function PHZ = phz_summary(PHZ,keepVars,varargin)
%PHZ_SUMMARY  Collapse across grouping variables of a PHZ or PHZS.
% 
% PHZ = PHZ_SUMMARY(PHZ,KEEPVARS) averages trials together. Data are 
%   summarized based on the grouping variables specified in KEEPVARS.
%   KEEPVARS is a string or a cell array of strings and can contain a
%   combination of 'participant', 'group', 'session', and 'trials'.
%   Use 'all' to retain all trials (do no averaging) or 'none' or ''
%   (empty) to average all trials together. 'all', 'none', and '' cannot
%   be used with other KEEPVARS.
% 
%   New fields are created in the PHZ structure:
%     PHZ.summary.keepVars     = The values specified in KEEPVARS.
%     PHZ.summary.stdError     = Standard error of each average.
%     PHZ.summary.nParticipant = Number of participants in each average.
%     PHZ.summary.nTrials      = Number of trials in each average.
%
% Written by Gabriel A. Nespoli 2016-03-17. Revised 2016-03-21.

if nargout == 0 && nargin == 0, help phz_summary, return, end

if nargin > 2, verbose = varargin{1}; else verbose = true; end

PHZ = phz_check(PHZ); % (make ordinal if there are new orders)
keepVars = phzUtil_verifySummaryType(keepVars);
if ismember(keepVars{1},{'all'}), return, end
PHZ.summary.keepVars = keepVars;

if ismember(keepVars{1},{'none'})
    PHZ.summary.stdError = ste(PHZ.data);
    PHZ.summary.nParticipant = length(unique(cellstr(PHZ.participant)));
    PHZ.summary.nTrials = size(PHZ.data,1);
    PHZ.data = mean(PHZ.data,1);
%     keepVars = 'none'; % for loseVars
    
else
    
    % get categories to collapse across
    for i = 1:length(keepVars)
        if ischar(PHZ.(keepVars{i}))
            PHZ.(keepVars{i}) = categorical(repmat({PHZ.(keepVars{i})},[size(PHZ.data,1) 1]));
        end
        
        if i == 1, varInd = PHZ.(keepVars{i});
        else       varInd = varInd .* PHZ.(keepVars{i});
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
        
        if length(PHZ.participant) == 1
            PHZ.summary.nParticipant(i) = 1;
        else
            PHZ.summary.nParticipant(i) = length(unique(cellstr(PHZ.participant(varInd == varTypes(i)))));
        end
        
        PHZ.summary.nTrials(i) = size(temp,1);
        newData(i,:) = mean(temp,1);
    end
    PHZ.data = newData;
    
    % adjust PHZ.(summaryType) vars
    varTypes = regexp(cellstr(varTypes),' ','split');
    for i = 1:length(keepVars)
        newVar = cell(size(PHZ.data,1),1);
        for j = 1:length(varTypes);
            newVar{j} = varTypes{j}{i};
        end
        PHZ.(keepVars{i}) = categorical(newVar,PHZ.spec.([keepVars{i},'_order']),'Ordinal',true);
    end 
end

% cleanup
loseVars = {'participant','group','session','trials'};
loseVars(ismember(loseVars,keepVars)) = [];
for i = 1:length(loseVars)
    if length(unique(cellstr(PHZ.(loseVars{i})))) > 1
        PHZ.(loseVars{i}) = '<collapsed>';
        PHZ.spec.([loseVars{i},'_order']) = strjoin(PHZ.spec.([loseVars{i},'_order']),'_');
        PHZ.spec.([loseVars{i},'_spec']) = {};
    end
end

for i = 1:length(keepVars)
    if ismember(keepVars{i},{'participant','group','session','trials'})
        if length(unique(PHZ.(keepVars{i}))) == 1
            PHZ.(keepVars{i}) = cellstr(unique(PHZ.(keepVars{i})));
            PHZ.(keepVars{i}) = PHZ.(keepVars{i}){1};
        end
    end
end

if ismember('blc',fieldnames(PHZ))
    PHZ.blc.values = '<collapsed>';
end

if ismember('rej',fieldnames(PHZ))
    PHZ.rej.locs = '<collapsed>';
    PHZ.rej.data = '<collapsed>';
    PHZ.rej.data_locs = '<collapsed>';
    PHZ.rej.participant = '<collapsed>';
    PHZ.rej.group = '<collapsed>';
    PHZ.rej.session = '<collapsed>';
    PHZ.rej.trials = '<collapsed>';
end

if isempty(keepVars), keepVars = {''}; end
PHZ = phzUtil_history(PHZ,['Summarized data by ''',strjoin(keepVars),'''.'],verbose);

end

function y = ste(x,varargin)
%STE  Standard error.
if nargin > 1, dim = varargin{1}; else dim = 1; end
y = std(x,0,dim) / sqrt(size(x,dim));
end