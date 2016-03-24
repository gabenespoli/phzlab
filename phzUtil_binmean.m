function PHZ = phzUtil_binmean(PHZ,bins,width,varargin)
%PHZUTIL_BINMEAN  Averages specified bins in a vector.
%   S = PHZUTIL_BINMEAN(Y,X,BINS,WIDTH) finds the indices of the values 
%       BINS in vector X, finds these bins in each row of Y, and returns
%       the average of a WIDTH number of bins on either side of the center
%       bin. A common use is when Y is fft data and X is the corresponding
%       frequency vector, and BINS is the frequencies of interest. For
%       matrices, BINMEAN operates on the first non-singleton dimension.
%
%   S = PHZUTIL_BINMEAN(...,TYPE) specifies one of the following things:
%       1 = specified bin and bins on either side are included (default)
%       0 = specified bin is excluded, bins are either side only are used
%
%   S = PHZUTIL_BINMEAN(...,0,BINSAWAY) If TYPE is 0 (do not include 
%       specified bin), BINSAWAY specifies the desired width of the center 
%       bin to ignore. BINMEAN will count a BINSAWAY number of bins on 
%       either side of the center bin before averaging a WIDTH number of
%       bins.
%
% Written by Gabe Nespoli 2015-03-10. Revised for PHYZLAB 2016-03-19.

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
PHZ = phzUtil_history(PHZ,['Averaged ',num2str(width * 2 + 1),' bins centered on ',num2str(bins),' ',units,'.'],verbose);

end