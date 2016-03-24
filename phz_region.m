function PHZ = phz_region(PHZ,region,varargin)
%PHZ_REGION  Restrict data to a specified time or frequency region.
% 
% PHZ = PHZ_REGION(PHZ,REGION) deletes portions of PHZ.data that are
%   outside of the specified time or frequency region REGION. REGION can be
%   a string specifying a region (e.g., 'baseline', 'target'), a 1-by-2
%   numeric vector with start and end times in seconds (or frequencies in
%   Hz (e.g., [0 3]), or a 1-by-N numeric vector of indices
%   (e.g., [1:3001]).
%
%   Fields are changed in the PHZ structure:
%     PHZ.region = The value specified in REGION.
% 
% Written by Gabriel A. Nespoli 2016-02-08. Revised 2016-03-21.

if nargout == 0 && nargin == 0, help phz_region, return, end

if isempty(region), return, end

% defaults
regionLabel = '';
verbose = true;

% check input
if ~isnumeric(region) && ~ischar(region), error('Invalid region.'), end
if nargin > 2, verbose = varargin{1}; end

% get ind field
if ismember('times',fieldnames(PHZ)), indField = 'times';
elseif ismember('freqs',fieldnames(PHZ)), indField = 'freqs';
end

% convert input to vector of indices
possibleRegions = PHZ.spec.region_order;

if isnumeric(region) && length(region) == 1;
    region = possibleRegions{region};
end

if ischar(region)
    if ismember(region,possibleRegions)
        regionLabel = region;
        region = PHZ.region.(region);
        if isempty(region), error('This region is empty.'), end
    else error('Invalid region.')
    end
end

if length(region) == 2
    if isempty(regionLabel), regionLabel = phzUtil_num2strRegion(region); end
    region = getind(PHZ.(indField),region(1)):getind(PHZ.(indField),region(2));
end

if isempty(region), error('Region is empty.'), end

% restrict PHZ.data to specified region
PHZ.data = PHZ.data(:,region);
PHZ.(indField) = PHZ.(indField)(region);
if ismember('rej',fieldnames(PHZ)), 
    PHZ.rej.data = PHZ.rej.data(:,region);
end

% cleanup PHZ fields
PHZ.region = regionLabel;

PHZ = phzUtil_history(PHZ,['Restricted to ''',regionLabel,''' region.'],verbose);

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