%PHZ_SAVE  Save a PHZ or PHZS structure.
% 
% USAGE
%   PHZ = phz_load(PHZ)
%   PHZ = phz_load(PHZ,filename,verbose,force)
% 
% INTPUT
%   PHZ           = [struct] PHZLAB data structure to save.
% 
%   filename      = [string] Filename (and path) of save location. Leave
%                   empty ('' or []) to be prompted to select a location
%                   with a dialog box.
% 
%   verbose       = [true|false] Specifies whether to print save progress
%                   in the command window. Default true.
%
%   force         = [true|false] If true, overwrite existing file if it
%                   exists, otherwise user will be prompted to overwrite,
%                   cancel, or change the filename. Default false.
%
% OUTPUT
%   PHZ.history   = Updated to reflect the save action.
% 
% EXAMPLES
%   PHZ = phz_save(PHZ) >> Browse computer to select a save location.
% 
%   PHZ = phz_save(PHZ,'myfile') >> Saves the PHZ structure 'PHZ' to
%         the file 'myfile.phz' in the current directory.
% 
%   PHZ = phz_save('myfolder/myfile.phz') >> Saves the PHZ structure 'PHZ'
%         to the file 'myfile.phz' in the folder 'myfolder'.

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

function PHZ = phz_save(PHZ,filename,verbose,force)

if nargout == 0 && nargin == 0, help phz_save, return, end
if nargin < 2, filename = ''; end
if nargin < 3, verbose = true; end
if nargin < 4, force = false; end

if isempty(filename)
    % get filename with dialog box
    [filename,pathname] = uiputfile({'*.phz';'*.*'},'Select file to write',[inputname(1),'.phz']);
    filename = fullfile(pathname,filename);
else
    % use filename from input argument
    [pathname,filename,ext] = fileparts(filename);
    if isempty(ext) || ~ismember(ext,{'.phz','.mat'}), ext = '.phz'; end
    filename = fullfile(pathname,[filename,ext]);
end

% ask about overwriting an existing filename
if exist(filename,'file') && ~force
    goodInput = false;
    while goodInput == false
        s = input('File already exists. Overwrite? [y/n]: ','s');
        switch lower(s)
            case 'y', goodInput = true;
            case 'n', disp('Aborting...'), return
            otherwise, disp('Invalid input.')
        end
    end
end

PHZ.lib.filename = filename;
PHZ = phz_history(PHZ,['Saved to ''',filename,'''.'],verbose);
if verbose, fprintf('  Saving...'), end
save(filename,'PHZ')
if verbose, fprintf(' Done.\n'), end

end
