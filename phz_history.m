function PHZ = phz_history(PHZ,str,verbose,check)
%PHZ_HISTORY Add item to the history of a PHZ structure.
%   Includes date, time, and name of caller function.
% 
% Written by Gabriel A. Nespoli 2016-02-08.

if nargout == 0 && nargin == 0, help phz_history, end

% parse input
if nargin < 3, verbose = true; end
if nargin < 4, check = true; end

[st,i] = dbstack;
caller_function = st(i+1).file;

PHZ.history{end+1} = [datestr(now),' ',caller_function,'>> ',str];

if verbose, disp(str), end

if check, PHZ = phz_check(PHZ,verbose); end

end
