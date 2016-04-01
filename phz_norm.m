function PHZ = phz_norm(PHZ,normtype,varargin)
%PHZ_NORM  Convert data to z-scores.
% 
% PHZ = PHZ_NORM(PHZ,NORMTYPE) converts data to z-scores based on the mean
%   and standard deviation of trials grouped by the grouping variable
%   NORMTYPE. NORMTYPE is a string specifying a grouping variable (i.e.,
%   'participant' (default), 'group', 'session', 'trials', 'all', or
%   'none'). A NORMTYPE of 'none' will take a new mean and standard
%   deviation for each trial, while 'all' will take one mean and standard
%   deviation for all trials.
% 
% Written by Gabriel A. Nespoli 2016-03-27. Revised 2016-03-30.
if nargin == 0 && nargout == 0; help phz_norm, end
if nargin == 1, normtype = 'participant'; end
if nargin > 1 && isempty(normtype), return, end

% defaults
verbose = true;

% user-defined
for i = 1:length(varargin)
    if ischar(varargin{i})
        normtype = varargin{i};
    
    elseif isnumeric(varargin{i}) || islogical(varargin{i})
        verbose = varargin{i};
        
    end
end
if isempty(normtype), return, end

% check input
normtype = lower(normtype);
if ~ismember(normtype,{'participant','group','session','trials','all','none'})
    error('Invalid NORMTYPE.')
end

% do normalization
if strcmp(normtype,'none')
    PHZ.data = (PHZ.data - repmat(mean(PHZ.data,2),1,size(PHZ.data,2))) / repmat(std(PHZ.data,[],2),1,size(PHZ.data,2));

elseif strcmp(normtype,'all') || length(PHZ.(normtype)) == 1
    PHZ.data = (PHZ.data - mean(PHZ.data(:))) / std(PHZ.data(:));
    
else
    for i = 1:length(PHZ.(normtype))
        ind = PHZ.tags.(normtype) == PHZ.(normtype)(i);
        data = PHZ.data(ind,:);
        PHZ.data(ind,:) = (data - mean(data(:))) / std(data(:));
    end
end

PHZ.units = 'z-scores';

if strcmp(normtype,'all'), normtype = 'all trials';
elseif strcmp(normtype,'none'), normtype = 'each trial';
end
PHZ = phzUtil_history(PHZ,['Converted data to z-scores by ',normtype,'.'],verbose);

end