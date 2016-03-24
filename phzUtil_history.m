function PHZ = phzUtil_history(PHZ,str,varargin)
%PHZUTIL_HISTORY Add item to the history of a PHZ structure.
%   Includes date, time, and name of caller function.
% 
% Written by Gabriel A. Nespoli 2016-02-08.

if nargout == 0 && nargin == 0, help phzUtil_history, end

% parse input
if nargin > 2, verbose = varargin{1}; else verbose = true; end

[st,i] = dbstack;
caller_function = st(i+1).file;

PHZ.history{end+1} = [datestr(now),' ',caller_function,'>> ',str];

if verbose, disp(str), end

PHZ = phz_check(PHZ,0);

end
