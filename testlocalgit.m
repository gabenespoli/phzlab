%PHZ_REJ  Remove trials containing values exceeding a threshold.
%
% USAGE    
%   PHZ = PHZ_REJ(PHZ,threshold)
%   PHZ = PHZ_REJ(PHZ,threshold,rejtype)
% 
% INPUT   
%   PHZ       = [struct] PHZLAB data structure.
% 
%   threshold = [numeric|string] Trials with any value exceeding this 
%               value of THRESHOLD will be rejected. Enter 0 to unreject 
%               all trials. THRESHOLD can be a string as a shorthand for
%               setting REJTYPE to 'sd'. In this case the string must be a
%               number followed by 'sd' (e.g., '0.05sd').
% 
%   rejtype   = ['value'|'sd'] The units of THRESHOLD. Default is 'value' 
%               (i.e., the same units as PHZ.units). Enter 'sd' to reject 
%               a trial if any value exceeds a THRESHOLD Number of that 
%               trial's standard deviation.
%                       
% OUTPUT  
%   PHZ.proc.rej.threshold   = The value specified in THRESHOLD.
%   PHZ.proc.rej.units       = The units of the threshold value.
%   PHZ.proc.rej.data        = Data of rejected trials.
%   PHZ.proc.rej.locs        = Indices of rejected trials.
%   PHZ.proc.rej.data_locs   = Indices of retained trials.
%   PHZ.proc.rej.participant = Participant tags of rejected trials.
%   PHZ.proc.rej.group       = Group tags of rejected trials.
%   PHZ.proc.rej.condition   = Condition tags of rejected trials.
%   PHZ.proc.rej.session     = Session tags of rejected trials.
%   PHZ.proc.rej.trials      = Trials trags of rejected trials.
% 
% EXAMPLES
%   PHZ = phz_rej(PHZ,20)     >> Reject all trials with a value > 20.
% 
%   PHZ = phz_rej(PHZ,3,'sd') >> Reject trials with a value > 3 standard
%                                deviations from the mean of all trials.
% 
%   PHZ = phz_rej(PHZ,'3sd')  >> Reject trials with a value > 3 standard
%                                deviations from the mean of all trials.
% 
%   PHZ = phz_rej(PHZ,0)      >> Restore all rejected trials.
%
% Written by Gabriel A. Nespoli 2016-01-27. Revised 2016-05-19.

function PHZ = phz_rej(PHZ,threshold,varargin)

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

% check input
if ischar(threshold) && strcmpi(threshold(end-1:end),'sd')
    rejtype = 'sd';
    threshold = str2double(threshold(1:end-2));
elseif ~isnumeric(threshold), error('Problem with THRESHOLD.')
end

% get indices of artifacts and copy them to PHZ.rej.locs
[PHZ,do_rej,do_restore] = verifyREJinput(PHZ,threshold,verbose);

if do_rej || do_restore
    
    if do_restore

        % check that no other processing has been done since phz_rej
        names = fieldnames(PHZ.proc);
        if ~strcmp(names{end},'rej')
            error(['Other processing has been done since threshold ',...
                'rejection. Cannot undo previous rejections.'])
        end
        
        % concatenate all locs, data, and grouping vars
        locs        = [PHZ.proc.rej.data_locs;    PHZ.proc.rej.locs];
        data        = [PHZ.data;                  PHZ.proc.rej.data];
        participant = [PHZ.meta.tags.participant; PHZ.proc.rej.participant];
        condition   = [PHZ.meta.tags.condition;   PHZ.proc.rej.condition];
        group       = [PHZ.meta.tags.group;       PHZ.proc.rej.group];
        session     = [PHZ.meta.tags.session;     PHZ.proc.rej.session];
        trials      = [PHZ.meta.tags.trials;      PHZ.proc.rej.trials];
        
        % sort locs, then sort others based on it
        [~,ind]                   = sort(locs);
        PHZ.data                  = data(ind,:);
        PHZ.meta.tags.participant = participant(ind);
        PHZ.meta.tags.condition   = condition(ind);
        PHZ.meta.tags.group       = group(ind);
        PHZ.meta.tags.session     = session(ind);
        PHZ.meta.tags.trials      = trials(ind);
        
        PHZ.proc = rmfield(PHZ.proc,'rej');
        PHZ = phz_history(PHZ,'Unrejected all trials.',verbose);
    end
    
    if do_rej
        
        PHZ = getRejStructure(PHZ);
        
        % do actual finding of trials to reject
        if strcmp(rejtype,PHZ.units), rejtype = 'threshold'; end
        switch lower(rejtype)
            case {'sd','std','stdev'}
                PHZ.proc.rej.units = 'SD';
                stDev = std(PHZ.data(:));
                for i = 1:size(PHZ.data,1)
                    if max(abs(PHZ.data(i,:))) > stDev * threshold
                        PHZ.proc.rej.locs = [PHZ.proc.rej.locs; i];
                    end
                end
                
            case {'threshold','value'}
                PHZ.proc.rej.units = PHZ.units;
                for i = 1:size(PHZ.data,1)
                    if max(abs(PHZ.data(i,:))) > threshold
                        PHZ.proc.rej.locs = [PHZ.proc.rej.locs; i];
                    end
                end
        end
        
        % check that ~reject all trials or ~reject no trials
        if length(PHZ.proc.rej.locs) == size(PHZ.data,1)
            disp('This threshold would reject all trials. Aborting...')
            disp(['The min threshold to reject a trial in this dataset is ',num2str(min(max(PHZ.data,[],2))),'.'])
            return
        end
        
        if isempty(PHZ.proc.rej.locs)
            disp('This threshold would not reject any trials. Aborting...')
            disp(['The max value in this dataset is ',num2str(max(PHZ.data(:))),'.'])
            return
        end
        
        % copy tags over to PHZ.rej.(field)
        for i = {'participant','group','session','trials'}, field = i{1};
            PHZ.proc.rej.(field) = PHZ.meta.tags.(field)(PHZ.proc.rej.locs);
            PHZ.meta.tags.(field)(PHZ.proc.rej.locs) = [];
        end
        PHZ.proc.rej.data = PHZ.data(PHZ.proc.rej.locs,:);
        PHZ.data(PHZ.proc.rej.locs,:) = [];
        PHZ.proc.rej.data_locs(PHZ.proc.rej.locs) = [];
        
        % misc updates to PHZ structure
        PHZ.proc.rej.threshold = threshold;
        
        % add to PHZ.history
        historyThreshold = [num2str(threshold),' ',PHZ.proc.rej.units];
        PHZ = phz_history(PHZ,['Threshold of ',historyThreshold,...
            ' rejected ',num2str(length(PHZ.proc.rej.locs)),' / ',...
            num2str(length(PHZ.proc.rej.data_locs) + length(PHZ.proc.rej.locs)),...
            ' trials (',num2str(round(phz_rejrate(PHZ,'%'),1)),'%).'],verbose);
        
    end
end
end

function [PHZ,do_rej,do_restore] = verifyREJinput(PHZ,threshold,verbose)

if threshold == 0
    
    % newThresh == 0, oldThresh == 0 (do nothing and return)
    if ~ismember('rej',fieldnames(PHZ.proc))
        do_restore = 0;
        do_rej = 0;
        if verbose, disp('Threshold is already set to 0.'), end
        
    else % newThresh == 0, oldThresh == val
        do_restore = true;
        do_rej = false;
        
    end
    
else
    % newThresh == val, oldThresh == val
    if ismember('rej',fieldnames(PHZ.proc))
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

totalNumTrials = size(PHZ.data,1) + length(PHZ.proc.rej.locs);
totalRejTrials = length(PHZ.proc.rej.locs);

rejrate = totalRejTrials / totalNumTrials;

switch lower(valType)
    case {'p','proportion'}
    case {'%','percent'}, rejrate = rejrate * 100;
    otherwise, warning('Unrecognized valType. Returning proportion.')
end
end

function PHZ = getRejStructure(PHZ)
PHZ.proc.rej.threshold = [];
PHZ.proc.rej.units = '';
PHZ.proc.rej.data = [];
PHZ.proc.rej.locs = [];
PHZ.proc.rej.data_locs = transpose(1:size(PHZ.data,1));
PHZ.proc.rej.participant = categorical;
PHZ.proc.rej.condition = categorical;
PHZ.proc.rej.group = categorical;
PHZ.proc.rej.session = categorical;
PHZ.proc.rej.trials = categorical;
end