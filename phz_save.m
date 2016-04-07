function PHZ = phz_save(PHZ,varargin)
%PHZ_SAVE  Save a PHZ or PHZS structure.
% 
% usage:    PHZ = PHZ_LOAD(PHZ)
%           PHZ = PHZ_LOAD(PHZ,FILENAME)
% 
% inputs:   PHZ      = PHZLAB data structure to save.
%           FILENAME = Filename (and path) of save location.
% 
% outputs:  PHZ.history = Updated to reflect the save action.
% 
% examples:
%   PHZ = phz_save(PHZ) >> Browse computer to select a save location.
%   PHZ = phz_save(PHZ,'myfile') >> Saves the PHZ structure 'PHZ' to
%         the file 'myfile.phz' in the current directory.
%   PHZ = phz_save('myfolder/myfile.phz') >> Saves the PHZ structure 'PHZ'
%         to the file 'myfile.phz' in the folder 'myfolder'.
%
% Written by Gabriel A. Nespoli 2016-03-07. Revised 2016-04-04.
if nargout == 0 && nargin == 0, help phz_save, return, end

if nargin == 1
    [filename,pathname] = uiputfile({'*.phz';'*.*'});
    filename = fullfile(pathname,filename);
end

if nargin > 1
    [pathname,filename,ext] = fileparts(varargin{1});
    if isempty(ext) || ~ismember(ext,{'.phz','.mat'}), ext = '.phz'; end
    filename = fullfile(pathname,[filename,ext]);
end

if nargin > 2
    verbose = varargin{2};
else verbose = true;
end

PHZ.misc.filename = filename;

PHZ = phz_history(PHZ,['Saved to ''',filename,'''.'],verbose);

fprintf('Saving...')

save(filename,'PHZ')

fprintf(' Done.\n')
end