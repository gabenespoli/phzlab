function PHZ = phz_load(varargin)
%PHZ_LOAD  Load a PHZ or PHZS structure.
% 
% PHZ = PHZ_LOAD opens a dialog box to select a file to load.
% PHZ = PHZ_LOAD(FILENAME) loads from FILENAME.
% 
% See also PHZ_SAVE, PHZ_CHECK.
%
% Written by Gabriel A. Nespoli 2016-03-07. Revised 2016-03-23.

if nargout == 0 && nargin == 0, help phz_load, return, end

if nargin == 0
    [filename,pathname] = uigetfile('.mat','Select a PHZ file to load...');
    if filename == 0, return, end
    filename = fullfile(pathname,filename);
else
    [pathname,filename,ext] = fileparts(varargin{1});
    filename = fullfile(pathname,[filename,ext]);
end

if nargin > 1, verbose = varargin{2}; else verbose = false; end

if ~exist(filename,'file'), error('File doesn''t exist.'), end

S = load(filename);
name = fieldnames(S);

i = 1;
badFile = true;
while badFile
    if i > length(name), rethrow(me), end
    try 
        PHZ = S.(name{i});
        PHZ = phz_check(PHZ,verbose);
        badFile = false;
    catch me
        i = i + 1;
    end
end

PHZ = phzUtil_history(PHZ,['Loaded variable ''',name{i},''' from ''',filename,'''.'],0);

end