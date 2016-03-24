function [y,ind] = phzUtil_smooth(x,varargin)
%PHZUTIL_SMOOTH  Smooth data with a moving point average
% [Y,IND] = PHZUTIL_SMOOTH(X,(PTS))
%   Y is the smoothed data.
%   IND is a vector with the new indices of Y.
%   X can be a vector or matrix. If matrix, each row of data is smoothed.
%   PTS optionally sets the number of points in the moving average. If a
%       number < 1, PTS is set to this proportion of the total length of X,
%       rounded. Default is 0.05.
% 
% Written by Gabriel A. Nespoli 2016-03-14.

if nargout == 0 && nargin == 0, help phzUtil_smooth, end

% defaults
pts = round(size(x,2) * 0.05);
ind = 1:size(x,2);

% user-defined
if nargin > 1
    if varargin{1} > 1,    pts = varargin{1};
    elseif varargin{1} < 1, pts = round(size(x,2) * varargin{1});
    elseif varargin{1} == 1, disp('No smoothing done.'), return
    else warning('Ignoring PTS input to PHZUTIL_SMOOTH.')
    end
end

% do smoothing
ind = ind(1 + round(pts / 2) : end - round(pts / 2));
y = nan(size(x,1),pts + 1,length(ind));
for i = 1:size(y,3)
    y(:,:,i) = x(:,i:i + pts);
end
y = permute(mean(y,2),[1 3 2]);

end
