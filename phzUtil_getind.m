%PHZUTIL_GETIND  Get indices of closest values.
% IND = GETIND(X,VAL) searches in X for the closest values of VAL, and
%   returns the indices of these values.

function ind = phzUtil_getind(x,val)

if nargout == 0 && nargin == 0, help phzUtil_getind, end

ind=nan(length(val),1);
for i=1:length(val)
    [~,ind(i)]=min(abs(x-val(i)));
end
end