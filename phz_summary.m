function PHZ = phz_summary(PHZ,keepVars,verbose)
%PHZ_SUMMARY  Average across grouping variables.
% 
% usage:    PHZ = phz_summary(PHZ,KEEPVARS)
% 
% inputs:   PHZ      = PHZLAB data structure.
%           KEEPVARS = A string or a cell array of strings and can contain
%                      a combination of 'participant', 'group', 'session', 
%                      and 'trials'. Use 'all' or [] (empty) to retain all 
%                      trials (i.e., do nothing) or 'none' to average 
%                      all trials together (i.e., discard all grouping
%                      variables. 'all' and 'none' cannot be used with
%                      other KEEPVARS.
% 
% outputs:  PHZ.data                 = The data summarized by KEEPVARS.
%           PHZ.summary.keepVars     = The values specified in KEEPVARS.
%           PHZ.summary.stdError     = Standard error of each average.
%           PHZ.summary.nParticipant = No. of participants in each average.
%           PHZ.summary.nTrials      = No. of trials in each average.
% 
% examples:
%   PHZ = phz_summary(PHZ,'trials') >> For each value in PHZ.trials,
%         average all of those trials together. The number of trials in
%         PHZ.data will correspond to the number of different kinds of
%         trials.
%   PHZ = phz_summary(PHZ,{'trials','group') >> For each unique combination
%         of PHZ.trials and PHZ.group, average those trials together.
%
% Written by Gabriel A. Nespoli 2016-03-17. Revised 2016-04-07.
if nargout == 0 && nargin == 0, help phz_summary, return, end
if isempty(keepVars), return, end
if nargin < 3, verbose = true; end

PHZ = phz_check(PHZ); % (make ordinal if there are new orders)
keepVars = verifyKeepVars(keepVars);
if ismember(keepVars{1},{'all'}), return, end
PHZ.summary.keepVars = keepVars;

if ismember(keepVars{1},{'none'})
    PHZ.summary.stdError = ste(PHZ.data);
    PHZ.summary.nParticipant = length(PHZ.participant);
    PHZ.summary.nTrials = size(PHZ.data,1);
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
    PHZ.summary.stdError = nan(size(newData));
    PHZ.summary.nParticipant = nan(length(varTypes),1);
    PHZ.summary.nTrials = nan(length(varTypes),1);
    
    for i = 1:length(varTypes)
        temp = PHZ.data(varInd == varTypes(i),:);
        PHZ.summary.stdError(i,:) = ste(temp);
        PHZ.summary.nParticipant(i) = length(unique(PHZ.meta.tags.participant(varInd == varTypes(i))));
        PHZ.summary.nTrials(i) = size(temp,1);
        newData(i,:) = mean(temp,1);
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
loseVars = {'participant','group','session','trials'};
loseVars(ismember(loseVars,keepVars)) = [];
for i = loseVars, field = i{1};
    
    PHZ.meta.tags.(field) = '<collapsed>';
end

if ismember('blc',fieldnames(PHZ.proc))
    PHZ.proc.blc.values = '<collapsed>';
end

if ismember('rej',fieldnames(PHZ.proc))
    PHZ.proc.rej.locs = '<collapsed>';
    PHZ.proc.rej.data = '<collapsed>';
    PHZ.proc.rej.data_locs = '<collapsed>';
    PHZ.proc.rej.participant = '<collapsed>';
    PHZ.proc.rej.group = '<collapsed>';
    PHZ.proc.rej.session = '<collapsed>';
    PHZ.proc.rej.trials = '<collapsed>';
end

if isempty(keepVars), keepVars = {''}; end
PHZ = phz_history(PHZ,['Summarized data by ''',strjoin(keepVars),'''.'],verbose);

end

function y = ste(x,varargin)
%STE  Standard error.
if nargin > 1, dim = varargin{1}; else dim = 1; end
y = std(x,0,dim) / sqrt(size(x,dim));
end

function keepVars = verifyKeepVars(keepVars)

if ~iscell(keepVars), keepVars = {keepVars}; end

if ~isempty(keepVars)
    
    if ~all(ismember(keepVars,{'trials','session','group','participant','all','',' ','none'}))
        error('Invalid summaryType.')
    end
    
    if any(ismember({'all','',' ','none'},keepVars)) && length(keepVars) > 1
        error('A value in summaryType must be used on its own, but is being used with other summaryTypes.')
    end
    
    if ismember(keepVars{1},{' '}) || isempty(keepVars{1})
        keepVars = {'none'};
    end
    
end
end