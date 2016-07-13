%PHZ_SUMMARY  Average across grouping variables.
% 
% USAGE
%   PHZ = phz_summary(PHZ,keepVars)
% 
% INPUT
%   PHZ       = PHZLAB data structure.
% 
%   keepVars  = A string or a cell array of strings and can contain a
%               combination of 'participant', 'group', 'session', and
%               'trials'. Use 'all' or [] (empty) to retain all trials
%               (i.e., do nothing) or 'none' to average all trials together
%               (i.e., discard all grouping variables. 'all' and 'none' 
%               cannot be used with other KEEPVARS.
% 
% OUTPUT
%   PHZ.data                      = The data summarized by KEEPVARS.
%   PHZ.proc.summary.keepVars     = The values specified in KEEPVARS.
%   PHZ.proc.summary.stdError     = Standard error of each average.
%   PHZ.proc.summary.nParticipant = No. of participants in each average.
%   PHZ.proc.summary.nTrials      = No. of trials in each average.
% 
% EXAMPLES
%   PHZ = phz_summary(PHZ,'trials') >> For each value in PHZ.trials,
%         average all of those trials together. The number of trials in
%         PHZ.data will correspond to the number of different kinds of
%         trials.
%   PHZ = phz_summary(PHZ,{'trials','group') >> For each unique combination
%         of PHZ.trials and PHZ.group, average those trials together.

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

function PHZ = phz_summary(PHZ,keepVars,verbose)

if nargout == 0 && nargin == 0, help phz_summary, return, end
if isempty(keepVars), return, end
if nargin < 3, verbose = true; end

PHZ = phz_check(PHZ); % (make ordinal if there are new manually-made orders i.e., not using phz_field.m)

keepVars = verifyKeepVars(keepVars);
if ismember(keepVars,{'all'}), return, end
PHZ.proc.summary.keepVars = keepVars;

if ismember(keepVars{1},{'none'})
    PHZ.proc.summary.nParticipant = length(PHZ.participant);
    PHZ.proc.summary.nTrials = size(PHZ.data,1);
    PHZ.proc.summary.stdError = ste(PHZ.data);
    PHZ.data = mean(PHZ.data,1);

else
    % get categories to collapse across
    for i = 1:length(keepVars)
        if i == 1, varInd = PHZ.meta.tags.(keepVars{i});
        else       varInd = varInd .* PHZ.meta.tags.(keepVars{i});
        end
    end
    varTypes = unique(varInd); % this will be in the proper spec order because they are ordinal categorical arrays
    
    % loop categories and average
    newData = nan(length(varTypes),size(PHZ.data,2));
    PHZ.proc.summary.stdError = nan(size(newData));
    PHZ.proc.summary.nParticipant = nan(length(varTypes),1);
    PHZ.proc.summary.nTrials = nan(length(varTypes),1);
    
    for i = 1:length(varTypes)
        TMP = PHZ;
        TMP.data = PHZ.data(varInd == varTypes(i),:);
        PHZ.proc.summary.nParticipant(i) = length(unique(PHZ.meta.tags.participant(varInd == varTypes(i))));
        PHZ.proc.summary.nTrials(i) = size(TMP.data,1);
        PHZ.proc.summary.stdError(i,:) = ste(TMP.data);
        newData(i,:) = mean(TMP.data,1);
        
    end
    PHZ.data = newData;
    
    % adjust PHZ.(keepVars) vars
    varTypes = regexp(cellstr(varTypes),' ','split');
    for i = 1:length(keepVars), field = keepVars{i};
        newVar = cell(size(PHZ.data,1),1);
        for j = 1:length(varTypes);
            newVar{j} = varTypes{j}{i};
        end
        PHZ.meta.tags.(field) = categorical(newVar,cellstr(PHZ.(field)),'Ordinal',true);
    end 
end

% cleanup
loseVars = {'participant','group','condition','session','trials'};
loseVars(ismember(loseVars,keepVars)) = [];
for i = loseVars, field = i{1};
    if length(unique(PHZ.meta.tags.(field))) == 1
        PHZ.meta.tags.(field) = PHZ.meta.tags.(field)(1:size(PHZ.data,1));
    else
        PHZ.meta.tags.(field) = '<collapsed>';
    end
end

if ismember('blsub',fieldnames(PHZ.proc))
    PHZ.proc.blsub.values = '<collapsed>';
end

if ismember('rej',fieldnames(PHZ.proc))
    PHZ.proc.rej.locs = '<collapsed>';
    PHZ.proc.rej.data = '<collapsed>';
    PHZ.proc.rej.data_locs = '<collapsed>';
    PHZ.proc.rej.participant = '<collapsed>';
    PHZ.proc.rej.condition = '<collapsed>';
    PHZ.proc.rej.group = '<collapsed>';
    PHZ.proc.rej.session = '<collapsed>';
    PHZ.proc.rej.trials = '<collapsed>';
end

if isempty(keepVars), keepVars = {''}; end
PHZ = phz_history(PHZ,['Summarized data by ''',strjoin(keepVars),'''.'],verbose);

end

function y = ste(x,varargin) %STE  Standard error.
if nargin > 1, dim = varargin{1}; else dim = 1; end
y = std(x,0,dim) / sqrt(size(x,dim));
end

function keepVars = verifyKeepVars(keepVars)
if ~iscell(keepVars), keepVars = cellstr(keepVars); end
if ~isempty(keepVars)
    if ~all(ismember(keepVars,{'trials','session','condition','group','participant','all','',' ','none'}))
        error('Invalid summaryType.'), end
    if any(ismember({'all','',' ','none'},keepVars)) && length(keepVars) > 1
        error('A value in summaryType must be used on its own, but is being used with other summaryTypes.'), end
    if ismember(keepVars{1},{' '}) || isempty(keepVars{1})
        keepVars = {'none'}; end
end
end