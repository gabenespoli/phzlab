%PHZ_SUMMARY  Average across grouping variables.
% 
% USAGE
%   PHZ = phz_summary(PHZ, keepVars)
%   [PHZ, preSummaryData] = phz_summary(PHZ, keepVars)
% 
% INPUT
%   PHZ      = [struct] PHZLAB data structure.
% 
%   keepVars = [string|cell of strings] Grouping variables that you would
%       like to keep. All other grouping variables (i.e., those not listed
%       in KEEPVARS) will be averaged across (collapsed).  KEEPVARS can be
%       combination of 'participant', 'group', 'condition', 'session', and
%       'trials'. There some special values for keepVars that are listed
%       below. 
%
%       []    = Retain all trials (i.e., do nothing). Cannot be used in
%               combination with other KEEPVARS.
%
%       'none'= Average all trials together (i.e., discard all grouping 
%               variables). Can also use ' ' (space). Cannot be used in
%               combination with other KEEPVARS.
%
%       'all' = Average all repeated trials; this is shorthand for 
%               {'participant', 'group', 'condition', 'session', 
%               'trials'}. Cannot be used in combination with other 
%               KEEPVARS.
%
% OUTPUT
%   PHZ.data                      = The data summarized by KEEPVARS.
%   PHZ.proc.summary.keepVars     = The values specified in KEEPVARS.
%   PHZ.proc.summary.stdError     = Standard error of each average.
%   PHZ.proc.summary.nParticipant = No. of participants in each average.
%   PHZ.proc.summary.nTrials      = No. of trials in each average.
%   preSummaryData                = A cell array the same height as
%                                   PHZ.data containing vectors with the
%                                   raw data points included in each 
%                                   average.
% 
% EXAMPLES
%    >> PHZ = phz_summary(PHZ,'trials')
%       For each value in PHZ.trials, average all of those trials
%       together. The number of trials in PHZ.data will correspond to the
%       number of different kinds of trials.
%
%    >> PHZ = phz_summary(PHZ,{'trials','group'})
%       For each unique combination of PHZ.trials and PHZ.group, average
%       those trials together.

% Copyright (C) 2016 Gabriel A. Nespoli, gabenespoli@gmail.com
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see http://www.gnu.org/licenses/.

function [PHZ, preSummaryData] = phz_summary(PHZ, keepVars, varargin)
preSummaryData = {};

if nargout == 0 && nargin == 0, help phz_summary, return, end
if isempty(keepVars), return, end

% defaults
verbose = true;
summaryFunction = 'mean';

% user-defined (based on class of arg, not param/value pairs)
if ~isempty(varargin)
    for i = 1:length(varargin)
        if islogical(varargin{i})
            verbose = varargin{i};

        elseif ischar(varargin{i})
            summaryFunction = varargin{i};

        end
    end
end

PHZ = phz_check(PHZ); % (make sure grouping vars are ordinal)

[keepVars, loseVars, summaryFunction] = verifyKeepVars(keepVars, summaryFunction, PHZ);
if ismember(keepVars,{'all'}), return, end
    
% get unique proc name so that multiple summaries can be used
procName = phzUtil_getUniqueProcName(PHZ, 'summary');

% add keepVars and summaryFunction to the proc field
PHZ.proc.(procName).summaryFunction = summaryFunction;
PHZ.proc.(procName).keepVars = keepVars;
PHZ.proc.(procName).loseVars = loseVars;

% discard marked trials
PHZ = phz_discard(PHZ, verbose);

if ismember(keepVars{1}, {'none'}) % summary across all trials
    PHZ.proc.(procName).stdError = ste(PHZ.data);
    PHZ.proc.(procName).nParticipant = length(PHZ.participant);
    PHZ.proc.(procName).nTrials = size(PHZ.data, 1);
    preSummaryData{1} = PHZ.data;
    PHZ.data = doSummary(PHZ.data, summaryFunction);

else % get categories to collapse across
    for i = 1:length(keepVars)
        if i == 1
            varInd = PHZ.meta.tags.(keepVars{i});
        else
            varInd = varInd .* PHZ.meta.tags.(keepVars{i});
        end
    end
    varTypes = unique(varInd); % this will be in the proper spec order because they are ordinal categorical arrays

    % make containers
    summaryData = nan(length(varTypes),size(PHZ.data,2));
    PHZ.proc.(procName).stdError = nan(size(summaryData));
    PHZ.proc.(procName).nParticipant = nan(length(varTypes),1);
    PHZ.proc.(procName).nTrials = nan(length(varTypes),1);

    % loop categories and average
    for i = 1:length(varTypes)
        preSummaryData{i} = PHZ.data(varInd == varTypes(i),:); %#ok<AGROW>
        PHZ.proc.(procName).nParticipant(i) = length(unique(PHZ.meta.tags.participant(varInd == varTypes(i))));
        PHZ.proc.(procName).nTrials(i) = size(preSummaryData{i},1);
        PHZ.proc.(procName).stdError(i,:) = ste(preSummaryData{i});
        summaryData(i,:) = doSummary(preSummaryData{i}, summaryFunction);
    end

    PHZ.data = summaryData;

    % adjust PHZ.(keepVars) vars
    varTypes = regexp(cellstr(varTypes),' ','split');
    for i = 1:length(keepVars), field = keepVars{i};
        newVar = cell(size(PHZ.data,1),1);
        for j = 1:length(varTypes)
            newVar{j} = varTypes{j}{i};
        end
        PHZ.meta.tags.(field) = categorical(newVar,cellstr(PHZ.(field)),'Ordinal',true);
    end 
end

% cleanup
preSummaryData = preSummaryData(:); % make col so dims match PHZ.data
loseVars = {'participant','group','condition','session','trials'};
loseVars(ismember(loseVars,keepVars)) = [];
for i = loseVars, field = i{1};
    if ~ischar(PHZ.meta.tags.(field)) && length(unique(PHZ.meta.tags.(field))) == 1
        PHZ.meta.tags.(field) = PHZ.meta.tags.(field)(1:size(PHZ.data,1));
    else
        PHZ.meta.tags.(field) = '<collapsed>';
    end
end

if ismember('blsub',fieldnames(PHZ.proc))
    PHZ.proc.blsub.values = '<collapsed>';
end

% the 'rej' field is not present in phzlab version >= 1
% this section is kept for backwards compatibility
if ismember('rej',fieldnames(PHZ.proc))
    PHZ.proc.rej.locs        = '<collapsed>';
    PHZ.proc.rej.data        = '<collapsed>';
    PHZ.proc.rej.data_locs   = '<collapsed>';
    PHZ.proc.rej.participant = '<collapsed>';
    PHZ.proc.rej.condition   = '<collapsed>';
    PHZ.proc.rej.group       = '<collapsed>';
    PHZ.proc.rej.session     = '<collapsed>';
    PHZ.proc.rej.trials      = '<collapsed>';
end

% reset number of views (from phz_review)
if ismember('views', fieldnames(PHZ.meta.tags))
    PHZ.meta.tags.views = zeros(size(PHZ.data,1), 1);
end

PHZ = phz_history(PHZ,['Summarized data by ''',strjoin(keepVars),'''.'],verbose);

end

function y = ste(x,varargin) %STE  Standard error.
if nargin > 1
    dim = varargin{1};
else
    dim = 1;
end
y = std(x,0,dim) / sqrt(size(x,dim));
end

function [keepVars, loseVars, summaryFunction] = verifyKeepVars(keepVars, summaryFunction, PHZ)

% convert summary function to common format
switch lower(summaryFunction)
    case {'*', 'mean', 'avg', 'average'},   summaryFunction = 'mean';
    case {'+', 'add'},                      summaryFunction = 'add';
    case {'-', 'sub', 'subtract'},          summaryFunction = 'subtract';
    otherwise, error('Invalid summaryFunction.')
end

% define possible values for input
possibleKeepVars = {'participant', 'group', 'condition', 'session', 'trials'};
possibleAloneKeepVars = {'', 'none', ' ', 'all'};
possibleSummaryFunctions = {'mean', 'add', 'subtract'};

% make sure keepVars is a cell
if ~iscell(keepVars)
    keepVars = cellstr(keepVars);
end

% make sure all keep vars are valid values
if ~all(ismember(keepVars, [possibleKeepVars, possibleAloneKeepVars]))
    error('Invalid keepVars')
end

% make sure keepVars that should be used alone are being used alone
if any(ismember(possibleAloneKeepVars, keepVars)) && length(keepVars) > 1
    error('A value in keepVars must be used on its own, but is being used with other keepVars')
end

% parse shorthands for 'none', ' ', and 'all'
if ismember(keepVars{1},{' '}) || isempty(keepVars{1})
    keepVars = {'none'};
elseif strcmpi(keepVars{1}, 'all')
    keepVars = possibleKeepVars;
end

% parse summary functions
% make sure there is only 1 or 0 summary functions
% and that it's not being used alone
indSumFunc = ismember(keepVars, possibleSummaryFunctions);
if sum(indSumFunc) == 1 
    if length(keepVars) > 1
        summaryFunction = keepVars{indSumFunc};
        keepVars(indSumFunc) = [];
    else
        error('A keepVar must be specified with a summary function.')
    end
elseif sum(indSumFunc) ~= 0
    error('Too many summary functions were specified.')
end

% if the summary function is + or -, make the keepVar a loseVar instead
if ismember(summaryFunction, {'add', 'subtract'})
    % keepVar is actually a loseVar
    if length(keepVars) ~= 1
        error('Must use exactly one keepVar with an ''add'' or ''subtract'' summary function.')
    end
    loseVars = keepVars;
    keepVars = possibleKeepVars(~ismember(keepVars, possibleKeepVars));
else
    loseVars = possibleKeepVars(~ismember(keepVars, possibleKeepVars));
end

% if a keepVar doesn't have multiple categories within, it doesn't need to be summary'd
rminds = [];
for i = 1:length(keepVars)
    if ~ismember(keepVars{i}, possibleKeepVars)
        continue
    end
    if ischar(PHZ.meta.tags.(keepVars{i})) || length(unique(PHZ.meta.tags.(keepVars{i}))) < 2
        rminds = [rminds i]; %#ok<AGROW>
    end
end
keepVars(rminds) = [];
if isempty(keepVars)
    keepVars = {'none'};
end

end

function summaryData = doSummary(preData, summaryFunction)
switch summaryFunction
    case 'mean'
        summaryData = mean(preData, 1);

    case 'add'
        if size(preData, 1) ~= 2
            error('Cannot add unless there are exactly 2 trials.')
        end
        summaryData = preData(1,:) + preData(2,:);

    case 'subtract'
        if size(preData, 1) ~= 2
            error('Cannot subtract unless there are exactly 2 trials.')
        end
        summaryData = preData(1,:) - preData(2,:);
end
end
