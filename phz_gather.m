function PHZS = phz_gather(varargin)
%PHZ_GATHER  Create a PHZS structure of data from many PHZ structures.
% 
% PHZS = PHZ_GATHER opens a file browser to select PHZ structures to
%   concatenate into a single PHZS structure. Files must be .mat.
% 
% PHZS = PHZ_GATHER(FOLDER) uses all of the .mat files in FOLDER.
%
% PHZS = PHZ_GATHER('Param1','Value1',...) additionally specifies one of
%   the following parameters. Applying a summary processing function will
%   make the filesize of PHZS smaller; this will render some trial
%   information inaccessible, but in some cases is required.
%
%   Processing options: These parameter names will call the function with
%     the same name, using the specified value as input. See the help of
%     each function for a more detailed explanation of what they do and
%     how to use them.
%   'subset'     = Only gather a subset of the data in PHZ.
%   'rect'       = Full- or half-wave rectification of PHZ.data.
%   'blc'        = Subtract the mean of a baseline region from PHZ.data.
%   'rej'        = Reject trials with values above a threshold.
%   'region'     = Restrict feature extraction or plotting to a region.
%   'feature'    = Gather a feature (e.g., mean, max, fft, etc.).
%   'summary'    = Summarize data by grouping variables (e.g., group,
%                  etc.). Default is 'all' (don't do any averaging).
%
%   Plotting options:
%   spec.*_order = Specify order of a grouping variable. Replace '*' with
%                  'participant', 'group', 'session', 'trials', and
%                  'region'.
%   spec.*_spec  = Specify the colour and line type specfications for
%                  plotting. Must be the same length as spec.*_order. See
%                  the help for the plot.m function for more detail on
%                  line types.
%
%   Saving options:
%   'save'       = Filename to save the PHZS structure as a .mat file after
%                  gathering.
%
% Written by Gabriel A. Nespoli 2016-02-21. Revised 2016-03-22.

if nargout == 0 && nargin == 0, help phz_gather, return, end

% defaults
subset = {};
rect = '';
blc = [];
rej = [];
region = '';
keepVars = {'all'};

spec.participant_spec = {};
spec.participant_order = {};
spec.group_spec = {};
spec.group_order = {};
spec.session_spec = {};
spec.session_order = {};
spec.trials_spec = {};
spec.trials_order = {};
spec.region_spec = {};
spec.region_order = {};

filename = {};

verbose = false;

% user-defined
if nargin > 0 && isdir(varargin{1})
    folder = varargin{1};
    files = what(folder);
    files = files.mat;
    varargin(1) = [];
    
else [files,folder] = uigetfile('.mat','Select PHZ files to gather...','MultiSelect','on');
    if isnumeric(files) && files == 0, return, end
    
end

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'subset',                  subset = varargin{i+1};
        case {'rect','rectify'},        rect = varargin{i+1};
        case {'blc','baselinecorrect'}, blc = varargin{i+1};
        case {'rej','reject'},          rej = varargin{i+1};
        case 'region',                  region = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
            
        case {'participantorder'},      spec.participant_order = varargin{i+1};
        case {'particiapntspec'},       spec.participant_spec = varargin{i+1};
        case {'grouporder'},            spec.group_order = varargin{i+1};
        case {'groupspec'},             spec.group_spec = varargin{i+1};
        case {'sessionorder'},          spec.session_order = varargin{i+1};
        case {'sessionspec'},           spec.session_spec = varargin{i+1};
        case {'trialsorder'},           spec.trials_order = varargin{i+1};
        case {'trialsspec'},            spec.trials_spec = varargin{i+1};
        case {'regionorder'},           spec.region_order = varargin{i+1};
        case {'regionspec'},            spec.region_spec = varargin{i+1};
            
        case {'save','filename'},       filename = addToCell(filename,varargin{i+1});
            
        case 'verbose',                 verbose = varargin{i+1};
    end
end

keepVars = phzUtil_verifySummaryType(keepVars);
PHZS = getBlankPHZS(length(files));

% loop through files
if verbose, disp(' '), disp('Gathering PHZ data...'), end
w = waitbar(0,'Gathering PHZ data...');
for i = 1:length(files)
    fileProgress = [num2str(i),'/',num2str(length(files)),': ',files{i}];
    waitbar((i-1)/length(files),w,['Gathering PHZ data from file ',fileProgress]);
    
    % load data
    if verbose, disp(['Loading data from file ',fileProgress]), end
    
    PHZS.files{i} = fullfile(folder,files{i});
    PHZ = phz_load(PHZS.files{i},verbose); % runs phz_check.m
    
    % do user-defined preprocessing
    PHZ = phz_subset(PHZ,subset);
    PHZ = phz_rect(PHZ,rect,verbose);
    PHZ = phz_blc(PHZ,blc,verbose);
    PHZ = phz_rej(PHZ,rej,verbose);
    PHZ = phz_region(PHZ,region,verbose);
    PHZ = phz_summary(PHZ,keepVars,'verbose',verbose);
    
    % gather data
    % -----------
    % fields with one value per participant
    if ~isempty(PHZ.study),      PHZS.study{i}       = PHZ.study;       end
    if ~isempty(PHZ.datatype),   PHZS.datatype{i}    = PHZ.datatype;    end
    if ~isempty(PHZ.units),      PHZS.units{i}       = PHZ.units;       end
    if ~isempty(PHZ.srate),      PHZS.srate(i)       = PHZ.srate;       end
    
    % fields with one value per participant; change to one value per trial
    PHZS.participant = [PHZS.participant; repmat(categorical(cellstr(PHZ.participant)),size(PHZ.data,1),1)];
    PHZS.group       = [PHZS.group;       repmat(categorical(cellstr(PHZ.group)),size(PHZ.data,1),1)];
    PHZS.session     = [PHZS.session;     repmat(categorical(cellstr(PHZ.session)),size(PHZ.data,1),1)];
    
    % fields with one value per trial
    PHZS.data        = [PHZS.data;        PHZ.data];
    if numel(PHZS.data) > 40000000
        close(w)
        error(['Too much data to gather into one variable. Consider ',...
            'doing some preprocessing and averging with phz_gather.'])
    end
    if isordinal(PHZ.trials), PHZ.trials = categorical(PHZ.trials,'Ordinal',false); end
    PHZS.trials      = [PHZS.trials;      PHZ.trials];
    
    % behavioural response data
    for j = 1:5
        qx = ['q',num2str(j)];
        PHZS.resp.(qx) = [PHZS.resp.(qx); PHZ.resp.(qx)];
        PHZS.resp.([qx,'_acc']) = [PHZS.resp.([qx,'_acc']); PHZ.resp.([qx,'_acc'])];
        PHZS.resp.([qx,'_rt']) = [PHZS.resp.([qx,'_rt']); PHZ.resp.([qx,'_rt'])];
    end
    
    
    
    PHZS = verifyFieldsThatShouldBeTheSame(PHZS,PHZ,i);
    
    % summary info
    if ~ismember(keepVars,{'all'})
        PHZS.summary.stdError     = [PHZS.summary.stdError;     PHZ.summary.stdError];
        PHZS.summary.nTrials      = [PHZS.summary.nTrials;      PHZ.summary.nTrials];
        PHZS.summary.nParticipant = [PHZS.summary.nParticipant; PHZ.summary.nParticipant];
    end
    
    if verbose, disp(' '), end
end % end looping participants
close(w)

% cleanup PHZS
% ------------
PHZS = verifySpec(PHZS,PHZ,spec);

% collapse fields fields if only one value
PHZS.study = collapseIfOneValue(PHZS.study);
PHZS.datatype = collapseIfOneValue(PHZS.datatype);
PHZS.units = collapseIfOneValue(PHZS.units);
PHZS.srate = collapseIfOneValue(PHZS.srate);

if ~ismember(keepVars,{'all'})
    PHZS.summary.type = keepVars;
end

% add creation date to PHZ.history (& phz_check)
PHZS = phzUtil_history(PHZS,'PHZS structure created.',verbose);

% add preprocessing to PHZ.history
if ~isempty(rect), PHZS = phzUtil_history(PHZS,['Pre-gathering rectification: ',rect,'.']); end
if ~isempty(blc),     if isnumeric(blc), blc = num2str(blc); end, PHZS = phzUtil_history(PHZS,['Pre-gathering baseline correction: ',blc,'.']); end
if ~isempty(rej),     PHZS = phzUtil_history(PHZS,['Pre-gathering rejection threshold: ',num2str(rej),' ',PHZS.units,'.']); end
if ~ismember(keepVars,{'all'}), PHZS = phzUtil_history(PHZS,['Pre-gathering summary: ',strjoin(keepVars),'.']); end

% save to file (& phz_check)
if ~isempty(filename), phz_save(PHZS,filename), end

end

function x = collapseIfOneValue(x)
if length(unique(x)) == 1
    x = unique(x);
    if iscell(x), x = x{1}; end
else warning(['Folder contains files with differing values for ',inputname,'.'])
end
end

function PHZS = verifyFieldsThatShouldBeTheSame(PHZS,PHZ,i)
if i == 1
    
    if ismember('times',fieldnames(PHZ)),     PHZS.times = PHZ.times;
    elseif ismember('freqs',fieldnames(PHZ)), PHZS.freqs = PHZ.freqs;
    end
    
    rname = fieldnames(PHZ.region);
    for j = 1:length(rname)
        PHZS.region.(rname{j}) = PHZ.region.(rname{j});
    end
    
    if ismember('summary',fieldnames(PHZ))
        PHZS.summary = PHZ.summary;
    end
    
else
    if ismember('times',fieldnames(PHZS)),
        if ~all(PHZS.times == PHZ.times)
            error('PHZ.times is inconsistent.')
        end
    elseif ismember('freqs',fieldnames(PHZS)), PHZS.freqs = PHZ.freqs;
        if ~all(PHZS.freqs == PHZ.freqs)
            error('PHZ.freqs is inconsistent.')
        end
    end
    
    rname = fieldnames(PHZS.region);
    for j = 1:length(rname)
        if ~all(PHZS.region.(rname{j}) == PHZ.region.(rname{j})),
            error(['FFR.roi.',(rname{j}),' is inconsistent.'])
        end
    end
end
end

function PHZS = verifySpec(PHZS,PHZ,spec)

if ~isempty(spec.participant_order),  PHZS.spec.participant_order  = spec.participant_order;
else                                  PHZS.spec.participant_order  = PHZ.spec.participant_order;
end
if ~isempty(spec.participant_spec),   PHZS.spec.participant_spec   = spec.participant_spec;
else                                  PHZS.spec.participant_spec   = PHZ.spec.participant_spec;
end

if ~isempty(spec.group_order),   PHZS.spec.group_order   = spec.group_order;
else                             PHZS.spec.group_order   = PHZ.spec.group_order;
end
if ~isempty(spec.group_spec),    PHZS.spec.group_spec    = spec.group_spec;
else                             PHZS.spec.group_spec    = PHZ.spec.group_spec;
end

if ~isempty(spec.session_order), PHZS.spec.session_order = spec.session_order;
else                             PHZS.spec.session_order = PHZ.spec.session_order;
end
if ~isempty(spec.session_spec),  PHZS.spec.session_spec  = spec.session_spec;
else                             PHZS.spec.session_spec  = PHZ.spec.session_spec;
end

if ~isempty(spec.trials_order),  PHZS.spec.trials_order  = spec.trials_order;
else                             PHZS.spec.trials_order  = PHZ.spec.trials_order;
end
if ~isempty(spec.trials_spec),   PHZS.spec.trials_spec   = spec.trials_spec;
else                             PHZS.spec.trials_spec   = PHZ.spec.trials_spec;
end

if ~isempty(spec.region_order),  PHZS.spec.region_order  = spec.region_order;
else                             PHZS.spec.region_order  = PHZ.spec.region_order;
end
if ~isempty(spec.region_spec),   PHZS.spec.region_spec   = spec.region_spec;
else                             PHZS.spec.region_spec   = PHZ.spec.region_spec;
end

end

function PHZS = getBlankPHZS(n)

PHZS.study = cell(n,1);
PHZS.datatype = cell(n,1);

PHZS.participant = categorical;
PHZS.group = categorical;
PHZS.session = categorical;
PHZS.trials = categorical;
PHZS.times = [];
PHZS.data = [];

PHZS.units = cell(n,1);
PHZS.srate = nan(n,1);

PHZS.region.baseline = [];
PHZS.region.target = [];
PHZS.region.target2 = [];
PHZS.region.target3 = [];
PHZS.region.target4 = [];

PHZS.resp.q1 = {};
PHZS.resp.q1_acc = [];
PHZS.resp.q1_rt = [];
PHZS.resp.q2 = {};
PHZS.resp.q2_acc = [];
PHZS.resp.q2_rt = [];
PHZS.resp.q3 = {};
PHZS.resp.q3_acc = [];
PHZS.resp.q3_rt = [];
PHZS.resp.q4 = {};
PHZS.resp.q4_acc = [];
PHZS.resp.q4_rt = [];
PHZS.resp.q5 = {};
PHZS.resp.q5_acc = [];
PHZS.resp.q5_rt = [];

PHZS.spec.participant_order = {};
PHZS.spec.participant_spec = {};
PHZS.spec.group_order = {};
PHZS.spec.group_spec = {};
PHZS.spec.session_order = {};
PHZS.spec.session_spec = {};
PHZS.spec.trials_order = {};
PHZS.spec.trials_spec = {};
PHZS.spec.region_order = {'baseline','target','target2','target3','target4'};
PHZS.spec.region_spec = {'k','b','g','y','r'};

PHZS.files = {};
PHZS.misc = [];
PHZS.history = {};

end

function C = addToCell(C,a)
if ischar(a), a = {a}; end
C = [C a];
end