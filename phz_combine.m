%PHZ_COMBINE  Create a PHZS structure of data from many PHZ structures.
% 
% USAGE    
%   PHZ = phz_combine
%   PHZ = phz_combine(folder)
%   PHZ = phz_combine(...,'Param1',Value1,etc.)
% 
% INPUT   
%   (none) = Opens a file browser to select files to combine.
% 
%   folder = Combine all .phz files in this folder. Can also be a 
%            cell array of full or relative file paths.
% 
%   'save' = Filename and path to save PHZ structure as a '.phz' file.
%           
%   These are executed in the order that they appear in the function call. 
%   See the help of each function for more details.
%     'subset'    = Calls phz_subset.
%     'rectify'   = Calls phz_rect.
%     'filter'    = Calls phz_filter.
%     'smooth'    = Calls phz_smooth.
%     'transform' = Calls phz_transform.
%     'blsub'     = Calls phz_blsub.
%     'rej'       = Calls phz_rej.
%     'norm'      = Calls phz_norm.
% 
%   These are always executed in the order listed here, after the above
%   processing funtions. See the help of each function for more details.
%     'region'    = Calls phz_region.
%     'summary'   = Calls phz_summary. Note that this will summarize each
%                   file individually.
% 
% OUTPUT  
%   PHZ = Combined PHZLAB data structure. More-or-less a concatnated 
%         version of all input PHZ structures.
% 
% EXAMPLES
%   PHZ = phz_combine >> Opens a file browser to select multiple files.
%   PHZ = phz_combine('myfolder') >> Combines all .phz files in myfolder.

% Copyright (C) 2018 Gabriel A. Nespoli, gabenespoli@gmail.com
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

function PHZS = phz_combine(varargin)

if nargout == 0 && nargin == 0, help phz_combine, return, end

% defaults
region = [];
keepVars = [];
filename = {};
verbose = false;

% user-defined
if nargin > 0 
    if ischar(varargin{1}) && isdir(varargin{1})
        folder = varargin{1};
        files = dir(folder);
        files = {files.name};
        files = files(contains(files, {'.phz'}));
        files = files(~startsWith(files, '.')); % ignore dotfiles

    elseif iscell(varargin{1})
        folder = '';
        files = varargin{1};

    end
    varargin(1) = [];
    
else
    [files,folder] = uigetfile({ ...
        '*.phz', 'PHZ-files (*.phz)'}, ...
        'Select PHZ files to combine...', ...
        'MultiSelect', 'on');
    if isnumeric(files) && files == 0, return, end
    if ischar(files), files = cellstr(files); end
    
end

processing = {};
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case {'subset','filter','filt','rect','rectify','smooth','smoothing',...
                'transform','blsub','blc','rej','reject','norm','normtype'}
            processing = [processing varargin(i:i+1)]; %#ok<AGROW>
        case 'region',                  region = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
        case {'save','filename'},       filename = addToCell(filename, varargin{i+1});
        case 'verbose',                 verbose = varargin{i+1};
    end
end

resetFields = {};

% loop through files
% ------------------
for j = 1:length(files)
    fileProgress = [num2str(j), '/', num2str(length(files)), ...
        ': ''',files{j},''''];
    
    disp(['Combining PHZ data from file ', fileProgress])

    % load data
    if verbose, disp(['Loading data from file ', fileProgress]), end
    
    currentFile = fullfile(folder, files{j});
    PHZ = phz_load(currentFile, verbose); % runs phz_check.m
    
    % do user-defined preprocessing
    for i = 1:2:length(processing)
        switch lower(processing{i})
            case 'subset',                  PHZ = phz_subset(PHZ,   processing{i+1}, verbose);
            case {'rect','rectify'},        PHZ = phz_rect(PHZ,     processing{i+1}, verbose);
            case {'filter','filt'},         PHZ = phz_filter(PHZ,   processing{i+1}, 'verbose', verbose);
            case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,   processing{i+1}, verbose);
            case 'transform',               PHZ = phz_transform(PHZ,processing{i+1}, verbose);
            case 'blsub',                   PHZ = phz_blsub(PHZ,    processing{i+1}, verbose);
            case {'rej','reject'},          PHZ = phz_rej(PHZ,      processing{i+1}, verbose);
            case {'norm','normtype'},       PHZ = phz_norm(PHZ,     processing{i+1}, verbose);
        end
    end
    
    PHZ = phz_region(PHZ, region, verbose);
    PHZ = phz_summary(PHZ, keepVars, verbose);
    
    % combine data
    % -----------
    if j == 1
        PHZS = PHZ;
        
        % reset history field
        PHZS.history = {};
        PHZS = phz_history(PHZS,'Combined PHZ structure created.', verbose);
        PHZS = phz_history(PHZS,['Preprocessing: ', strnumjoin(processing)], verbose);
        PHZS.lib.files{j} = currentFile;
        if ismember('filename', fieldnames(PHZ.lib))
            PHZ.lib = rmfield(PHZ.lib, 'filename'); end
        
        PHZS.proc = [];
        PHZS.proc.pre{j} = PHZ.proc;

        continue
    end    
    
    % make sure data length is compatible
    if size(PHZS.data,2) ~= size(PHZ.data,2)
        PHZS = phz_history(PHZS, ['NOTE: The length of the data in ''', ...
            files{j}, ''' was different, so it was not included.'], verbose, 0);
        continue
    end
    
    % make sure sampling frequency is compatible
    if PHZ.srate ~= PHZS.srate
        PHZS = phz_history(PHZS, ['NOTE: The ''srate'' field of ''', ...
            files{j}, ''' is different (', num2str(PHZ.(field)), ...
            '), so it was not included.'], verbose, 0);
        continue
    end
    
    % proc field
    PHZS.proc.pre{j} = PHZ.proc;
    
    % basic fields (strings)
    PHZS.lib.files{j} = currentFile;
    for i = {'study','datatype','units'}, field = i{1};
        if ~strcmp(PHZ.(field),PHZS.(field))
            PHZS = phz_history(PHZS, ['NOTE: The ''',field,''' field of ''', ...
                files{j}, ''' is different: ''', PHZ.(field),'''.'], verbose, 0);
        end
    end

    % grouping variables & tags
    % if different, reset to include unique values of tags after looping
    for i = {'participant','group','condition','session','trials'}, field = i{1};
        if ~strcmp(PHZ.lib.tags.(field),'<collapsed>')
            
            if ~all(ismember(cellstr(PHZ.(field)),cellstr(PHZS.(field))))
                if ~ismember(field,resetFields), resetFields{end+1} = field; end %#ok<AGROW>
            end
            
            PHZ.lib.tags.(field) = categorical(cellstr(PHZ.lib.tags.(field)),'Ordinal',false);
            PHZS.lib.tags.(field) = categorical(cellstr(PHZS.lib.tags.(field)),'Ordinal',false);
            PHZS.lib.tags.(field) = [PHZS.lib.tags.(field); PHZ.lib.tags.(field)];
            
        end
    end
    
    % data
    PHZS.data = [PHZS.data; PHZ.data];
    if numel(PHZS.data) > 50000000 % check if filesize is getting too big
        error(['Too much data to combine into one variable. Consider ',...
            'doing some preprocessing and averaging with phz_combine.'])
    end
    
    % behavioural response data
    for i = 1:5
        qx = ['q',num2str(i)];
        PHZS.resp.(qx) = [PHZS.resp.(qx); PHZ.resp.(qx)];
        PHZS.resp.([qx,'_acc']) = [PHZS.resp.([qx,'_acc']); PHZ.resp.([qx,'_acc'])];
        PHZS.resp.([qx,'_rt']) = [PHZS.resp.([qx,'_rt']); PHZ.resp.([qx,'_rt'])];
    end

    PHZS = verifyFieldsThatShouldBeTheSame(PHZS,PHZ,j);
    
    if verbose, disp(' '), end
end % end looping participants

% cleanup PHZS
% ------------
for j = 1:length(resetFields), field = resetFields{j};
    PHZS.(field) = unique(PHZS.lib.tags.(field));
    PHZS = phz_history(PHZS,['The ',field, ...
        ' field was reset to include the unique values of tags.', ...
        field,'.'],verbose,0);
end

% save to file (& phz_check)
if ~isempty(filename)
    PHZS = phz_save(PHZS,filename);
else
    PHZS = phz_check(PHZS);
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
    
else
    if ismember('times',fieldnames(PHZS))
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
        if ~all(PHZS.region.(rname{j}) == PHZ.region.(rname{j}))
            error(['FFR.region.',(rname{j}),' is inconsistent.'])
        end
    end
end
end

function C = addToCell(C,a)
if ischar(a), a = {a}; end
C = [C a];
end

function s = strnumjoin(C)
if ~iscell(C), return, end
allStrings = {};
for i = 1:length(C)
    
    if ischar(C{i})
        temp = {['''', C{i}, '''']};
        
    elseif islogical(C{i})
        if C{i} == true
            temp = 'true';
        else
            temp = 'false';
        end
        
    elseif isnumeric(C{i})
        if length(C{i}) == 1
            temp = num2str(C{i});
            
        elseif isvector(C{i})
            temp = '[';
            for j = 1:length(C{i})
                temp = [temp, num2str(C{i}(j))]; %#ok<AGROW>
                if j == length(C{i})
                    temp = [temp, ']']; %#ok<AGROW>
                else
                    temp = [temp, ' ']; %#ok<AGROW>
                end
            end
            
        else
            warning('Cannot print matrix in history string.')
            temp = '<some matrix>';

        end
        
        temp = {temp};
                
    elseif iscell(C{i})
        temp = ['{', strnumjoin(C{i}), '}'];
        
    else
        error('Problem with strnumjoin function.')
        
    end
    
    allStrings = [allStrings temp]; %#ok<AGROW>
end
s = strjoin(allStrings, ', ');
end
