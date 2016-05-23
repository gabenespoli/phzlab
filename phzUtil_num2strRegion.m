%PHZUTIL_NUM2STRREGION  Converts a length-2 numeric vector to a string
%   without leaving so much space between the two numbers, as happens when
%   just using num2str.

function str = phzUtil_num2strRegion(num)

if nargout == 0 && nargin == 0, help phzUtil_num2strRegion, end

if isempty(num), str = ''; end
if length(num) == 1
    str = num2str(num);
    
elseif length(num) == 2
    str = ['[',num2str(num(1)),'  ',num2str(num(2)),']'];
    
end
end