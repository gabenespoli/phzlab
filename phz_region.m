%PHZ_REGION  Restrict data to a specified time or frequency region.
% 
% USAGE
%   PHZ = phz_region(PHZ,REGION)
% 
% INPUT   
%   PHZ     = PHZLAB data structure.
% 
%   REGION  = A string specifying a region in PHZ.region, a 1-by-2 vector
%               specifying the start and end times in seconds, or a 1-by-N
%               vector (length > 2) of indices.
% 
% OUTPUT
%   PHZ.data          = Data for specified region only.
%   PHZ.region        = Value specified in REGION.
% 
% EXAMPLES
%     PHZ = phz_region(PHZ,'target') >> Restricts PHZ.data to the 'target'
%           region only.
%     PHZ = phz_region(PHZ,[0 3]) >> Restricts PHZ.data to the region from
%           0 to 3 seconds.
%     PHZ = phz_region(PHZ,[1:3001]) >> Restricts PHZ.data to the region
%           from the first sample to the 3001st sample. For a sampling rate
%           of 1000 Hz, this would correspond to 0-3 seconds.

% Copyright (C) 2018 Gabriel A. Nespoli, gabenespoli@gmail.com
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

function PHZ = phz_region(PHZ,region,verbose)

if nargout == 0 && nargin == 0, help phz_region, return, end
if isempty(region), return, end
if ~isnumeric(region) && ~ischar(region), error('Invalid region.'), end
if nargin < 3, verbose = true; end

% get ind field
if ismember('times',fieldnames(PHZ)), indField = 'times';
elseif ismember('freqs',fieldnames(PHZ)), indField = 'freqs';
end

% convert input to vector of indices
possibleRegions = PHZ.lib.tags.region;

if isnumeric(region) && length(region) == 1
    region = possibleRegions{region};
end

regionLabel = '';
if ischar(region)
    if ismember(region,possibleRegions)
        regionLabel = [region,                 ' [', ...
            num2str(PHZ.region.(region)(1)),   ' ', ...
            num2str(PHZ.region.(region)(end)), ']'];
        region = PHZ.region.(region);
        if isempty(region), error('This region is empty.'), end
    else
        error('Invalid region.')
    end
end

if length(region) == 2
    if isempty(regionLabel)
        regionLabel = ['region',  ' [', ...
            num2str(region(1)),   ' ', ...
            num2str(region(end)), ']'];
    end
    ind1 = getind(PHZ.(indField), region(1));
    ind2 = getind(PHZ.(indField), region(2));
    if ind1 == ind2
        warning('Region is only 1 sample long.')
    end
    region = ind1:ind2;
end

if isempty(region), error('Region is empty.'), end

% restrict ABR stim to same region
if ismember('stim', fieldnames(PHZ.lib)) && ...
    length(PHZ.lib.stim) == size(PHZ.data,2)
    PHZ.lib.stim = PHZ.lib.stim(region);
end

% restrict PHZ.data to specified region
PHZ.data = PHZ.data(:,region);
PHZ.(indField) = PHZ.(indField)(region);

% cleanup PHZ fields
PHZ.region = regionLabel;

PHZ = phz_history(PHZ,['Restricted to ''',regionLabel,''' region.'],verbose);

end

function ind = getind(x,val)
%GETIND  Get indices of closest values.
% IND = GETIND(X,VAL) searches in X for the closest values of VAL, and
%   returns the indices of these values.

ind=nan(length(val),1);
for i=1:length(val)
    [~,ind(i)]=min(abs(x-val(i)));
end
end
