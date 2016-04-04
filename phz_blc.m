function PHZ = phz_blc(PHZ,region,verbose)
%PHZ_BLC  Subtract the mean of a region from each trial.
%
% usage:    PHZ = phz_blc(PHZ,REGION)
%
% inputs:   PHZ      = PHZLAB data structure.
%           REGION   = Baseline region to subtract. REGION is a string
%                      specifying a region in PHZ.regions, a 1-by-2 vector
%                      specifying the start and end times in seconds, or a
%                      1-by-N vector (length > 2) of indices. Setting
%                      REGION to zero restores a previous subtraction.
%
% outputs:  PHZ.data       = Baseline-corrected data.
%           PHZ.blc.region = Start and end times of region used for blc.
%           PHZ.blc.values = Mean of blc region for each trial.
%           * If baseline is restored (REGION = 0), the 'blc' field is
%               removed from the PHZ structure.
%
% examples:
%   PHZ = phz_blc(PHZ,'baseline') >> Subtract the mean of the baseline
%         region (as specified in PHZ.regions.baseline) from each trial.
%   PHZ = phz_blc(PHZ,[-1 0]) >> Subtract the mean of -1s to 0s.
%   PHZ = phz_blc(PHZ,0) >> Undo baseline correction.
%
% Written by Gabriel A. Nespoli 2016-02-16. Revised 2016-04-03.
if nargout == 0 && nargin == 0, help phz_blc, return, end
if nargin > 1 && isempty(region), return, end
if nargin < 2, region = 'baseline'; end
if nargin < 3, verbose = true; end

[PHZ,do_blc,do_restore] = verifyBLinput(PHZ,region,verbose);

% if new baseline-subtraction is requested, do it
if do_blc || do_restore
    
    % restore previously-subtracted baseline
    if do_restore
        
        if isempty(PHZ.blc.values), error('The current baseline-correction is undoable, probably due to previous preprocessing.'), end
        
        if ismember('rej',fieldnames(PHZ))
            PHZ.data     = PHZ.data     + repmat(PHZ.blc.values(PHZ.rej.data_locs),1,size(PHZ.data,2));
            PHZ.rej.data = PHZ.rej.data + repmat(PHZ.blc.values(PHZ.rej.locs),1,size(PHZ.rej.data,2));
        else
            PHZ.data = PHZ.data + repmat(PHZ.blc.values,1,size(PHZ.data,2));
        end
        
        PHZ = rmfield(PHZ,'blc');
        PHZ = phzUtil_history(PHZ,'Added back previously removed baseline.',verbose);
    end
    
    % subtract mean of new baseline region
    if do_blc
        
        PHZ = getBLCstructure(PHZ);
        
        % get and subtract baseline
        PHZb = phz_region(PHZ,region,0);
        
        if ismember('rej',fieldnames(PHZ))
            PHZ.blc.values = nan(length(PHZ.rej.locs) + length(PHZ.rej.data_locs),1);
            PHZ.blc.values(PHZ.rej.locs)      = mean(PHZb.rej.data,2);
            PHZ.blc.values(PHZ.rej.data_locs) = mean(PHZb.data,2);
            PHZ.rej.data = PHZ.rej.data - repmat(PHZ.blc.values(PHZ.rej.locs),[1 size(PHZ.rej.data,2)]);
            PHZ.data     = PHZ.data - repmat(PHZ.blc.values(PHZ.rej.data_locs),[1 size(PHZ.data,2)]);
        else
            PHZ.blc.values = mean(PHZb.data,2);
            PHZ.data = PHZ.data - repmat(PHZ.blc.values,[1 size(PHZ.data,2)]);
        end
        
        % make region endpoints
        if ischar(region)
            regionStr = [region,' ',phzUtil_num2strRegion(PHZ.regions.(region))];
            region = PHZ.regions.(region);
        else regionStr = phzUtil_num2strRegion(region);
        end
        PHZ.blc.region = region;
        
        % add to history
        PHZ = phzUtil_history(PHZ,['Subtracted mean of ',...
            regionStr,' from data.'],verbose);
    end
end
end

function [PHZ,do_blc,do_restore] = verifyBLinput(PHZ,region,verbose)

% parse region input
if length(region) == 1 && region == 0
    
    % newBL == 0, oldBL == 0 (do nothing and return)
    if ~ismember('blc',fieldnames(PHZ))
        do_restore = false;
        do_blc = false;
        if verbose, disp('Baseline is already set to 0.'), end
        
    else % newBL == 0, oldBL == val
        do_restore = true;
        do_blc = false;
        
    end
    
else
    % newBL == val, oldBL == val
    if ismember('blc',fieldnames(PHZ))
        do_restore = true;
        do_blc = true;
        
    else % newBL == val, oldBL == 0
        do_restore = false;
        do_blc = true;
        
    end
end
end

function PHZ = getBLCstructure(PHZ)
PHZ.blc.region = '';
PHZ.blc.values = [];
end