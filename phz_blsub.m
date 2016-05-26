%PHZ_BLSUB  Subtract the mean of a region from each trial.
%
% USAGE    
%   PHZ = phz_blsub(PHZ)
%   PHZ = phz_blsub(PHZ,region)
%
% INPUT   
%   PHZ       = [struct] PHZLAB data structure.
%   region    = [string|numeric] Baseline region to subtract. Either a 
%               string specifying a region name in PHZ.region, a 1-by-2 
%               vector specifying the start and end times in seconds, or a 
%               1-by-N vector (length > 2) of indices. Setting REGION to 
%               zero restores a previous subtraction. Default value is
%               the first region in PHZ.region.
%
% OUTPUT  
%   PHZ.data              = Baseline-subtracted data.
%   PHZ.proc.blc.region   = Start and end times of blc region used.
%   PHZ.proc.blc.values   = Mean of baseline region for each trial.
%
% EXAMPLES
%   PHZ = phz_blsub(PHZ,'baseline') >> Subtract the mean of the baseline
%         region (as specified in PHZ.region.baseline) from each trial.
%   PHZ = phz_blsub(PHZ,[-1 0]) >> Subtract the mean of -1s to 0s.
%   PHZ = phz_blsub(PHZ,0) >> Undo baseline subtraction.
%
% Written by Gabriel A. Nespoli 2016-02-16. Revised 2016-04-06.

function PHZ = phz_blsub(PHZ,region,verbose)

if nargout == 0 && nargin == 0, help phz_blc, return, end
if nargin > 1 && isempty(region), return, end
if nargin < 2, region = PHZ.meta.tags.region{1}; end
if nargin < 3, verbose = true; end

[PHZ,do_blsub,do_restore] = verifyBLinput(PHZ,region,verbose);

% if new baseline-subtraction is requested, do it
if do_blsub || do_restore
    
    % restore previously-subtracted baseline
    if do_restore
        
        % check that no other processing has been done since phz_blsub
        names = fieldnames(PHZ.proc);
        if ~ismember(names{end},{'blsub','rej'})
            error(['Other processing has been done since baseline ',... 
                'subtraction. Cannot undo previous baseline subtraction.'])
        end
        
        if ismember('rej',fieldnames(PHZ.proc))
            PHZ.data          = PHZ.data          + repmat(PHZ.proc.blsub.values(PHZ.proc.rej.data_locs),1,size(PHZ.data,2));
            PHZ.proc.rej.data = PHZ.proc.rej.data + repmat(PHZ.proc.blsub.values(PHZ.proc.rej.locs),1,size(PHZ.proc.rej.data,2));
        else
            PHZ.data = PHZ.data + repmat(PHZ.proc.blsub.values,1,size(PHZ.data,2));
        end
        
        PHZ.proc = rmfield(PHZ.proc,'blsub');
        PHZ = phz_history(PHZ,'Added back previously removed baseline.',verbose);
    end
    
    % subtract mean of new baseline region
    if do_blsub
        
        % get and subtract baseline
        PHZb = phz_region(PHZ,region,0);
        PHZ = getBLSUBstructure(PHZ);
        
        if ismember('rej',fieldnames(PHZ.proc))
            PHZ.proc.blsub.values = nan(length(PHZ.proc.rej.locs) + length(PHZ.proc.rej.data_locs),1);
            PHZ.proc.blsub.values(PHZ.proc.rej.locs) = mean(PHZb.proc.rej.data,2);
            PHZ.proc.blsub.values(PHZ.proc.rej.data_locs) = mean(PHZb.data,2);
            PHZ.proc.rej.data = PHZ.proc.rej.data - repmat(PHZ.proc.blc.values(PHZ.proc.rej.locs),[1 size(PHZ.proc.rej.data,2)]);
            PHZ.data = PHZ.data - repmat(PHZ.proc.blsub.values(PHZ.proc.rej.data_locs),[1 size(PHZ.data,2)]);
        else
            PHZ.proc.blc.values = mean(PHZb.data,2);
            PHZ.data = PHZ.data - repmat(PHZ.proc.blc.values,[1 size(PHZ.data,2)]);
        end
        
        % make region endpoints
        if ischar(region)
            regionStr = [region,' ',phzUtil_num2strRegion(PHZ.region.(region))];
            region = PHZ.region.(region);
        else regionStr = phzUtil_num2strRegion(region);
        end
        PHZ.proc.blsub.region = region;
        
        % add to history
        PHZ = phz_history(PHZ,['Subtracted mean of ',...
            regionStr,' from data.'],verbose);
    end
end
end

function [PHZ,do_blsub,do_restore] = verifyBLinput(PHZ,region,verbose)

% parse region input
if length(region) == 1 && region == 0
    
    % newBL == 0, oldBL == 0 (do nothing and return)
    if ~ismember('blc',fieldnames(PHZ.proc))
        do_restore = false;
        do_blsub = false;
        if verbose, disp('Baseline is already set to 0.'), end
        
    else % newBL == 0, oldBL == val
        do_restore = true;
        do_blsub = false;
        
    end
    
else
    % newBL == val, oldBL == val
    if ismember('blc',fieldnames(PHZ.proc))
        do_restore = true;
        do_blsub = true;
        
    else % newBL == val, oldBL == 0
        do_restore = false;
        do_blsub = true;
        
    end
end
end

function PHZ = getBLSUBstructure(PHZ)
PHZ.proc.blsub.region = '';
PHZ.proc.blsub.values = [];
end