function PHZ = phz_load(varargin)
%PHZ_LOAD  Load a PHZ structure (.phz or .mat file).
% 
% usage:    PHZ = PHZ_LOAD
%           PHZ = PHZ_LOAD(FILENAME)
% 
% inputs:   (none)   = A file browser will popup to select a file.
%           FILENAME = Filename (and path) of file to load.
% 
% outputs:  PHZ      = PHZLAB data structure.
% 
% examples:
%   PHZ = phz_load >> Browse computer to select a file to load.
%   PHZ = phz_load('myfile.phz') >> Loads the file 'myfile.phz' from the
%         current directory.
%   PHZ = phz_load('myfolder/myfile.phz') >> Loads the file 'myfile.phz'
%         from the folder 'myfolder'.
%
% Written by Gabriel A. Nespoli 2016-03-07. Revised 2016-04-04.
if nargout == 0 && nargin == 0, help phz_load, return, end

% get filename if none given
if nargin == 0
    [filename,pathname] = uigetfile({'.phz';'.mat'},'Select a PHZ file to load...');
    if filename == 0, return, end
    filename = fullfile(pathname,filename);
else
    [pathname,filename,ext] = fileparts(varargin{1});
    filename = fullfile(pathname,[filename,ext]);
end

% parse input
if nargin > 1, verbose = varargin{2}; else verbose = false; end

if ~exist(filename,'file'), error('File doesn''t exist.'), end

% load file
S = load(filename,'-mat');
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

PHZ = phz_history(PHZ,['Loaded variable ''',name{i},''' from ''',filename,'''.'],0);

end