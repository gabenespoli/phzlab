%PHZ_SAVE  Save a PHZ or PHZS structure.
% 
% USAGE
%   PHZ = phz_load(PHZ)
%   PHZ = phz_load(PHZ,filename)
% 
% INTPUT
%   PHZ           = [struct] PHZLAB data structure to save.
% 
%   filename      = [string] Filename (and path) of save location.
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

function PHZ = phz_save(PHZ,varargin)

if nargout == 0 && nargin == 0, help phz_save, return, end

% get filename with dialog box
if nargin == 1
    [filename,pathname] = uiputfile({'*.phz';'*.*'},'Select file to write',[inputname(1),'.phz']);
    filename = fullfile(pathname,filename);
end

% use filename from input argument
if nargin > 1
    [pathname,filename,ext] = fileparts(varargin{1});
    if isempty(ext) || ~ismember(ext,{'.phz','.mat'}), ext = '.phz'; end
    filename = fullfile(pathname,[filename,ext]);
end

% ask about overwriting an existing filename
if exist(filename,'file') && nargin > 2
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

if nargin > 2
    verbose = varargin{2};
else
    verbose = true;
end

PHZ.lib.filename = filename;

PHZ = phz_history(PHZ,['Saved to ''',filename,'''.'],verbose);

fprintf('  Saving...')

save(filename,'PHZ')

fprintf(' Done.\n')
end
