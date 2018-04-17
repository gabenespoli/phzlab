%PHZ_COMBINE  Create a PHZ structure of data from many PHZ structures.
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
%     'reject'    = Calls phz_reject.
%     'norm'      = Calls phz_norm.
% 
%   These are always executed in the order listed here, after the above
%   processing funtions. See the help of each function for more details.
%     'equal'     = Calls phzABR_equalizeTrials.
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

function PHZ = phz_combine(varargin)

if nargout == 0 && nargin == 0, help phz_combine, return, end

% defaults
equalGrpVar = [];
region = [];
keepVars = [];
filename = {};
verbose = false;

% user-defined
if nargin > 0 
    if iscell(varargin{1})
        folder = '';
        files = varargin{1};

    elseif ischar(varargin{1}) && isdir(varargin{1})
        folder = varargin{1};
        files = dir(folder);
        files = {files.name};
        files = files(contains(files, {'.phz'}));
        files = files(~startsWith(files, '.')); % ignore dotfiles

    else
        error([varargin{1}, ' is not a directory.'])

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
        case {'equal','equalizetrials'},equalGrpVar = varargin{i+1};
        case 'region',                  region = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
        case {'save','filename','file'},filename = addToCell(filename, varargin{i+1});
        case 'verbose',                 verbose = varargin{i+1};
    end
end

resetFields = {};

% loop through files
% ------------------
for j = 1:length(files)
    fileProgress = [num2str(j), '/', num2str(length(files)), ...
        ': ''',files{j},''''];
    
    disp(['  Combining PHZ data from file ', fileProgress])

    % load data
    if verbose, disp(['Loading data from file ', fileProgress]), end
    
    currentFile = fullfile(folder, files{j});
    TMP = phz_load(currentFile, verbose); % runs phz_check.m
    
    % do user-defined preprocessing
    for i = 1:2:length(processing)
        switch lower(processing{i})
            case 'subset',                  TMP = phz_subset(TMP,   processing{i+1}, verbose);
            case {'rect','rectify'},        TMP = phz_rect(TMP,     processing{i+1}, verbose);
            case {'filter','filt'},         TMP = phz_filter(TMP,   processing{i+1}, 'verbose', verbose);
            case {'smooth','smoothing'},    TMP = phz_smooth(TMP,   processing{i+1}, verbose);
            case 'transform',               TMP = phz_transform(TMP,processing{i+1}, verbose);
            case 'blsub',                   TMP = phz_blsub(TMP,    processing{i+1}, verbose);
            case {'rej','reject'},          TMP = phz_reject(TMP,   processing{i+1}, verbose);
            case {'norm','normtype'},       TMP = phz_norm(TMP,     processing{i+1}, verbose);
        end
    end
    
    TMP = phzABR_equalizeTrials(TMP, equalGrpVar, verbose);
    TMP = phz_region(TMP, region, verbose);
    TMP = phz_summary(TMP, keepVars, verbose);
    
    % combine data
    % -----------
    if j == 1
        PHZ = TMP;
        
        % reset history field
        PHZ.history = {};
        PHZ = phz_history(PHZ,'Combined PHZ structure created.', verbose);
        PHZ = phz_history(PHZ,['Preprocessing: ', strnumjoin(processing)], verbose);
        PHZ.lib.files{j} = currentFile;
        if ismember('filename', fieldnames(TMP.lib))
            TMP.lib = rmfield(TMP.lib, 'filename'); end
        
        PHZ.proc = [];
        PHZ.etc = [];
        PHZ.proc.combine{j} = TMP.proc;
        PHZ.etc.combine{j} = TMP.etc;

        continue
    end    
    
    % make sure data length is compatible
    if size(PHZ.data,2) ~= size(TMP.data,2)
        PHZ = phz_history(PHZ, ['NOTE: The length of the data in ''', ...
            files{j}, ''' was different, so it was not included.'], verbose, 0);
        continue
    end
    
    % make sure sampling frequency is compatible
    if TMP.srate ~= PHZ.srate
        PHZ = phz_history(PHZ, ['NOTE: The ''srate'' field of ''', ...
            files{j}, ''' is different (', num2str(TMP.(field)), ...
            '), so it was not included.'], verbose, 0);
        continue
    end
    
    % proc field
    PHZ.proc.combine{j} = TMP.proc;
    PHZ.etc.combine{j} = TMP.etc;
    
    % basic fields (strings)
    PHZ.lib.files{j} = currentFile;
    for i = {'study','datatype','units'}, field = i{1};
        if ~strcmp(TMP.(field),PHZ.(field))
            PHZ = phz_history(PHZ, ['NOTE: The ''',field,''' field of ''', ...
                files{j}, ''' is different: ''', TMP.(field),'''.'], verbose, 0);
        end
    end

    % grouping variables & tags
    % if different, reset to include unique values of tags after looping
    for i = {'participant','group','condition','session','trials'}, field = i{1};
        if ~strcmp(TMP.lib.tags.(field),'<collapsed>')
            
            if ~all(ismember(cellstr(TMP.(field)),cellstr(PHZ.(field))))
                if ~ismember(field,resetFields), resetFields{end+1} = field; end %#ok<AGROW>
            end
            
            TMP.lib.tags.(field) = categorical(cellstr(TMP.lib.tags.(field)),'Ordinal',false);
            PHZ.lib.tags.(field) = categorical(cellstr(PHZ.lib.tags.(field)),'Ordinal',false);
            PHZ.lib.tags.(field) = [PHZ.lib.tags.(field); TMP.lib.tags.(field)];
            
        end
    end
    
    % data
    PHZ.data = [PHZ.data; TMP.data];
    if numel(PHZ.data) > 50000000 % check if filesize is getting too big
        error(['Too much data to combine into one variable. Consider ',...
            'doing some preprocessing and averaging with phz_combine.'])
    end
    
    % behavioural response data
    for i = 1:5
        qx = ['q',num2str(i)];
        PHZ.resp.(qx) = [PHZ.resp.(qx); TMP.resp.(qx)];
        PHZ.resp.([qx,'_acc']) = [PHZ.resp.([qx,'_acc']); TMP.resp.([qx,'_acc'])];
        PHZ.resp.([qx,'_rt']) = [PHZ.resp.([qx,'_rt']); TMP.resp.([qx,'_rt'])];
    end

    PHZ = verifyFieldsThatShouldBeTheSame(PHZ,TMP,j);
    
    if verbose, disp(' '), end
end % end looping participants

% cleanup PHZ
% ------------
for j = 1:length(resetFields), field = resetFields{j};
    PHZ.(field) = unique(PHZ.lib.tags.(field));
    PHZ = phz_history(PHZ,['The ',field, ...
        ' field was reset to include the unique values of tags.', ...
        field,'.'],verbose,0);
end

% save to file (& phz_check)
if ~isempty(filename)
    PHZ = phz_save(PHZ,filename);
else
    PHZ = phz_check(PHZ);
end

end

function PHZ = verifyFieldsThatShouldBeTheSame(PHZ,TMP,i)
if i == 1
    
    if ismember('times',fieldnames(TMP)),     PHZ.times = TMP.times;
    elseif ismember('freqs',fieldnames(TMP)), PHZ.freqs = TMP.freqs;
    end
    
    rname = fieldnames(TMP.region);
    for j = 1:length(rname)
        PHZ.region.(rname{j}) = TMP.region.(rname{j});
    end
    
else
    if ismember('times',fieldnames(PHZ))
        if ~all(PHZ.times == TMP.times)
            error('PHZ.times is inconsistent.')
        end
    elseif ismember('freqs',fieldnames(PHZ)), PHZ.freqs = TMP.freqs;
        if ~all(PHZ.freqs == TMP.freqs)
            error('PHZ.freqs is inconsistent.')
        end
    end
    
    rname = fieldnames(PHZ.region);
    for j = 1:length(rname)
        if ~all(PHZ.region.(rname{j}) == TMP.region.(rname{j}))
            error(['PHZ.region.',(rname{j}),' is inconsistent.'])
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
