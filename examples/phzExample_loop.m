%PHZEXAMPLE_LOOP
%   Loop through many raw data files, call a function to create PHZ files
%   that is specific to a given study, and save each file as a PHZ file.
%
% USAGE
%   PHZ = phzExample_loop(folder)
%   PHZ = phzExample_loop(files)
%   PHZ = phzExample_loop(folder, files)
%   PHZ = phzExample_loop(files, folder)
%
% INPUT
%   folder    = [string] The folder containing the raw data. If 'files' is
%               not given, this script will load all .mat files in this
%               folder. If files is given, this folder will be prepended
%               to each filename.
%
%   files     = [string|cell of strings] A file or list of files to load.
%
%   NOTES:      If one input is given and it is a string, this function
%               will check if it is a folder or a file, and treat it
%               appropriately. If no input is given at all, a dialog box
%               will pop up to select files.
%
% OUTPUT
%   *.phz:      PHZ files are saved in the same folder, using the same
%               filename, but with the .phz extension instead of .mat.
%

function phzExample_loop(varargin)

%% get raw data filenames
if nargin > 0 && nargin < 3
    for i = 1:length(varargin)
        if ischar(varargin{i}) && isdir(varargin{i}) % folder
            folder = varargin{i};
        elseif (ischar(varargin{i}) && exist(varargin{i}, 'file')) || ...
                iscell(varargin{i}) % file(s)
            files = cellstr(varargin{i});
        end
    end
else
    % pop-up window to select files
    [files,folder] = uigetfile('.mat','MultiSelect','on');
end

% get all files in folder
if ~exist('files', 'var') && ~isempty(folder)
    d = dir(folder); % get files in folder
    names = {d.name}; % get only filenames
    ind = regexp(names, '^.*\.mat$'); % get only mat files
    ind = ~cellfun(@isempty, ind); % convert cell to vector
    files = names(ind);
end

% prepend folder to each filename
if ~isempty(folder)
    for i = 1:length(files)
        files{i} = fullfile(folder, files{i});
    end
end

%% loop through files
for i = 1:length(files)

    % make sure file exists, display progress
    if exist(files{i}, 'file')
        [pathstr,name] = fileparts(files{i});
    else
        pathstr = folder;
    end
    currentFile = fullfile(pathstr,[name,'.mat']); % force .mat ext
    if ~exist(currentFile, 'file')
        warning(['File ''', currentFile, ''' not found. Skipping...'])
        continue
    else
        fprintf('Processing ec file %i/%i: ''%s''\n', ...
                i, length(files), currentFile)
    end

    % call a custom phz_create script on this file
    % for example, modify phzExample_SCL.m or phzExample_ABR.m to include
    %   settings specific to your data
    % ------------------------------------------------------------- %

    PHZ = my_phz_create_function(filename);

    % ------------------------------------------------------------- %

    % save the phz file
    saveFile = fullfile(pathstr, [name, '.phz']); % use .phz ext
    phz_save(PHZ, saveFile);

end

end
