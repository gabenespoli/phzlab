function PHZ = phz_blc(PHZ,region,varargin)
%PHZ_BLC  Subtract the mean of a baseline region from each trial.
% 
% PHZ = PHZ_BLC(PHZ,REGION) takes the mean of the region REGION for each
%   trial and subtracts it from that trial. REGION can be a string
%   specifying a region of interest (i.e., 'baseline', 'target', or other
%   region name specified in PHZ.spec.*_order), or a vector of length 2 
%   specifying the endpoints of the desired region in seconds (e.g., 
%   [-1 0]) or Hertz (e.g., [0 500]). Leaving REGION empty restores a
%   previously subtracted baseline (if there is one).
% 
%   New fields are created in the PHZ structure:
%     PHZ.blc.region = The value specified in REGION.
%     PHZ.blc.values = The value of the mean of the baseline region for
%                    each trial.
% 
% Written by Gabriel A. Nespoli 2016-02-16. Revised 2016-04-01.

if nargout == 0 && nargin == 0, help phz_blc, return, end
if nargin > 2, verbose = varargin{1}; else verbose = true; end
[PHZ,do_blc,do_restore] = phz_verifyBLinput(PHZ,region,verbose);

% if new baseline-subtraction is requested, do it
if do_blc || do_restore
    
%     % if things are rejected, un-reject first
%     if ismember('rej',fieldnames(PHZ))
%         threshold = PHZ.rej.threshold;
%         if ~isempty(threshold), PHZ = phz_rej(PHZ,[],verbose); end
%     else threshold = [];
%     end
    
    % restore previously-subtracted baseline
    if do_restore
        
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
        else
            PHZ.blc.values = mean(PHZb.data,2);
            PHZ.data = PHZ.data - repmat(PHZ.blc.values,[1 size(PHZ.data,2)]);
        end
        
        
        
        if ischar(region), region = PHZ.region.(region); end
        PHZ.blc.region = region;
        
        % add to history
        PHZ = phzUtil_history(PHZ,['Subtracted mean of ',...
            phzUtil_num2strRegion(region),' from data.'],verbose);
    end
    
%     % if things were rejected, re-reject
%     if ~isempty(threshold)
%         PHZ = phz_rej(PHZ,threshold,verbose);
%     end
end
end

function [PHZ,do_blc,do_restore] = phz_verifyBLinput(PHZ,region,verbose)

if all(isempty(region))
    
    if ~ismember('blc',fieldnames(PHZ))
        
        % newBL == 0, oldBL == 0 (do nothing and return)
        do_blc = false;
        do_restore = false;
%         if verbose, disp('Baseline is already set to [].'), end
        return
        
    else % newBL == 0, oldBL == val
        do_blc = false;
        do_restore = true;
        return
    end
    
elseif ismember('blc',fieldnames(PHZ))
    
    if ischar(region), newRegion = PHZ.region.(region);
    else               newRegion = region;
    end
    
    if all(newRegion == PHZ.blc.region)
        
        % newBL == val, oldBL == same val (do nothing and return)
        do_blc = false;
        do_restore = false;
        if verbose, disp('Baseline correction already done for this region.'), end
        return
        
    else % newBL == val, oldBL == different val (reset and continue)
        do_blc = true;
        do_restore = true;
    end
    
else % (otherwise newBL == val, oldBL == 0, no prep needed, continue)
    do_blc = true;
    do_restore = false;
end
end

function PHZ = getBLCstructure(PHZ)
PHZ.blc.region = [];
PHZ.blc.values = [];
end