function PHZ = phz_check(PHZ,verbose)
% PHZ_CHECK  Verify and fix a PHZ structure.
% 
% usage:    PHZ = phz_check(PHZ)
% 
% Written by Gabriel A. Nespoli 2016-02-08. Revised 2016-04-04.
if nargout == 0 && nargin == 0, help phz_check, end
if nargin < 2, verbose = true; end

% get name of input variable for accurate feedback
name = inputname(1);

% pre-checking
PHZ = backwardsCompatibility(PHZ,verbose);
PHZ = orderPHZfields(PHZ);

%% basic
if ~isstruct(PHZ), error([name,' variable should be a structure.']), end
PHZ.study       = verifyChar(PHZ.study,[name,'.study'],verbose);
PHZ.datatype    = verifyChar(PHZ.datatype,[name,'.datatype'],verbose);
PHZ.units       = verifyChar(PHZ.units,[name,'.units'],verbose);
PHZ.meta.srate       = verifyNumeric(PHZ.meta.srate,[name,'.meta.srate'],verbose);
checkSingleNumber(PHZ.meta.srate,[name,'.meta.srate']);
PHZ.data        = verifyNumeric(PHZ.data,[name,'.data'],verbose);

%% participant, group, session, trials
if ~isstruct(PHZ.meta.tags), error([name,'.meta.tags should be a structure.']), end
if ~isstruct(PHZ.meta.spec), error([name,'.meta.spec should be a structure.']), end

for i = {'participant','group','session','trials'}, field = i{1};
    
    % grouping vars
    if length(PHZ.(field)) ~= length(unique(PHZ.(field))), error([name,'.',field,' cannot contain repeated values.']), end
    PHZ.(field) = verifyCategorical(PHZ.(field),[name,'.',field],verbose);
    PHZ.(field) = checkAndFixRow(PHZ.(field),[name,'.',field],nargout,verbose);
    
    % tags
    if ischar(PHZ.meta.tags.(field)) && strcmp(PHZ.meta.tags.(field),'<collapsed>')
        PHZ = resetSpec(PHZ,field);
        continue
    end
    
    PHZ.meta.tags.(field) = verifyCategorical(PHZ.meta.tags.(field),[name,'.meta.tags.',field],verbose);
    PHZ.meta.tags.(field) = checkAndFixColumn(PHZ.meta.tags.(field),[name,'.meta.tags.',field],nargout,verbose);
    
    % grouping vars && tags
    if isempty(PHZ.meta.tags.(field)) || any(isundefined(PHZ.(field)))
        
        if isempty(PHZ.(field)) || any(isundefined(PHZ.(field)))
            % do nothing, both are empty
            
        elseif length(PHZ.(field)) == 1
            % auto-create tags if only one type of grouping var
            PHZ.meta.tags.(field) = repmat(PHZ.(field),size(PHZ.data,1));
            
        elseif length(PHZ.(field)) > 1
            warning(['It is unknown which values of ''',field,''' apply to which trials.'])
            % tags remains empty despite multiple values in grouping var
            
        else error(['Problem with PHZ.',field,'.'])
        end
        
    else % if ~isempty(PHZ.tags.(field))
        
        % make sure tags is same length as trials
        if (length(PHZ.meta.tags.(field)) ~= size(PHZ.data,1))
            
            % if only one value, repeat it to the number of trials
            if length(unique(PHZ.meta.tags.(field))) == 1
                PHZ.meta.tags.(field) = repmat(PHZ.meta.tags.(field),size(PHZ.data,1),1);
            else
                error([name,'.tags.',field,' must be the same length as the number of trials.'])
            end
        end
        
            % make ordinal
    if ~isempty(PHZ.(field))
        PHZ.(field)      = categorical(PHZ.(field),     cellstr(PHZ.(field)),'Ordinal',true);
        PHZ.meta.tags.(field) = categorical(PHZ.meta.tags.(field),cellstr(PHZ.(field)),'Ordinal',true);
    end
        
        % empty grouping var if there are tags not represented
        if ~isempty(PHZ.(field)) && ~all(ismember(PHZ.meta.tags.(field),PHZ.(field)))
            PHZ.(field) = [];
            resetStr = ' because it did not represent all trial tags';
        else resetStr = '';
        end
        
        % if empty grouping var, reset (auto-create) from tags
        if isempty(PHZ.(field))
            
            PHZ.(field) = unique(PHZ.meta.tags.(field));
            
            % if numeric, order numerically
            if ~any(isnan(str2double(PHZ.(field))))
                PHZ.(field) = str2double(PHZ.(field));
                PHZ.(field) = sort(PHZ.(field));
                PHZ.(field) = cellstr(num2str(PHZ.(field)));
                PHZ.(field) = strrep(PHZ.(field),' ','');
            end
            PHZ.history{end+1} = ['PHZ.',field,' was reset',resetStr,'.'];
            if verbose, disp(PHZ.history{end}), end
        end
    end

    % verify spec
    do_resetSpec = [];
    if ~isempty(PHZ.(field))
        
        if ~ismember(PHZ.meta.tags.(field),{'<collapsed>'})
            %             || isundefined(PHZ.(i{1}))
            
            % if there is an order, make sure spec is same length
            if length(PHZ.(field)) ~= length(PHZ.meta.spec.(field))
                do_resetSpec = true;
                if nargout == 0, warning([name,'.meta.spec.',field,' has an incorrect number of items.'])
                elseif verbose, disp([name,'.meta.spec.',field,' had an incorrect number of items and was reset to the default order.'])
                end
            end
        else PHZ.meta.spec.(field) = {};
        end
        
        % else _order is empty, make sure spec is empty
    elseif ~isempty(PHZ.meta.spec.(field))
        PHZ.meta.spec.(field) = {};
        disp([name,'.meta.spec.',field,' was emptied (set to {})'])
        
    end
    
    if do_resetSpec, PHZ = resetSpec(PHZ,field); end
    
end

%% times / freqs
if all(ismember({'times','freqs'},fieldnames(PHZ))), error('Cannot have both TIMES and FREQS fields.'), end
if ismember('times',fieldnames(PHZ))
    PHZ.meta.times       = verifyNumeric(PHZ.meta.times,[name,'.meta.times'],verbose);
    PHZ.meta.times       = checkAndFixRow(PHZ.meta.times,[name,'.meta.times'],nargout,verbose);
    
    % fill times
    if isempty(PHZ.meta.times) && ~isempty(PHZ.meta.srate) && ~isempty(PHZ.data)
        %     if
    end
    
    
elseif ismember('freqs',fieldnames(PHZ))
    PHZ.meta.freqs       = verifyNumeric(PHZ.meta.freqs,[name,'.meta.freqs'],verbose);
    PHZ.meta.freqs       = checkAndFixRow(PHZ.meta.freqs,[name,'.meta.freqs'],nargout,verbose);
end

%% region
if isstruct(PHZ.region)
    rname = fieldnames(PHZ.region);
    for i = 1:length(rname)
        PHZ.region.(rname{i}) = verifyNumeric(PHZ.region.(rname{i}),[name,'.region.(rname{i})'],verbose);
        PHZ.region.(rname{i})   = checkAndFix1x2(PHZ.region.(rname{i}),[name,'.region.(rname{i})'],nargout,verbose);
    end
    
elseif isnumeric(PHZ.region)
    PHZ.region = checkAndFix1x2(PHZ.region,[name,'.region'],nargout,verbose);
end

PHZ.meta.tags.region = verifyCell(PHZ.meta.tags.region,[name,'.meta.tags.region'],verbose);
PHZ.meta.tags.region = checkAndFixRow(PHZ.meta.tags.region,[name,'.meta.tags.region'],nargout,verbose);
if length(PHZ.meta.tags.region) ~= 5, error('There should be 5 region names in PHZ.meta.tags.region.'), end

%% resp
if ~isstruct(PHZ.resp), error([name,'.resp should be a structure.']), end

%% blc
if isstruct(PHZ.proc) && ismember('blc',fieldnames(PHZ.proc))
    if ~isstruct(PHZ.blc), error([name,'.blc should be a structure.']), end
    PHZ.proc.blc.region = verifyNumeric(PHZ.proc.blc.region,[name,'.proc.blc.region'],verbose);
    PHZ.proc.blc.region = checkAndFix1x2(PHZ.proc.blc.region,[name,'.proc.blc.region'],nargout,verbose);
    
    if ~ismember('summary',fieldnames(PHZ))
        PHZ.proc.blc.values = verifyNumeric(PHZ.proc.blc.values,[name,'.proc.blc.values'],verbose);
        PHZ.proc.blc.values = checkAndFixColumn(PHZ.proc.blc.values,[name,'.proc.blc.values'],nargout,verbose);
    else
        if ~strcmp(PHZ.proc.blc.values,'<collapsed>'), error('Problem with PHZ.proc.blc and/or PHZ.summary.'), end
    end
end

%% rej
if isstruct(PHZ.proc) && ismember('rej',fieldnames(PHZ.proc))
    if ~isstruct(PHZ.proc.rej), error([name,'.proc.rej should be a structure.']), end
    PHZ.proc.rej.threshold   = verifyNumeric(PHZ.proc.rej.threshold, [name,'.proc.rej.threshold'],verbose);
    checkSingleNumber(PHZ.proc.rej.threshold,[name,'.proc.rej.threshold']);
    PHZ.proc.rej.units = verifyChar(PHZ.proc.rej.units,[name,'.proc.rej.units'],verbose);
    
    if ~ismember('summary',fieldnames(PHZ))
        PHZ.proc.rej.data        = verifyNumeric(PHZ.proc.rej.data,      [name,'.proc.rej.data'],verbose);
        PHZ.proc.rej.data_locs   = verifyNumeric(PHZ.proc.rej.data_locs, [name,'.proc.rej.data_locs'],verbose);
        
        for i = {'participant','group','session','trials'}
            PHZ.proc.rej.(i{1}) = verifyCategorical(PHZ.proc.rej.(i{1}),[name,'.proc.rej.(i{1})'],verbose);
            PHZ.proc.rej.(i{1}) = checkAndFixColumn(PHZ.proc.rej.(i{1}),[name,'.proc.rej.(i{1})'],nargout,verbose);
        end
    else
        if ~strcmp(PHZ.proc.rej.locs,'<collapsed>'),         error('Problem with PHZ.proc.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.proc.rej.data,'<collapsed>'),         error('Problem with PHZ.proc.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.proc.rej.data_locs,'<collapsed>'),    error('Problem with PHZ.proc.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.proc.rej.participant,'<collapsed>'),  error('Problem with PHZ.proc.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.proc.rej.group,'<collapsed>'),        error('Problem with PHZ.proc.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.proc.rej.session,'<collapsed>'),      error('Problem with PHZ.proc.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.proc.rej.trials,'<collapsed>'),       error('Problem with PHZ.proc.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.proc.rej.data,'<collapsed>'),         error('Problem with PHZ.proc.rej and/or PHZ.summary.'), end
    end
end

%% norm


%% files
if ismember('files',fieldnames(PHZ.meta))
    PHZ.meta.files       = verifyCell(PHZ.meta.files,[name,'.meta.files'],verbose);
    PHZ.meta.files       = checkAndFixColumn(PHZ.meta.files,[name,'.meta.files'],nargout,verbose);
end

%% history
PHZ.history         = verifyCell(PHZ.history,[name,'.history'],verbose);
PHZ.history         = checkAndFixColumn(PHZ.history,[name,'.history'],nargout,verbose);

end

function PHZ = resetSpec(PHZ,field)
for j = 1:length(PHZ.(field))
    PHZ.meta.spec.(field){j} = '';
end
end

function C = verifyNumeric(C,name,verbose)
if isnumeric(C), return, end
try
    if iscategorical(C),    C = cellstr(C);     end
    if iscell(C),           C = C{:};           end
    if ischar(C),           C = str2double(C);  end
    if verbose, disp(['Changed ',name,' to a double.']), end
catch, error([name,' should be a numeric array.'])
end
end

function C = verifyChar(C,name,verbose)
if ischar(C), return, end
try
    if isnumeric(C), C = num2str(C); end
    if iscell(C), C = C{:}; end
    if verbose, disp(['Changed ',name,' to a string.']), end
catch, error([name,' should be a string.'])
end
end

function C = verifyCell(C,name,verbose)
if iscell(C), return, end
try
    if isnumeric(C),        C = {C};        end
    if ischar(C),           C = cellstr(C); end
    if iscategorical(C),    C = cellstr(C); end
    if verbose, disp(['Changed ',name,' to a cell array.']), end
catch, error([name,' should be a cell array.'])
end
end

function C = verifyCategorical(C,name,verbose)
if iscategorical(C), return, end
try
    if isnumeric(C), C = num2str(C);     end
    if ischar(C),    C = cellstr(C);     end
    if iscell(C),    C = categorical(C); end
    
%     if isordinal(C) && length(unique(C)) == 1
%         C = categorical(C,'Ordinal',false);
%     end
    
    if verbose, disp(['Changed ',name,' to a categorical array.']), end
catch, error([name,' should be a categorical array.'])
end
end

function x = checkAndFixRow(x,name,noutargs,verbose)
if isempty(x), return, end
if ~isrow(x)
    if iscolumn(x)
        x = x';
        if noutargs == 0
            warning([name,' should be changed from a column vector to a row vector.'])
        elseif verbose, disp(['Changed ',name,' from a column vector to a row vector.'])
        end
    else error(['Something is wrong with ',name,'.'])
    end
end
end

function x = checkAndFixColumn(x,name,noutargs,verbose)
if isempty(x), return, end
if ~iscolumn(x)
    if isrow(x)
        x = x';
        if noutargs == 0
            warning([name,' should be changed from a row vector to a column vector.'])
        elseif verbose, disp(['Changed ',name,' from a row vector to a column vector.'])
        end
    else error(['Something is wrong with ',name,'.'])
    end
end
end

function x = checkAndFix1x2(x,name,noutargs,verbose)
if isempty(x), return, end

x = checkAndFixRow(x,name,noutargs,verbose);

if size(x,2) ~= 2
    error([name,' should be of size 1 X 2.'])
end
end

function checkSingleNumber(x,name)
if isempty(x), return, end
if length(x) ~= 1
    error([name,' should be a single number.'])
end
end

function PHZ = backwardsCompatibility(PHZ,verbose)

% swap grouping and order vars, add tags (older than v0.7.7)
if ~ismember('tags',fieldnames(PHZ)) && ~ismember('meta',fieldnames(PHZ))
    for i = {'participant','group','session','trials'}, field = i{1};
        PHZ.tags.(field) = PHZ.(field);
        PHZ.(field) = PHZ.spec.([field,'_order']);
        PHZ.spec.(field) = PHZ.spec.([field,'_spec']);
        PHZ.spec = rmfield(PHZ.spec,{[field,'_order'] [field,'_spec']});
    end
    PHZ.tags.region = PHZ.spec.region_order;
    PHZ.spec.region = PHZ.spec.region_spec;
    PHZ.spec = rmfield(PHZ.spec,{'region_order','region_spec'});
    PHZ = phzUtil_history(PHZ,'Converted PHZ structure to v0.7.7.',verbose,0);
end

% change field 'regions' to 'region'
if ismember('regions',fieldnames(PHZ))
    PHZ.region = PHZ.regions;
    PHZ = rmfield(PHZ,'regions');
end

if ismember('regions',fieldnames(PHZ.meta.tags))
    PHZ.meta.tags.region = PHZ.meta.tags.regions;
    PHZ.meta.tags = rmfield(PHZ.meta.tags,'regions');
end

if ismember('regions',fieldnames(PHZ.meta.spec))
    PHZ.meta.spec.region = PHZ.meta.spec.regions;
    PHZ.meta.spec = rmfield(PHZ.meta.spec,'regions');
end

% move stuff to meta and create proc (older than v0.8)
if ~all(ismember({'proc','meta'},fieldnames(PHZ))) && any(ismember({'rej','blc','norm'},fieldnames(PHZ)))
    warning(['Preprocessing (rej, blc, norm) must be undone ',...
        'before this file can be compatible with this version of ',...
        'PHZLAB.'])
    s = input('Should PHZLAB undo this preprocessing? [y/n]','s');
    switch lower(s)
        case 'n', disp('Aborting...'), error(' ')
        case 'y',
            PHZ = phz_norm(PHZ,0);
            PHZ = phz_blc(PHZ,0);
            PHZ = phz_rej(PHZ,0);
    end
end

if ismember('times',fieldnames(PHZ))
    PHZ.meta.times = PHZ.times;
    PHZ = rmfield(PHZ,'times');
elseif ismember('freqs',fieldnames(PHZ))
    PHZ.meta.freqs = PHZ.freqs;
    PHZ = rmfield(PHZ,'freqs');
end

for i = {'srate','tags','spec'}, field = i{1};
    if ismember(field,fieldnames(PHZ))
        PHZ.meta.(field) = PHZ.(field);
        PHZ = rmfield(PHZ,field);
    end
end

if ismember('files',fieldnames(PHZ))
    PHZ.meta.files = PHZ.files;
    PHZ = rmfield(PHZ,'files');
end

if ismember('filename',fieldnames(PHZ.misc))
    PHZ.meta.filename = PHZ.misc.filename;
    PHZ.misc = rmfield(PHZ.misc,'filename');
end

PHZ.proc = [];
PHZ = phzUtil_history(PHZ,'Converted PHZ structure to v0.8.',verbose,0);
end

function PHZ = orderPHZfields(PHZ)

% region structure
if isstruct(PHZ.region)
    
    % if spec order doesn't match the struct, recreate the struct
    if ~strcmp(strjoin(fieldnames(PHZ.region)),strjoin(PHZ.meta.tags.region))
        rname = fieldnames(PHZ.region);
        for i = 1:length(PHZ.meta.tags.region)
            temp.(PHZ.meta.tags.region{i}) = PHZ.region.(rname{i});
        end
        PHZ.region = temp;
    end
end

% main structure
% --------------
mainOrder = {
    'study'
    'datatype'
    
    'participant'
    'group'
    'session'
    'trials'
    'summary'
    'region'
    
    'data'
    'feature'
    'units'
    
    'resp'
    'proc'
    'meta'
    'misc'
    'history'};
if ~all(ismember(fieldnames(PHZ),mainOrder))
    error(['Invalid fields present in PHZ structure. ',...
        'Use PHZ.misc to store miscellaneous data.'])
end
mainOrder = mainOrder(ismember(mainOrder,fieldnames(PHZ)));
PHZ = orderfields(PHZ,mainOrder);

% meta structure
% --------------
metaOrder = {
    'srate'
    'times'
    'freqs'
    
    'tags'
    'spec'
    'filename'
    'files'
    };
if ~all(ismember(fieldnames(PHZ.meta),metaOrder))
    error(['Invalid fields present in PHZ structure. ',...
        'Use PHZ.misc to store miscellaneous data.'])
end
metaOrder = metaOrder(ismember(metaOrder,fieldnames(PHZ.meta)));
PHZ.meta = orderfields(PHZ.meta,metaOrder);
end