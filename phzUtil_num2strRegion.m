%PHZUTIL_NUM2STRREGION  Converts a length-2 numeric vector to a string
%   without leaving so much space between the two numbers, as happens when
%   just using num2str (e.g., '[1  5]' instead of '[1      5]'. The second 
%   input, if non-empty, is the delimiter, and the surrounding brackets
%   are left off.
%
% EXAMPLES
%    >> phzUtil_num2strRegion([1 5]) = '[1  5]'
%
%    >> phzUtil_num2strRegion([1 5], '-') = '1-5'

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

function str = phzUtil_num2strRegion(num,delim)

if nargout == 0 && nargin == 0, help phzUtil_num2strRegion, end
if nargin < 2, delim = ''; end

if isempty(num), str = ''; end
if length(num) == 1
    str = num2str(num);
    
elseif length(num) == 2
    num1 = num2str(num(1));
    num2 = num2str(num(2));
    if isempty(delim)
        str = ['[',num1,'  ',num2,']'];
    else
        str = [num1,delim,num2];
    end
end
end
