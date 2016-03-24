function PHZ = phz_save(PHZ,varargin)
%PHZ_SAVE  Save a PHZ or PHZS structure.
% 
% PHZ = PHZ_SAVE(PHZ) opens a dialog box to select save location.
% PHZ = PHZ_SAVE(PHZ,FILENAME) saves PHZ to FILENAME as a '.mat' file.
% 
% See also PHZ_LOAD, PHZ_CHECK.
%
% Written by Gabriel A. Nespoli 2016-03-04.

if nargout == 0 && nargin == 0, help phz_save, return, end

if nargin == 1
    [filename,pathname] = uiputfile({'*.mat';'*.*'});
    filename = fullfile(pathname,filename);
end

if nargin > 1
    [pathname,filename,ext] = fileparts(varargin{1});
    if isempty(ext), ext = '.mat'; end
    filename = fullfile(pathname,[filename,ext]);
end

if nargin > 2
    verbose = varargin{2};
else verbose = true;
end

PHZ = phzUtil_history(PHZ,['Saved to ''',filename,'''.'],verbose);

fprintf('Saving...')

save(filename,'PHZ')

fprintf(' Done.\n')
end