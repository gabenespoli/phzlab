%PHZ_HISTORY Add item to the history of a PHZ structure. Includes date,
%   time, and name of caller function. This function is usually called 
%   from another PHZLAB function.
% 
% USAGE
%   PHZ = phz_history(PHZ,str)
%   PHZ = phz_history(PHZ,str,verbose,check)
% 
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
% 
%   str       = [string] Message to add to history field. The name of the
%               caller function and the date and time are also included.
% 
%   verbose   = [true|false] Specifies whether to print the history
%               message in the command window. Default true.
% 
%   check     = [true|false] Specifies whether to also run phz_check.
%               Default true.
% 
% OUTPUT
%   PHZ       = [struct] PHZLAB data structure with history item added.

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

function PHZ = phz_history(PHZ,str,verbose,check)

if nargout == 0 && nargin == 0, help phz_history, end
if nargin < 3, verbose = true; end
if nargin < 4, check = true; end

[st,i] = dbstack;
caller_function = st(i+1).file;

PHZ.history{end+1} = [datestr(now),' ',caller_function,'>> ',str];

if verbose, disp(str), end

if check, PHZ = phz_check(PHZ,verbose); end

end
