function w = phzUtil_progressbar(w,val,str)
%PHZUTIL_PROGRESSBAR  Text progress bar in the command window.
% 
% USAGE
%   W = phzUtil_progressbar(w,val,str)
% 
% INPUT
%   w     = 
% 
%   val   = [numeric] Value between 0 and 1 indicating how much progress
%           is complete.
% 
%   str   = [string] Text to display alongside the progress bar.
% 
% OUTPUT
% 
%   w     = 

% Copyright (C) 2016 Gabriel A. Nespoli, gabenespoli@gmail.com
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