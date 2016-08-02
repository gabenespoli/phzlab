%PHZ_CREATE  Create a new PHZ structure.
% 
% USAGE
%   PHZ = phz_create
%   PHZ = phz_create('Param1',Value1,etc.)
%   PHZ = phz_create('blank')
% 
% INPUT   
%   PHZ           = PHZLAB data structure.
% 
%   'filename'    = [string|cell of strings] Specifies the file(s) to
%                   import. If not specified, a dialog box pops up for you 
%                   to select a file or files. If FILES is a folder, all
%                   .mat files are used.
% 
%   'folder'      = [string] A folder path to prepend to each filename in
%                   FILES.
% 
%   'filetype'    = [string] The type of file that is being loaded. All
%                   files must be saved as matlab files (i.e., .mat), on
%                   whichever software they came from. Default is 'acq'
%                   for a Biopac AcqKnowledge file that has been saved
%                   a MATLAB .mat file.
% 
%   'channel'     = [numeric|string] Specify which channel of data to
%                   import. For Biopac data, 'channel' can be a string 
%                   specfying the name of the channel as specified in the 
%                   'labels' variable that is exported from Biopac. If no
%                   channel is specified, the user is prompted to enter a
%                   channel.
% 
%   'namestr'     = [string] Specifies the file naming convention in order 
%                   to read values for certain fields directly from the 
%                   filename. NAMESTR should contain any of the following 
%                   keywords: 'study', 'datatype', 'participant', 'group',
%                   'condition', or 'session'. Each must be separated 
%                   by a delimiter (e.g., 'datatype-participant_group').
%                   If NAMESTR is empty, no values are read from the 
%                   filename. If any value is specified with it's
%                   own parameter/value pair (i.e., 
%                   phz_create(...,'participant',1,...)), it will 
%                   overwrite the value obtained via NAMESTR.
% 
%   'study'       = Fills the 'study' field of the PHZ structure.
%   'datatype'    = Fills the 'datatype' field of the PHZ structure.
%   'participant' = Fills the 'participant' field of the PHZ structure.
%   'group'       = Fills the 'group' field of the PHZ structure.
%   'condition'   = Fills the 'condition' field of the PHZ structure.
%   'session'     = Fills the 'session' field of the PHZ structure.
% 
%   'savefolder'  = [string] The folder where the new PHZ file should be 
%                   saved. SAVEFOLDER must be specified if multiple PHZ 
%                   files are being created. Specify the empty string ('') 
%                   to use the same folder as where the data files are 
%                   saved. Default is not to save the new PHZ structure. 
%                   Files are saved using the phz_save function, the file
%                   will have the '.phz' extension, and should be loaded 
%                   using the phz_load function.
% 
% OUTPUT  
%   PHZ           = [struct] PHZ data structure with the following fields:
% 
%   study         = [string] Specifies the name of the study.
% 
%   datatype      = [string] Specifies the type of data in PHZ.data. Used
%                   for labelling plots.
% 
%   participant   = [categorical|string|numeric]
%   group         = [categorical|string|numeric]
%   condition     = [categorical|string|numeric]
%   session       = [categorical|string|numeric]
%   trials        = [categorical|string|numeric]
% 
%   region.(name) = [numeric] specifying endpoints of time regions of 
%                   interest (in s). Enter in the form [start end].
%                   Default region names are 'baseline', 'target',
%                   'target2', 'target3', and 'target4'. Region times and 
%                   names can be modified using the phz_field function with
%                   the keywords 'region' and 'regionnames', respectively.
% 
%   times         = [numeric] Vector of times for each sample (in s). 
%                   Must be same length as size(data,2).
% 
%   data          = [numeric] 2D array TRIALS-by-TIME.
% 
%   units         = [string] Units of data in PHZ.data.
% 
%   srate         = [numeric] Sampling frequency.
% 
%   resp.q1       = [cell] Behavioural responses to each trial. Must be a 
%                   column the same length as size(data,1). Also available
%                   are q2, q3, q4, and q5.
% 
%   resp.q1_acc   = [numeric] Column of accuracy values.
% 
%   resp.q1_rt    = [numeric] Column of reaction times.
% 
%   proc          = [struct] This field is auto-filled with info from
%                   processing functions that are used on this file. 
%                   Fields are inserted in chronological order and keep 
%                   the relevent values for recreating the analysis with
%                   another file. See phz_proc for more uses.
% 
%   meta.tags.*   = [categorical|cell] Specifies grouping variable labels
%                   for each row in PHZ.data. PHZ.meta.tags.(grpvar) are
%                   stored as categoricals and must be the same length as 
%                   the number of rows in data (i.e., number of epochs).
%                   PHZ.meta.tags.region is stored as a cell and must be
%                   the same length as the number of regions in PHZ.region.
%                   Regions can be added using phz_field.
% 
%   meta.spec.*   = [cell] Specifies the lineSpec property (incl. colour) 
%                   for plotting. Must be the same length as the 
%                   corresponding grouping variable (i.e., participant, 
%                   group, condition, session, or trials. See the help for
%                   the plot.m function for more details on lineSpec. These
%                   values can be changed using the phz_field function.
% 
%   misc          = [struct] Empty structure for user to store data of any
%                   type. There are some PHZLAB functions that access 
%                   certain fields from PHZ.misc (e.g., FFR
%                   stimulus-response correlation), but in general you can 
%                   do whatever you want here.
% 
%   history       = [cell] Every time a PHZLAB function is called on this
%                   file, a new row is added to PHZ.history (using the
%                   phz_history function) specifying what happened.

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

function PHZ = phz_create(varargin)

if nargout == 0 && nargin == 0, help phz_create, return, end

if nargin == 1 && strcmp(varargin{1},'blank'), PHZ = getBlankPHZ(1); return, end

files = '';
folder = '';

namestr = '';

study = ''; %#ok<NASGU>
datatype = ''; %#ok<NASGU>
participant = ''; %#ok<NASGU>
group = ''; %#ok<NASGU>
condition = ''; %#ok<NASGU>
session = ''; %#ok<NASGU>

channel = [];

filetype = 'acq';
savefolder = 0;
verbose = true;



% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case {'files','file','filename'},files = varargin{i+1};
        case 'folder',                  folder = varargin{i+1};
            
        case 'channel',                 channel = varargin{i+1};
        case 'namestr',                 namestr = varargin{i+1};
        
        case 'study',                   study = varargin{i+1}; %#ok<NASGU>
        case 'datatype',                datatype = varargin{i+1}; %#ok<NASGU>
        case 'participant',             participant = varargin{i+1}; %#ok<NASGU>
        case 'group',                   group = varargin{i+1}; %#ok<NASGU>
        case 'condition',               condition = varargin{i+1}; %#ok<NASGU>
        case 'session',                 session = varargin{i+1}; %#ok<NASGU>

        case 'filetype',                filetype = varargin{i+1};
        case {'save'},                  savefolder = varargin{i+1};
        case 'verbose',                 verbose = varargin{i+1};
    end
end

% get data file names
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

% check things before starting
if ~ischar(savefolder) && length(files) > 1
    error('When creating more than one PHZ file, specify a folder where they should be saved.'), end

% loop files
% if verbose, disp(' '), disp('Creating PHZ file(s) from data file(s)...'), end
w = '';
for i = 1:length(files)
    fileProgress = [num2str(i),'/',num2str(length(files)),': ',files{i}];
    if length(files) > 1, w = phzUtil_progressbar(w,i/length(files),fileProgress); end
    
    % load data
    if verbose, disp(['Loading data from file ',fileProgress]), end
    PHZ = getBlankPHZ(verbose); % get new blank PHZ structure
    PHZ.proc.create.datafile = fullfile(folder,files{i});
    raw = load(PHZ.proc.create.datafile,'-mat');
    
    % get grouping vars from filename or parameter/value pairs
    PHZ = readFilename(PHZ,namestr);
    for j = {'study','datatype','participant','group','condition','session'}; field = j{1};
        if ~isempty(eval(field)), PHZ.(field) = eval(field); end
    end
    
    % get data
    switch lower(filetype)
        case {'acq','biopac','acqknowledge'}
            
            if isempty(channel)
                disp('Which channel would you like to load?')
                disp('(Enter 0 to abort.)')
                for j = 1:size(raw.labels,1), disp([num2str(j),'. ',raw.labels(j,:)]), end
                while isempty(channel) || ~ismember(channel,0:size(raw.labels,1))
                    channel = input('Enter the channel number: '); commandwindow
                end
                if channel == 0, disp('Aborting...'), return, end
            end
            
            if ischar(channel), channel = find(strcmp(cellstr(raw.labels),channel)); end
            
            PHZ.datatype = deblank(raw.labels(channel,:));
            PHZ.units = deblank(raw.units(channel,:));
            
            switch raw.isi_units
                case 'ms', PHZ.srate = 1 / (raw.isi / 1000);
                case 's',  PHZ.srate = 1 / raw.isi;
            end
            
            PHZ.data = transpose(raw.data(:,channel));
            PHZ.times = (raw.start_sample:1:length(PHZ.data)-1) / PHZ.srate;
            
        otherwise, error('Unknown file type.')
    end
    
    if ~isempty(datatype), PHZ.datatype = datatype; end
    
    % save PHZ file
    if ischar(savefolder)
        [pathstr,name] = fileparts(PHZ.meta.datafile);
        if isempty(savefolder), savefolder = pathstr; end
        PHZ = phz_save(PHZ,fullfile(savefolder,[name,'.phz']));
    else PHZ = phz_check(PHZ,verbose);
    end
     
end
end

function PHZ = readFilename(PHZ,namestr)
if isempty(namestr), return, end

% find out which grpvars are in namestr & their order & their start/ends
vars = {'study','datatype','participant','group','condition','session'};
varsbeg = sort(cell2mat(regexp(namestr,vars,'start')));
varsend = sort(cell2mat(regexp(namestr,vars,'end')));
grpvars = cell(size(varsbeg));
for i = 1:length(grpvars), grpvars{i} = namestr(varsbeg(i):varsend(i)); end

% use start/ends to get delimstr that occur before & after each grpvar
% i.e., length(delimstr) = length(grpvars) + 1
delimstr = cell(1,length(grpvars) + 1);
for i = 1:length(delimstr)
    switch i
        
        case 1
            if varsbeg(i) == 1
                delimstr{i} = '';
            else
                delimstr{i} = namestr(1:varsbeg(i) - 1);
            end
            
        case length(delimstr)
            if varsend(i-1) == length(grpvars)
                delimstr{i} = ''; 
            else
                delimstr{i} = namestr(varsend(i-1) + 1:end);
            end
            
        otherwise
            delimstr{i} = namestr(varsend(i-1) + 1:varsbeg(i) - 1);
    end
end

if any(cellfun(@isempty,delimstr(2:end-1)))
    error('There must be some delimiter between grouping variables in the filename.'), end

[~,name,~] = fileparts(PHZ.proc.create.datafile);

% move cursor past leading delimiter
if isempty(delimstr{1}), cursor = 1;
elseif strcmp(delimstr{1},name(1:length(delimstr{1})))
    cursor = 1 + length(delimstr{1});
else error(['Filename ''',name,''' doesn''t match the namestr.'])
end
delimstr(1) = []; % delimstr now holds delims that follow each grpvar

% loop through grpvars and get their vals from the filename
for i = 1:length(grpvars)
    
    if i == length(grpvars) && isempty(delimstr{i})
        PHZ.(grpvars{i}) = name(cursor:end);
        
    else
        strend = min(strfind(name(cursor:end),delimstr{i}));
        PHZ.(grpvars{i}) = name(cursor:cursor + strend - 2);
        cursor = cursor + strend + length(delimstr{i}) - 1;
    end
end

PHZ.proc.create.namestr = namestr;
end

function PHZ = getBlankPHZ(verbose)

PHZ.study = '';
PHZ.datatype = '';

PHZ.participant = categorical;
PHZ.group = categorical;
PHZ.condition = categorical;
PHZ.session = categorical;
PHZ.trials = categorical;

PHZ.region.baseline = [];
PHZ.region.target = [];
PHZ.region.target2 = [];
PHZ.region.target3 = [];
PHZ.region.target4 = [];

PHZ.data = [];
PHZ.units = '';

PHZ.resp.q1 = {};
PHZ.resp.q1_acc = [];
PHZ.resp.q1_rt = [];
PHZ.resp.q2 = {};
PHZ.resp.q2_acc = [];
PHZ.resp.q2_rt = [];
PHZ.resp.q3 = {};
PHZ.resp.q3_acc = [];
PHZ.resp.q3_rt = [];
PHZ.resp.q4 = {};
PHZ.resp.q4_acc = [];
PHZ.resp.q4_rt = [];
PHZ.resp.q5 = {};
PHZ.resp.q5_acc = [];
PHZ.resp.q5_rt = [];

PHZ.proc = struct;

PHZ.srate = [];
PHZ.times = [];

PHZ.meta.tags.participant = categorical;
PHZ.meta.tags.group = categorical;
PHZ.meta.tags.condition = categorical;
PHZ.meta.tags.session = categorical;
PHZ.meta.tags.trials = categorical;
PHZ.meta.tags.region = {'baseline','target','target2','target3','target4'};

PHZ.meta.spec.participant = {};
PHZ.meta.spec.group = {};
PHZ.meta.spec.condition = {};
PHZ.meta.spec.session = {};
PHZ.meta.spec.trials = {};
PHZ.meta.spec.region = {'k','b','g','y','r'};

PHZ.misc = struct;
PHZ.history = {};

PHZ = phz_history(PHZ,'PHZ structure created.',verbose);

end