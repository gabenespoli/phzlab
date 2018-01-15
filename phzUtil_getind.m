%PHZUTIL_GETIND  Get indices of closest values.
% IND = GETIND(X,VAL) searches in X for the closest values of VAL, and
%   returns the indices of these values.

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

function ind = phzUtil_getind(x,val)

if nargout == 0 && nargin == 0, help phzUtil_getind, end

ind=nan(length(val),1);
for i=1:length(val)
    [~,ind(i)]=min(abs(x-val(i)));
end
end
