%PHZUTIL_GETUNIQUESAVENAME  Prompt the user if filename exists.
%   Options are o to overwrite the existing file, a to append a number 
%   (e.g., 'filename.phz' becomes 'filename2.phz'), e to manually enter a
%   new filename, s to skip (returns an empty string), or c to cancel
%   (throws an error).
% 
% USAGE
%   filename = phzUtil_getUniqueSaveName(filename)
%   filename = phzUtil_getUniqueSaveName(filename, append)
% 
% INPUT
%   filename  = [string] 
%
%   force     = [0|1|2] What to do if the given filename exists. 0 will
%               prompt the user for what to do, 1 will append a number to
%               the filename, and 2 will overwrite it. Default 0.
%
% OUTPUT
%   filename = [string] The unique filename. Returns empty if the the 
%              user wants to cancel.

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

function filename = phzUtil_getUniqueSaveName(filename, force)
if nargin < 2, force = 0; end

if ~exist(filename, 'file') 
    return
else
    if force == 2
        fprintf('  Overwriting existing file: ''%s''...\n', filename)
        return
    elseif force == 1
        fprintf('  Appending unique number to existing filename: ''%s''...\n', filename)
        filename = appendUniqueNumber(filename);
        return
    else
        fprintf('  Filename already exists: ''%s''\n', filename)
    end
end

goodInput = false;
while goodInput == false
    s = input(['  [o]verwrite, [s]kip, [c]ancel, ',...
                 '[a]ppend number, or [e]dit filename?: '],'s');
    switch lower(s)
        case 'o'
            goodInput = true;

        case 's'
            filename = '';
            disp('Aborting...')
            goodInput = true;

        case 'c'
            error('Filename exists. Execution cancelled by the user.')

        case 'a'
            filename = appendUniqueNumber(filename);
            goodInput = true;

        case 'e'
            fprintf('Old filename: %s\n', filename)
            filename = input('New filename: ', 's');
            if isempty(filename) || ~exist(filename,'file')
                goodInput = true;
            end
        otherwise, disp('Invalid input.')
    end
end
end

function filename = appendUniqueNumber(filename)
goodName = false;
counter = 2;
[pathstr,name,ext] = fileparts(filename);
while goodName == false
    filename = fullfile(pathstr,[name,'_',num2str(counter),ext]);
    if ~exist(filename,'file')
        goodName = true;
    else
        counter = counter + 1;
    end
end
end
