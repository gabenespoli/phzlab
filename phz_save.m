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
%
% Written by Gabriel A. Nespoli 2016-03-07. Revised 2016-05-25.

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
else verbose = true;
end

PHZ.meta.filename = filename;

PHZ = phz_history(PHZ,['Saved to ''',filename,'''.'],verbose);

fprintf('Saving...')

save(filename,'PHZ')

fprintf(' Done.\n')
end