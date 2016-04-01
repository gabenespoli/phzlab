function PHZ = phz_rej(PHZ,threshold,varargin)
%PHZ_REJ  Remove trials containing values exceeding a threshold.
% 
% PHZ = PHZ_REJ(PHZ,THRESHOLD) removes trials from PHZ.DATA if they
%   contain values exceeding THRESHOLD. The rejected data and grouping
%   information (i.e., participant, group, session, trials) are stored in
%   PHZ.REJ. Entering a threshold of 0 or [] (empty) restores all 
%   previously rejected trials (if there are any).
% 
% PHZ = PHZ_REJ(PHZ,THRESHOLD,'sd') removes trials containing a value
%   exceeding a THRESHOLD number of each trial's standard deviation.
% 
%   New fields are created in the PHZ structure:
%     PHZ.rej.threshold   = The value specified in THRESHOLD.
%     PHZ.rej.data        = Data from PHZ.data of rejected trials.
%     PHZ.rej.locs        = Indices in PHZ.data of rejected trials.
%     PHZ.rej.data_locs   = Indices in PHZ.data of retained trials.
%     PHZ.rej.participant = Data from PHZ.participant of rejected trials.
%     PHZ.rej.group       = Data from PHZ.group of rejected trials.
%     PHZ.rej.session     = Data from PHZ.session of rejected trials.
%     PHZ.rej.trials      = Data from PHZ.trials of rejected trials.
%
% Written by Gabriel A. Nespoli 2016-01-27. Revised 2016-03-23.

if nargout == 0 && nargin == 0, help phz_rej, return, end

% defaults
rejType = 'value'; % 'value' or 'sd'
verbose = true;

% user-defined
for i = 1:length(varargin)
    
    if isnumeric(varargin{i}) || islogical(varargin{i})
        verbose = varargin{i};
    
    elseif ischar(varargin{i})
        rejType = varargin{i};
    
    end 
end

% get indices of artifacts and copy them to PHZ.rej.locs
[PHZ,returnFlag] = phz_findArtifacts(PHZ,threshold,rejType,verbose);
if returnFlag, return, end

% copy tags over to PHZ.rej.(field)
for i = {'participant','group','session','trials'}, field = i{1};
    PHZ.rej.(field) = PHZ.tags.(field)(PHZ.rej.locs);
    PHZ.tags.(field)(PHZ.rej.locs) = [];
end
PHZ.rej.data = PHZ.data(PHZ.rej.locs,:);
PHZ.data(PHZ.rej.locs,:) = [];
PHZ.rej.data_locs(PHZ.rej.locs) = [];

% misc updates to PHZ structure
PHZ.rej.threshold = threshold;

% add to PHZ.history
if isempty(threshold)
    historyThreshold = '[]';
else historyThreshold = [num2str(threshold),' ',PHZ.rej.units];
end
PHZ = phzUtil_history(PHZ,['Threshold of ',historyThreshold,...
    ' rejected ',num2str(length(PHZ.rej.locs)),' / ',...
    num2str(length(PHZ.rej.data_locs) + length(PHZ.rej.locs)),...
    ' trials (',num2str(round(phz_rejrate(PHZ,'%'),1)),'%).'],verbose);

end

function [PHZ,returnFlag] = phz_findArtifacts(PHZ,threshold,rejType,verbose)
returnFlag = 0;

if isempty(threshold) || threshold == 0
    
    % newThresh == 0, oldThresh == 0 (do nothing and return)
    if ~ismember('rej',fieldnames(PHZ))
%         if verbose, disp('Threshold is already set to [].'), end
        returnFlag = 1;
        return
        
        % newThresh == 0, oldThresh == val
    else PHZ = phz_unreject(PHZ,verbose);
        returnFlag = 1;
        return
    end
    
    % newThresh == val
elseif ismember('rej',fieldnames(PHZ))
    PHZ = phz_unreject(PHZ,verbose);
    PHZ = getRejStructure(PHZ);
    
    % (otherwise newThresh == val, oldThresh == 0, no prep needed, continue)
else PHZ = getRejStructure(PHZ);
    
end

% do actual finding of trials to reject
switch lower(rejType)
    case {'sd','std','stdev'}
        PHZ.rej.units = 'SD';
        stDev = std(PHZ.data,[],2);
        for i = 1:size(PHZ.data,1)
            if max(abs(PHZ.data(i,:))) > stDev(i) * threshold
                PHZ.rej.locs = [PHZ.rej.locs; i];
            end
        end
    
    case {'threshold','value'}
        PHZ.rej.units = PHZ.units;
        for i = 1:size(PHZ.data,1)
            if max(abs(PHZ.data(i,:))) > threshold
                PHZ.rej.locs = [PHZ.rej.locs; i];
            end
        end
end

if length(PHZ.rej.locs) == size(PHZ.data,1)
    disp('This threshold would reject all trials. Aborting...')
    error(' ')
end

end

function PHZ = phz_unreject(PHZ,verbose)

% concatenate all locs, data, trials, etc.
locs            = [PHZ.rej.data_locs;    PHZ.rej.locs];
data            = [PHZ.data;             PHZ.rej.data];
participant     = [PHZ.tags.participant; PHZ.rej.participant];
group           = [PHZ.tags.group;       PHZ.rej.group];
session         = [PHZ.tags.session;     PHZ.rej.session];
trials          = [PHZ.tags.trials;      PHZ.rej.trials];

% sort locs, then sort others based on it
[~,ind]                 = sort(locs);
PHZ.data                = data(ind,:);
PHZ.tags.participant    = participant(ind);
PHZ.tags.group          = group(ind);
PHZ.tags.session        = session(ind);
PHZ.tags.trials         = trials(ind);

PHZ = rmfield(PHZ,'rej');

PHZ = phzUtil_history(PHZ,'Unrejected all trials.',verbose);

end

function rejrate = phz_rejrate(PHZ,varargin)
%PHZ_REJRATE  Get the proportion of trials that were rejected.
%
% See also PHZ_REJECT.
%
% Written by Gabriel A. Nespoli 2016-04-05. Revised 2016-02-18.

% default
valType = 'proportion';

% user-defined
for i = 1:length(varargin)
    valType = varargin{i};
end

totalNumTrials = size(PHZ.data,1) + length(PHZ.rej.locs);
totalRejTrials = length(PHZ.rej.locs);

rejrate = totalRejTrials / totalNumTrials;

switch lower(valType)
    case {'p','proportion'}
    case {'%','percent'}, rejrate = rejrate * 100;
    otherwise, warning('Unrecognized valType. Returning proportion.')
end
end

function PHZ = getRejStructure(PHZ)
PHZ.rej.threshold = [];
PHZ.rej.units = '';
PHZ.rej.data = [];
PHZ.rej.locs = [];
PHZ.rej.data_locs = transpose(1:size(PHZ.data,1));
PHZ.rej.participant = categorical;
PHZ.rej.group = categorical;
PHZ.rej.session = categorical;
PHZ.rej.trials = categorical;
end
