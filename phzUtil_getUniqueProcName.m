%PHZUTIL_GETUNIQUEPROCNAME  Finds a unique string for current processing 
%   when adding to PHZ.proc. For example, when adding a 'transform' 
%   field to PHZ.proc when there already is one, this function will 
%   return 'transform2'.
% 
% USAGE
%   name = phzUtil_getUniqueProcName(PHZ,basename)
% 
% INPUT
%   PHZ           = [struct] PHZLAB data structure.
% 
%   basename      = [string] Name of processing to make unique.

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

function name = phzUtil_getUniqueProcName(PHZ, basename)
if ~ischar(basename)
    error('Basename must be a string.')
end
names = fieldnames(PHZ.proc);

if ~ismember(basename, names)
    name = basename;
    
else
    goodName = false;
    counter = 2;
    while goodName == false
        name = [basename, int2str(counter)];
        if ~ismember(name, names)
            goodName = true;
        else
            counter = counter + 1;
        end
    end
    
end
end
