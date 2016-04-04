function PHZ = phz_rej(PHZ,threshold,varargin)
%PHZ_REJ  Remove trials containing values exceeding a threshold.
%
% usage:    PHZ = PHZ_REJ(PHZ,THRESHOLD)
%           PHZ = PHZ_REJ(PHZ,THRESHOLD,REJTYPE)
% 
% inputs:   PHZ         = PHZLAB data structure.
%           THRESHOLD   = Trials with any value exceeding the value of
%                         THRESHOLD will be rejected. Enter 0 to unreject
%                         all trials.
%           REJTYPE     = The units of THRESHOLD. Default is 'threshold' 
%                         (i.e., the same units as PHZ.units). Enter 'sd'
%                         for standard deviation.
% 
% outputs:  PHZ.rej.threshold   = The value specified in THRESHOLD.
%           PHZ.rej.units       = The units of the threshold value.
%           PHZ.rej.data        = Data from PHZ.data of rejected trials.
%           PHZ.rej.locs        = Indices in PHZ.data of rejected trials.
%           PHZ.rej.data_locs   = Indices in PHZ.data of retained trials.
%           PHZ.rej.participant = participant tags of rejected trials.
%           PHZ.rej.group       = group tags of rejected trials.
%           PHZ.rej.session     = session tags of rejected trials.
%           PHZ.rej.trials      = trials trags of rejected trials.
% 
% examples:
%   PHZ = phz_rej(PHZ,20)    >> Reject all trials with a value > 20.
%   PHZ = phz_rej(PHZ,3,'sd' >> Reject trials with a value > 3 standard
%                               deviations from the mean of all trials.
%   PHZ = phz_rej(PHZ,0)     >> Restore all rejected trials.
%
% Written by Gabriel A. Nespoli 2016-01-27. Revised 2016-04-03.
if nargout == 0 && nargin == 0, help phz_rej, return, end
if nargin > 1 && isempty(threshold), return, end

% defaults
rejtype = 'value'; % 'value' or 'sd'
verbose = true;

% user-defined
for i = 1:length(varargin)
    
    if isnumeric(varargin{i}) || islogical(varargin{i})
        verbose = varargin{i};
        
    elseif ischar(varargin{i})
        rejtype = varargin{i};
        
    end
end

% get indices of artifacts and copy them to PHZ.rej.locs
[PHZ,do_rej,do_restore] = verifyREJinput(PHZ,threshold,verbose);

if do_rej || do_restore
    
    if do_restore
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
    
    if do_rej
        
        PHZ = getRejStructure(PHZ);
        
        % do actual finding of trials to reject
        if strcmp(rejtype,PHZ.units), rejtype = 'threshold'; end
        switch lower(rejtype)
            case {'sd','std','stdev'}
                PHZ.rej.units = 'SD';
                stDev = std(PHZ.data(:));
                for i = 1:size(PHZ.data,1)
                    if max(abs(PHZ.data(i,:))) > stDev * threshold
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
            disp(['The max value in this dataset is ',num2str(max(PHZ.data(:))),'.'])
            return
        end
        
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
        historyThreshold = [num2str(threshold),' ',PHZ.rej.units];
        PHZ = phzUtil_history(PHZ,['Threshold of ',historyThreshold,...
            ' rejected ',num2str(length(PHZ.rej.locs)),' / ',...
            num2str(length(PHZ.rej.data_locs) + length(PHZ.rej.locs)),...
            ' trials (',num2str(round(phz_rejrate(PHZ,'%'),1)),'%).'],verbose);
        
    end
end
end

function [PHZ,do_rej,do_restore] = verifyREJinput(PHZ,threshold,verbose)

if threshold == 0
    
    % newThresh == 0, oldThresh == 0 (do nothing and return)
    if ~ismember('rej',fieldnames(PHZ))
        do_restore = 0;
        do_rej = 0;
        if verbose, disp('Threshold is already set to 0.'), end
        
    else % newThresh == 0, oldThresh == val
        do_restore = true;
        do_rej = false;
        
    end
    
else
    % newThresh == val, oldThresh == val
    if ismember('rej',fieldnames(PHZ))
        do_restore = true;
        do_rej = true;
        
    else % newThresh == val, oldThresh == 0
        do_restore = false;
        do_rej = true;
        
    end
end
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