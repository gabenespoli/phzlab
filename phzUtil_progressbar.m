%PHZUTIL_PROGRESSBAR  Text progress bar in the command window.
% 
% Usage:
%   w = phzUtil_progressbar(w,val,str)
% 
% Input:
%   w     = [string] Pass an empty value ('') to initiate the progress bar.
%           This function will return a value for w (the number of
%           characters to delete on the next loop), so pass that value in
%           here on the next loop.
% 
%   val   = [numeric] Value between 0 and 1 indicating how much progress
%           is complete. When a value of 1 is passed, the progress bar is
%           printed with a newline ('\n') at the end.
% 
%   str   = [string] Optional text to display on the line above the
%           progress bar. 
% 
% Output:
%   w     = The string that was printed for the current update of the
%           progress bar. Pass this variable in on the next loop so that
%           the function knows how many characters to delete before
%           printing the next progress update.
%

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

function w = phzUtil_progressbar(w,val,str)

waitchar = '=';

if nargin < 3
    str = '';
    extraChars = 1;
else
    str = [str '\n'];
    extraChars = 2;
end

if usejava('desktop') % using matlab gui

    del = repmat('\b',1,length(w)-1-extraChars); % extra -2 for the newline chars
    dot = floor(val * 20);
    pct = num2str(floor(val * 100));
    pct = [repmat(' ',1,3-length(pct)),pct,'%% '];

    w = ['[',repmat(waitchar,1,dot),repmat(' ',1,20 - dot) '] ',pct];
    w = [str w '\n'];

    fprintf([del w])

else % using -nodisplay option to run matlab in a terminal

    if isempty(w)
        fprintf('  %s\n', str(1:end-2)) % \n has already been appended
        fprintf('  [%s]\n', repmat(' ', 1, 20))
        fprintf('  [')
        w = 0;
        return
    end

    dot = floor(val * 20);
    if dot > w
        fprintf('%s', repmat(waitchar, 1, dot - w))
        w = dot;
    end

    if val == 1
        fprintf('] 100%%\n')
    end

end
end
