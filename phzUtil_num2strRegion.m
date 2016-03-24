function str = phzUtil_num2strRegion(num)

if nargout == 0 && nargin == 0, help phzUtil_num2strRegion, end

if isempty(num), str = ''; end
if length(num) == 1
    str = num2str(num);
    
elseif length(num) == 2
    str = ['[',num2str(num(1)),'  ',num2str(num(2)),']'];
    
end
end