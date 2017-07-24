%PHZ_LOAD  Load a PHZ structure (.phz or .mat file).
% 
% USAGE
%   PHZ = phz_load
%   PHZ = phz_load(filename)
% 
% INPUT
%   (none)    = A file browser will popup to select a file.
% 
%   filename  = [string] Filename (and path) of file to load.
% 
% OUTPUT
%   PHZ       = [struct] PHZLAB data structure.
% 
% EXAMPLES
%   PHZ = phz_load >> Browse computer to select a file to load.
% 
%   PHZ = phz_load('myfile.phz') >> Loads the file 'myfile.phz' from the
%         current directory.
% 
%   PHZ = phz_load('myfolder/myfile.phz') >> Loads the file 'myfile.phz'
%         from the folder 'myfolder'.

% Copyright (C) 2016 Gabriel A. Nespoli, gabenespoli@gmail.com
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

function PHZ = phz_load(varargin)

if nargout == 0 && nargin == 0, help phz_load, return, end

% get filename if none given
if nargin == 0
    [filename,pathname] = uigetfile({'*.phz','PHZ-files (*.phz)';'*.mat','MAT-files (*.mat)'},'Select a PHZ file to load...');
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
    if i > length(name), rethrow(me), end %#ok<NODEF>
    try 
        PHZ = S.(name{i});
        PHZ = phz_check(PHZ,verbose);
        badFile = false;
    catch me %#ok<NASGU>
        i = i + 1;
    end
end

PHZ = phz_history(PHZ,['Loaded variable ''',name{i},''' from ''',filename,'''.'],0);

end
