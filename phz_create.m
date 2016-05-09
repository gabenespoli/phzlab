function PHZ = phz_create(filetype,files,varargin)
%PHZ_CREATE  Create a new PHZ structure.
% 
% USAGE
%     PHZ = phz_create
%     PHZ = phz_create(filetype)
%     PHZ = phz_create(filetype,files)
%     PHZ = phz_create(filetype,folder)
%     PHZ = phz_create(filetype,...,'Param1','Value1',etc.)
% 
% INPUT   
%     PHZ         = PHZLAB data structure.
% 
%     filetype    = The type of file to import. Options are 'acq'
% 
%     files       = String or cell array of strings specifying the file(s) 
%                   to import. If left empty, a dialog box pops up for you 
%                   to select a file or files.
% 
%     folder      = A folder of files from which to create PHZ files.
%                   Specify a save folder to save each one.
% 
%     'channel'   = If the data file contains multiple channels, you must
%                   specify which channel to extract. CHANNEL can be a 
%                   number or a string. If it is a string, there must be a 
%                   labels (or similar) variable in the data file indexing 
%                   the channels in the data variable.
% 
%     'delimiter' = Specifies the delimiter in the filename for separating
%                   'participant, 'group', and 'session' information
% 
%  X  'namestr'   = Specifies the file naming convention. NAMESTR must
%                   contain at least one of 'participant', 'group', and 
%                   'session', and each must be separated by a delimiter. 
%                   Other options are 'study' and 'datatype'. The default 
%                   NAMESTR is 'participant-group-session'.
% 
%     'study'     = Fills the 'study' field of the PHZ structure.
% 
%     'datatype'  = Fills the 'datatype' field of the PHZ structure.
% 
%     'savefolder'= The folder where the new PHZ file should be saved.
%                   SAVEFOLDER must be specified if multiple PHZ files are 
%                   being created. Specify the empty string ('') to use the
%                   same folder as where the data files are saved. Default 
%                   is not to save the new PHZ structure. Files are saved 
%                   using the phz_save function, the file will have the 
%                   '.phz' extension, and should be loaded using the 
%                   phz_load function.
% 
%   X  = This functionality isn't working yet.
% 
% OUTPUT  
%     PHZ structure with the following fields.
% 
%     study           = 'string'
%     datatype        = 'string', type of data in PHZ.data.
%     participant     = 'string' or [numeric].
%     group           = (same as participant)
%     session         = (same as participant)
%     trials          = 'string', {'1D cell array of strings'}, 
%                       or [numeric]. Must be same length as size(data,1).
%     times           = [numeric], vector of times for each sample
%                       (in s). Must be same length as size(data,2).
%     data            = [numeric], 2D array TRIALS-by-TIME.
%     units           = 'string', units of data in PHZ.data.
%     srate           = [numeric], sampling frequency.
%     region.region   = [numeric], endpoints of region (in s). 
%                       Default available regions are 'baseline', 'target',
%                       'target2', 'target3', and 'target4'.
%     resp.q1         = {'1D cell array of strings'}, behavioural 
%                       responses to each trial. Also available are 
%                       q2, q3, q4, and q5.
%     resp.q1_acc     = [numeric], column of accuracy values.
%     resp.q1_rt      = [numeric], column of reaction times.
%     spec.*          = {'1D cell array of strings'} specifies the lineSpec
%                       property (incl. colour) for plotting. Must be the 
%                       same length as the corresponding grouping variable 
%                       (i.e., participant, group, session, or trials. See
%                       the help for the plot.m function for more details
%                       on line types.
%     tags.*          = Grouping-variable tags for each trial.
%
% Written by Gabe Nespoli 2016-01-27. Revised 2016-04-01.

if nargout == 0 && nargin == 0, help phz_create, return
elseif nargout == 0 && nargin > 0, error('Assign an output argument.')
end
if nargin == 0 || isempty(filetype), PHZ = getBlankPHZ(1); return, end

% defaults
study = '';
% participant = '';
% group = '';
% session = '';

channel = 1;
delimiter = '-';

% filetype = 'acq';
savefolder = 0;
verbose = true;

folder = '';

% get data file names
if isdir(files) % load all files from folder
    folder = files;
    files = what(folder);
    files = files.mat;
    
% elseif ischar(files) && strcmp(files,'blank')
%     PHZ = getBlankPHZ(verbose);
%     return
    
elseif ischar(files) && exist(files,'file') % load file from filename
    files = {files};
    
elseif isempty(files) % prompt to select file(s)
    [files,folder] = uigetfile('.mat','Select data file(s)...','MultiSelect','on');
    if isnumeric(files) && files == 0, return, end
    if ischar(files), files = {files}; end
    
elseif ~iscell(files)  % (load many files from cell array of filenames)
    error('Problem with FILES input.')
    
end

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'study',                   study = varargin{i+1};
%         case 'participant',             participant = varargin{i+1};
%         case 'group',                   group = varargin{i+1};
%         case 'session',                 session = varargin{i+1};

        case 'channel',                 channel = varargin{i+1};
        case 'delimiter',               delimiter = varargin{i+1};
        
%         case 'filetype',                filetype = varargin{i+1};
        case {'save','filename'},       savefolder = varargin{i+1};
        case 'verbose',                 verbose = varargin{i+1};
    end
end

% check things before starting
if ~ischar(savefolder) && length(files) > 1
    error('When creating more than one PHZ file, specify a folder where they should be saved.')
end

% loop files
if verbose, disp(' '), disp('Creating PHZ file(s) from data file(s)...'), end
w = waitbar(0,'Creating PHZ file(s) from data file(s)...');
for i = 1:length(files)
    fileProgress = [num2str(i),'/',num2str(length(files)),': ',files{i}];
    waitbar((i-1)/length(files),w,['Creating PHZ file from data file ',fileProgress]);
    
    % load data
    if verbose, disp(['Loading data from file ',fileProgress]), end
    PHZ = getBlankPHZ(verbose); % get new blank PHZ structure
    PHZ.study = study;
    PHZ.meta.datafile = fullfile(folder,files{i});
    s = load(PHZ.meta.datafile,'-mat');
    
    % get grouping vars from filename ('participant-group-session.mat')
    [~,name] = fileparts(files{i});
    name = regexp(name,delimiter,'split');
    PHZ.participant = name{1};
    if length(name) > 1, PHZ.group = name{2}; end
    if length(name) > 2, PHZ.session = name{3}; end
    
    % get data
    switch lower(filetype)
        case {'acq','biopac','acqknowledge'}
            if ischar(channel), channel = find(strcmp(cellstr(s.labels),channel)); end
            if isempty(channel), error('Specify a valid channel.'), end
            PHZ.datatype = deblank(s.labels(channel,:));
            
            PHZ.units = deblank(s.units(channel,:));
            switch s.isi_units
                case 'ms', PHZ.srate = s.isi * 1000;
                case 's',  PHZ.srate = s.isi;
            end
            
            PHZ.data = transpose(s.data(:,channel));
            PHZ.meta.times = (s.start_sample:1:length(PHZ.data)) / PHZ.srate;
            
        otherwise, error('Unknown file type.')
    end
    
    % save PHZ file
    if ischar(savefolder)
        [pathstr,name] = fileparts(PHZ.meta.datafile);
        if isempty(savefolder), savefolder = pathstr; end
        PHZ = phz_save(PHZ,fullfile(savefolder,[name,'.phz']));
    else PHZ = phz_check(PHZ);
    end
     
end
close(w)

end

function PHZ = getBlankPHZ(verbose)

PHZ.study = '';
PHZ.datatype = ''; % i.e. 'scl', 'zyg', 'ffr', etc.

PHZ.participant = '';
PHZ.group = ''; % aka between-subjects variable
PHZ.session = ''; % aka within-subjects variable
PHZ.trials = ''; % trialtype label for each trial (i.e., trial order)

PHZ.region.baseline = []; % baseline region if data are baseline-corrected
PHZ.region.target = [];
PHZ.region.target2 = [];
PHZ.region.target3 = [];
PHZ.region.target4 = [];

PHZ.data = []; % actual data, 2D, trials X time
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

PHZ.meta.srate = []; % sampling frequency in Hz
PHZ.meta.times = []; % in seconds

PHZ.meta.tags.participant = categorical;
PHZ.meta.tags.group = categorical;
PHZ.meta.tags.session = categorical;
PHZ.meta.tags.trials = categorical;
PHZ.meta.tags.region = {'baseline','target','target2','target3','target4'};

PHZ.meta.spec.participant = {};
PHZ.meta.spec.group = {};
PHZ.meta.spec.session = {};
PHZ.meta.spec.trials = {};
PHZ.meta.spec.region = {'k','b','g','y','r'};

PHZ.misc = struct;

PHZ.history = {};

% add creation date to FFR.history
PHZ = phzUtil_history(PHZ,'PHZ structure created.',verbose);

end