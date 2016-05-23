%PHZUTIL_BINMEAN  Averages specified bins in a vector. Usually used with
%   FFT data to find averages of a certain numer of frequency bins around
%   a frequency of interest.
% 
% USAGE
%   PHZ = phzUtil_binmean(PHZ,bins,width)
%   PHZ = phzUtil_binmean(PHZ,bins,width,'Param1',Value1,etc.)
% 
% INPUT
%   PHZ           = [struct] PHZLAB data structure.
% 
%   bins          = [numeric] Values in the TIMES or FREQS field to serve
%                   as center bins when averaging.
% 
%   width         = [numeric] The number of bins on either side of the
%                   center bin to average together. e.g., a width of 2
%                   would average a total of 5 bins (the center bin and 
%                   two bins on either side.
% 
%   'bintype'     = [1|0] Enter 0 to exclude the center bin from the
%                   average. Default 1.
% 
%   'binsaway'    = [numeric] If BINTYPE is 0 (exclude center bin), 
%                   BINSAWAY specifies the desired width of the center bin
%                   to ignore. BINMEAN will count a BINSAWAY number of bins
%                   on either side of the center bin before averaging a 
%                   WIDTH number of bins. Default 1.
% 
% OUTPUT
%   PHZ.data = [numeric] Means of specified bins.
%
% Written by Gabe Nespoli 2015-03-10. Revised for PHYZLAB 2016-03-19.

function PHZ = phzUtil_binmean(PHZ,bins,width,varargin)

if nargout == 0 && nargin == 0, help phzUtil_binmean, end

% defaults
binType = 1;
binsaway = 1;
verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'bintype',     binType = varargin{i+1};
        case 'binsaway',    binsaway = varargin{i+1};
        case 'verbose',     verbose = varargin{i+1};
    end
end

% get Y and X
y = PHZ.data;
if ismember('times',fieldnames(PHZ))
    x = PHZ.times;
    units = 's';
elseif ismember('freqs',fieldnames(PHZ))
    x = PHZ.freqs;
    units = 'Hz';
end

% check X is same length as dim 1 of Y
if length(x) ~= size(y,2), error('Length of X must be the same length as the 2nd dimension of Y.'), end

% create container variables
ind = nan(1,length(bins));
s = nan(size(y,1),length(bins));

% convert bin values to indices (find value of X closest to BIN value)
for i = 1:length(bins)
    [~,ind(i)] = min(abs(x - bins((i))));
end

% loop through bins and calculate means
for i = 1:length(ind)
    
    if ind(i) - width < 1 || ind(i) + width > length(x)
        error('BIN exceeds dimensions of X when combined with WIDTH.')
    end
    
    % get indicies of desired mean
    switch binType
        case 1 % mean of target bin and surrounding bins (default)
            tempind = ind(i) - width:ind(i) + width;
            
        case 0 % mean of only surrounding bins
            farbound = width + binsaway - 1;
            tempind = [ind(i) - farbound:ind(i) - binsaway,ind(i) + binsaway:ind(i) + farbound];
    end
    
    % calculate mean and put in container matrix
    s(:,i) = mean(y(:,tempind),2);
end

PHZ.data = s;
PHZ = phz_history(PHZ,['Averaged ',num2str(width * 2 + 1),' bins centered on ',num2str(bins),' ',units,'.'],verbose);

end