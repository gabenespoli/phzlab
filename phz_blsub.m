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
%   PHZ.proc.blsub.region   = Start and end times of blsub region used.
%   PHZ.proc.blsub.values   = Mean of baseline region for each trial.
%
% EXAMPLES
%   PHZ = phz_blsub(PHZ,'baseline') >> Subtract the mean of the baseline
%         region (as specified in PHZ.region.baseline) from each trial.
%   PHZ = phz_blsub(PHZ,[-1 0]) >> Subtract the mean of -1s to 0s.
%   PHZ = phz_blsub(PHZ,0) >> Undo baseline subtraction.

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
        if ~ismember(names{end},{'blsub'})
            error(['Other processing has been done since baseline ',... 
                'subtraction. Cannot undo previous baseline subtraction.'])
        end
        
        PHZ.data = PHZ.data + repmat(PHZ.proc.blsub.values,1,size(PHZ.data,2));
        
        PHZ.proc = rmfield(PHZ.proc,'blsub');
        PHZ = phz_history(PHZ,'Added back previously removed baseline.',verbose);
    end
    
    % subtract mean of new baseline region
    if do_blsub
        
        % get and subtract baseline
        PHZb = phz_region(PHZ,region,0);
        PHZ = getBLSUBstructure(PHZ);
        
        PHZ.proc.blsub.values = mean(PHZb.data,2);
        PHZ.data = PHZ.data - repmat(PHZ.proc.blsub.values,[1 size(PHZ.data,2)]);
        
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
    if ~ismember('blsub',fieldnames(PHZ.proc))
        do_restore = false;
        do_blsub = false;
        if verbose, disp('Baseline is already set to 0.'), end
        
    else % newBL == 0, oldBL == val
        do_restore = true;
        do_blsub = false;
        
    end
    
else
    % newBL == val, oldBL == val
    if ismember('blsub',fieldnames(PHZ.proc))
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
