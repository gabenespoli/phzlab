function phzUtil_biopacSplit(files,varargin)
%PHZUTIL_BIOPACSPLIT  Split Biopac data into separate files per channel.
% 
% Written by Gabriel A. Nespoli 2016-03-29.

if nargin == 0, files = []; end

% defaults
folder = '';
savefolder = '';
differentFolders = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'savefolder',          savefolder = varargin{i+1};
        case 'differentfolders',    differentFolders = varargin{i+1};
    end
end

% get cell array of data file names
if isdir(files) % load all files from folder
    folder = files;
    files = what(folder);
    files = files.mat;
    
elseif ischar(files) && exist(files,'file') % load file from filename
    files = {files};
    
elseif isempty(files) % prompt to select file(s)
    [files,folder] = uigetfile('.mat','Select data file(s)...','MultiSelect','on');
    if isnumeric(files) && files == 0, return, end
    if ischar(files), files = {files}; end
    
elseif ~iscell(files)  % (load many files from cell array of filenames)
    error('Problem with FILES input.')
    
end

% loop files
w = waitbar(0,'Splitting Biopac files...');
for i = 1:length(files)
    fileProgress = [num2str(i),'/',num2str(length(files)),': ',files{i}];
    waitbar((i-1)/length(files),w,['Splitting Biopac file ',fileProgress]);
    
    % load data
    [pathstr,name,ext] = fileparts(files{i});
    if ~isempty(pathstr), folder = pathstr; files{i} = [name,ext]; end
    
    s = load(fullfile(folder,files{i}),'-mat');
    
    if isempty(savefolder), savefolder = folder; end
    s.labels = cellstr(s.labels);
    
    for j = size(s.data,2):-1:1 % count backwards so that duplicate labels are ordered correctly
        data = s.data(:,j);
        isi = s.isi;
        isi_units = s.isi_units;
        labels = s.labels{j};
        start_sample = s.start_sample;
        units = s.units(j,:);
        
        % deal with duplicate label names
        baseLabel = labels;
        counter = 1;
        badLabel = true;
        while badLabel
            counter = counter + 1;
            otherLabels = s.labels;
            otherLabels(j) = [];
            if ismember(labels,otherLabels)
                labels = [baseLabel,num2str(counter)];
                s.labels{j} = labels;
            else badLabel = false;
            end
            
        end
        
        % create directory if it doesn't exist
        if differentFolders
            if ~exist(fullfile(savefolder,labels),'dir'), mkdir(fullfile(savefolder,labels)), end
            save(fullfile(savefolder,labels,[labels,'-',files{i}]),...
                'data','isi','isi_units','labels','start_sample','units')
        else
            save(fullfile(savefolder,[labels,'-',files{i}]),...
                'data','isi','isi_units','labels','start_sample','units')
        end
        
    end
    
    
    
    
    
end
close(w)
disp('Done splitting Biopac file(s).')
end