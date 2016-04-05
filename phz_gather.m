function PHZS = phz_gather(varargin)
%PHZ_GATHER  Create a PHZS structure of data from many PHZ structures.
% 
% usage:    PHZ = phz_gather
%           PHZ = phz_gather(FOLDER)
%           PHZ = phz_gather(...,'Param1','Value1',etc.)
% 
% inputs:   (none)  = Opens a file browser to select files to gather.
%           FOLDER  = Gather all .phz files in this folder.
%           'save'  = Filename and path to save resultant PHZ structure
%                     as a .phz file.
%           
%           The following functions can be called as parameter/value pairs,
%           and are executed in the same order as they appear in the
%           function call. See the help of each function for more details.
%               'subset'    = Calls phz_subset.
%               'rectify'   = Calls phz_rect.
%               'filter'    = Calls phz_filter.
%               'smooth'    = Calls phz_smooth.
%               'transform' = Calls phz_transform.
%               'blc'       = Calls phz_blc.
%               'rej'       = Calls phz_rej.
%               'norm'      = Calls phz_norm.
% 
%           The following functions can be called as parameter/value pairs,
%           and are always executed in the order listed here, after all of
%           the processing funtions. See the help of each function for more
%           details.
%               'region'    = Calls phz_region.
%               'summary'   = Calls phz_summary.
% 
% outputs:  PHZ = Gathered PHZLAB data structure. More-or-less a
%                 concatnated version of all input PHZ structures.
% 
% examples:
%   PHZ = phz_gather >> Opens a file browser to select multiple files.
%   PHZ = phz_gather('myfolder') >> Gathers all .phz files in myfolder.
%
% Written by Gabriel A. Nespoli 2016-02-21. Revised 2016-04-04.
if nargout == 0 && nargin == 0, help phz_gather, return, end

% defaults
region = [];
keepVars = {'all'};
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

processing = {};
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case {'subset','filter','filt','rect','rectify','smooth','smoothing',...
                'transform','blc','baselinecorrect','rej','reject','norm','normtype'}
            processing = [processing varargin(i:i+1)];
        case 'region',                  region = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
        case {'save','filename'},       filename = addToCell(filename,varargin{i+1});
        case 'verbose',                 verbose = varargin{i+1};
    end
end

resetFields = {};

% loop through files
if verbose, disp(' '), disp('Gathering PHZ data...'), end
w = waitbar(0,'Gathering PHZ data...');
for j = 1:length(files)
    fileProgress = [num2str(j),'/',num2str(length(files)),': ',files{j}];
    waitbar((j-1)/length(files),w,['Gathering PHZ data from file ',fileProgress]);
    
    % load data
    if verbose, disp(['Loading data from file ',fileProgress]), end
    
    PHZS.files{j} = fullfile(folder,files{j});
    PHZ = phz_load(PHZS.files{j},verbose); % runs phz_check.m
    
    % do user-defined preprocessing
    for i = 1:2:length(processing)
        switch lower(processing{i})
            case 'subset',                  PHZ = phz_subset(PHZ,varargin{i+1},verbose);
            case {'rect','rectify'},        PHZ = phz_rect(PHZ,varargin{i+1},verbose);
            case {'filter','filt'},         PHZ = phz_filter(PHZ,varargin{i+1},verbose);
            case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,varargin{i+1},verbose);
            case 'transform',               PHZ = phz_transform(PHZ,varargin{i+1},verbose);
            case {'blc','baselinecorrect'}, PHZ = phz_blc(PHZ,varargin{i+1},verbose);
            case {'rej','reject'},          PHZ = phz_rej(PHZ,varargin{i+1},verbose);
            case {'norm','normtype'},       PHZ = phz_norm(PHZ,varargin{i+1},verbose);
        end
    end
    
    PHZ = phz_region(PHZ,region,verbose);
    PHZ = phz_summary(PHZ,keepVars,verbose);
    
    % gather data
    % -----------
    if j == 1
        PHZS = PHZ;
        PHZS.history = {};
        PHZS = phzUtil_history(PHZS,'Gathered PHZ structure created.',verbose);
        PHZS = phzUtil_history(PHZS,['Preprocessing: ',strjoin(processing)],verbose);
        
        % (soon these will be tucked into PHZ.proc)
        if ismember('rej',fieldnames(PHZS)), PHZS = rmfield(PHZS,'rej'); end
        if ismember('blc',fieldnames(PHZS)), PHZS = rmfield(PHZS,'blc'); end
        if ismember('norm',fieldnames(PHZS)), PHZS = rmfield(PHZS,'norm'); end
        
        continue
    end
    
    % make sure data length is compatible
    if size(PHZS.data,2) ~= size(PHZ.data,2)
        PHZS = phzUtil_history(PHZS,['NOTE: The length of the data in ''',files{j},''' was different, so it was not included.'],verbose);
        continue
    end
    
    % make sure sampling frequency is compatible
    if PHZ.srate ~= PHZS.srate
        PHZS = phzUtil_history(PHZS,['NOTE: The ''srate'' field of ''',files{j},''' is different (',num2str(PHZ.(field)),'), so it was not included.'],verbose);
        continue
    end
    
    % basic fields (strings)
    for i = {'study','datatype','units'}
        field = i{1};
        if ~strcmp(PHZ.(field),PHZS.(field))
            PHZS = phzUtil_history(PHZS,['NOTE: The ''',field,''' field of ''',files{j},''' is different: ''',PHZ.(field),'''.'],verbose,0);
        end
    end

    
    % grouping variables & tags
    % if different, reset to include unique values of tags after looping
    for i = {'participant','group','session','trials'}, field = i{1};
        
        if ~all(ismember(cellstr(PHZ.(field)),cellstr(PHZS.(field))))
            if ~ismember(field,resetFields), resetFields{end+1} = field; end
        end
        
        PHZ.tags.(field) = categorical(PHZ.tags.(field),'Ordinal',false);
        PHZS.tags.(field) = categorical(PHZS.tags.(field),'Ordinal',false);
        PHZS.tags.(field) = [PHZS.tags.(field); PHZ.tags.(field)];
    end
    
    % data
    PHZS.data = [PHZS.data; PHZ.data];
    if numel(PHZS.data) > 50000000 % check if filesize is getting too big
        close(w)
        error(['Too much data to gather into one variable. Consider ',...
            'doing some preprocessing and averging with phz_gather.'])
    end
    
    % behavioural response data
    for i = 1:5
        qx = ['q',num2str(i)];
        PHZS.resp.(qx) = [PHZS.resp.(qx); PHZ.resp.(qx)];
        PHZS.resp.([qx,'_acc']) = [PHZS.resp.([qx,'_acc']); PHZ.resp.([qx,'_acc'])];
        PHZS.resp.([qx,'_rt']) = [PHZS.resp.([qx,'_rt']); PHZ.resp.([qx,'_rt'])];
    end

    PHZS = verifyFieldsThatShouldBeTheSame(PHZS,PHZ,j);
    
    % concatenate summary info if applicable
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
for j = 1:length(resetFields), field = resetFields{j};
    PHZS.(field) = unique(PHZS.tags.(field));
    PHZS = phzUtil_history(PHZS,['The ',field,' field was reset to include the unique values of tags.',field,'.'],verbose,0);
end

if ~ismember(keepVars,{'all'})
    PHZS.summary.type = keepVars;
end


% add preprocessing to PHZ.history
% if ~isempty(rect), PHZS = phzUtil_history(PHZS,['Pre-gathering rectification: ',rect,'.']); end
% if ~isempty(blc),     if isnumeric(blc), blc = num2str(blc); end, PHZS = phzUtil_history(PHZS,['Pre-gathering baseline correction: ',blc,'.']); end
% if ~isempty(rej),     PHZS = phzUtil_history(PHZS,['Pre-gathering rejection threshold: ',num2str(rej),' ',PHZS.units,'.']); end
% if ~ismember(keepVars,{'all'}), PHZS = phzUtil_history(PHZS,['Pre-gathering summary: ',strjoin(keepVars),'.']); end

% save to file (& phz_check)
if ~isempty(filename)
    phz_save(PHZS,filename)
else PHZS = phz_check(PHZS);
end

end

% function x = collapseIfOneValue(x)
% if length(unique(x)) == 1
%     x = unique(x);
%     if iscell(x), x = x{1}; end
% else warning(['Folder contains files with differing values for ',inputname,'.'])
% end
% end

function PHZS = verifyFieldsThatShouldBeTheSame(PHZS,PHZ,i)
if i == 1
    
    if ismember('times',fieldnames(PHZ)),     PHZS.times = PHZ.times;
    elseif ismember('freqs',fieldnames(PHZ)), PHZS.freqs = PHZ.freqs;
    end
    
    rname = fieldnames(PHZ.regions);
    for j = 1:length(rname)
        PHZS.region.(rname{j}) = PHZ.regions.(rname{j});
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
            error(['FFR.region.',(rname{j}),' is inconsistent.'])
        end
    end
end
end

% function PHZS = verifySpec(PHZS,PHZ,spec)
% 
% if ~isempty(spec.participant_order),  PHZS.spec.participant_order  = spec.participant_order;
% else                                  PHZS.spec.participant_order  = PHZ.spec.participant_order;
% end
% if ~isempty(spec.participant_spec),   PHZS.spec.participant_spec   = spec.participant_spec;
% else                                  PHZS.spec.participant_spec   = PHZ.spec.participant_spec;
% end
% 
% if ~isempty(spec.group_order),   PHZS.spec.group_order   = spec.group_order;
% else                             PHZS.spec.group_order   = PHZ.spec.group_order;
% end
% if ~isempty(spec.group_spec),    PHZS.spec.group_spec    = spec.group_spec;
% else                             PHZS.spec.group_spec    = PHZ.spec.group_spec;
% end
% 
% if ~isempty(spec.session_order), PHZS.spec.session_order = spec.session_order;
% else                             PHZS.spec.session_order = PHZ.spec.session_order;
% end
% if ~isempty(spec.session_spec),  PHZS.spec.session_spec  = spec.session_spec;
% else                             PHZS.spec.session_spec  = PHZ.spec.session_spec;
% end
% 
% if ~isempty(spec.trials_order),  PHZS.spec.trials_order  = spec.trials_order;
% else                             PHZS.spec.trials_order  = PHZ.spec.trials_order;
% end
% if ~isempty(spec.trials_spec),   PHZS.spec.trials_spec   = spec.trials_spec;
% else                             PHZS.spec.trials_spec   = PHZ.spec.trials_spec;
% end
% 
% if ~isempty(spec.region_order),  PHZS.spec.region_order  = spec.region_order;
% else                             PHZS.spec.region_order  = PHZ.spec.region_order;
% end
% if ~isempty(spec.region_spec),   PHZS.spec.region_spec   = spec.region_spec;
% else                             PHZS.spec.region_spec   = PHZ.spec.region_spec;
% end
% 
% end

function C = addToCell(C,a)
if ischar(a), a = {a}; end
C = [C a];
end