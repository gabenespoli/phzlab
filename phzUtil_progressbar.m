function w = phzUtil_progressbar(w,val,str)
%PHZUTIL_PROGRESSBAR  Text progress bar in the command window.

if nargin < 3, str = '';
elseif length(str) > 25, str = ['\n' str]; end

del = repmat('\b',1,length(w)-1);
dot = floor(val * 20);
pct = num2str(floor(val * 100));
pct = [repmat(' ',1,3-length(pct)),pct,'%% '];

w = [pct,'[',repmat('.',1,dot),repmat(' ',1,20 - dot) ']'];
w = [w str];

fprintf([del w])
if val == 1, fprintf('\n'), end

end