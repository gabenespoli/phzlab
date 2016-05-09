function PHZ = phz_region(PHZ,region,verbose)
%PHZ_REGION  Restrict data to a specified time or frequency region.
% 
% usage:    
%     PHZ = phz_region(PHZ,REGION)
% 
% input:   
%     PHZ     = PHZLAB data structure.
% 
%     REGION  = A string specifying a region in PHZ.region, a 1-by-2 vector
%               specifying the start and end times in seconds, or a 1-by-N
%               vector (length > 2) of indices.
% 
% output:  
%     PHZ.data   = Data for specified region only.
% 
%     PHZ.region = Value specified in REGION.
% 
% examples:
%     PHZ = phz_region(PHZ,'target') >> Restricts PHZ.data to the 'target'
%           region only.
%     PHZ = phz_region(PHZ,[0 3]) >> Restricts PHZ.data to the region from
%           0 to 3 seconds.
%     PHZ = phz_region(PHZ,[1:3001]) >> Restricts PHZ.data to the region
%           from the first sample to the 3001st sample. For a sampling rate
%           of 1000 Hz, this would correspond to 0-3 seconds.
% 
% Written by Gabriel A. Nespoli 2016-02-08. Revised 2016-04-07.
if nargout == 0 && nargin == 0, help phz_region, return, end
if isempty(region), return, end
if ~isnumeric(region) && ~ischar(region), error('Invalid region.'), end
if nargin < 3, verbose = true; end

% get ind field
if ismember('times',fieldnames(PHZ)), indField = 'times';
elseif ismember('freqs',fieldnames(PHZ)), indField = 'freqs';
end

% convert input to vector of indices
possibleRegions = PHZ.meta.tags.region;

if isnumeric(region) && length(region) == 1;
    region = possibleRegions{region};
end

regionLabel = '';
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
    PHZ.proc.rej.data = PHZ.proc.rej.data(:,region);
end

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