function PHZ = phz_check(PHZ,verbose)
% PHZ_CHECK  Verify and fix a PHZ structure.
% 
% usage:    PHZ = phz_check(PHZ)
% 
% Written by Gabriel A. Nespoli 2016-02-08. Revised 2016-04-01.

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
PHZ.srate       = verifyNumeric(PHZ.srate,[name,'.srate'],verbose);
checkSingleNumber(PHZ.srate,[name,'.srate']);
PHZ.data        = verifyNumeric(PHZ.data,[name,'.data'],verbose);

%% participant, group, session, trials
if ~isstruct(PHZ.tags), error([name,'.tags should be a structure.']), end
if ~isstruct(PHZ.spec), error([name,'.spec should be a structure.']), end

for i = {'participant','group','session','trials'}, field = i{1};
    
    % grouping vars
    if length(PHZ.(field)) ~= length(unique(PHZ.(field))), error([name,'.',field,' cannot contain repeated values.']), end
    PHZ.(field) = verifyCategorical(PHZ.(field),[name,'.',field],verbose);
    PHZ.(field) = checkAndFixRow(PHZ.(field),[name,'.',field],nargout,verbose);
    
    % tags
    if ischar(PHZ.tags.(field)) && strcmp(PHZ.tags.(field),'<collapsed>')
        PHZ = resetSpec(PHZ,field);
        continue
    end
    
    PHZ.tags.(field) = verifyCategorical(PHZ.tags.(field),[name,'.tags.',field],verbose);
    PHZ.tags.(field) = checkAndFixColumn(PHZ.tags.(field),[name,'.tags.',field],nargout,verbose);
    
    % grouping vars && tags
    if isempty(PHZ.tags.(field)) || any(isundefined(PHZ.(field)))
        
        if isempty(PHZ.(field)) || any(isundefined(PHZ.(field)))
            % do nothing, both are empty
            
        elseif length(PHZ.(field)) == 1
            % auto-create tags if only one type of grouping var
            PHZ.tags.(field) = repmat(PHZ.(field),size(PHZ.data,1));
            
        elseif length(PHZ.(field)) > 1
            warning(['It is unknown which values of ''',field,''' apply to which trials.'])
            % tags remains empty despite multiple values in grouping var
            
        else error(['Problem with PHZ.',field,'.'])
        end
        
    else % if ~isempty(PHZ.tags.(field))
        
        % make sure tags is same length as trials
        if (length(PHZ.tags.(field)) ~= size(PHZ.data,1))
            
            % if only one value, repeat it to the number of trials
            if length(unique(PHZ.tags.(field))) == 1
                PHZ.tags.(field) = repmat(PHZ.tags.(field),size(PHZ.data,1),1);
            else
                error([name,'.tags.',field,' must be the same length as the number of trials.'])
            end
        end
        
            % make ordinal
    if ~isempty(PHZ.(field))
        PHZ.(field)      = categorical(PHZ.(field),     cellstr(PHZ.(field)),'Ordinal',true);
        PHZ.tags.(field) = categorical(PHZ.tags.(field),cellstr(PHZ.(field)),'Ordinal',true);
    end
        
        % empty grouping var if there are tags not represented
        if ~isempty(PHZ.(field)) && ~all(ismember(PHZ.tags.(field),PHZ.(field)))
            PHZ.(field) = [];
            resetStr = ' because it did not represent all trial tags';
        else resetStr = '';
        end
        
        % if empty grouping var, reset (auto-create) from tags
        if isempty(PHZ.(field))
            
            PHZ.(field) = unique(PHZ.tags.(field));
            
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
        
        if ~ismember(PHZ.tags.(field),{'<collapsed>'})
            %             || isundefined(PHZ.(i{1}))
            
            % if there is an order, make sure spec is same length
            if length(PHZ.(field)) ~= length(PHZ.spec.(field))
                do_resetSpec = true;
                if nargout == 0, warning([name,'.spec.',field,' has an incorrect number of items.'])
                elseif verbose, disp([name,'.spec.',field,' had an incorrect number of items and was reset to the default order.'])
                end
            end
        else PHZ.spec.(field) = {};
        end
        
        % else _order is empty, make sure spec is empty
    elseif ~isempty(PHZ.spec.(field))
        PHZ.spec.(field) = {};
        disp([name,'.spec.',field,' was emptied (set to {})'])
        
    end
    
    if do_resetSpec, PHZ = resetSpec(PHZ,field); end
    
end

%% times / freqs
if all(ismember({'times','freqs'},fieldnames(PHZ))), error('Cannot have both TIMES and FREQS fields.'), end
if ismember('times',fieldnames(PHZ))
    PHZ.times       = verifyNumeric(PHZ.times,[name,'.times'],verbose);
    PHZ.times       = checkAndFixRow(PHZ.times,[name,'.times'],nargout,verbose);
    
    % fill times
    if isempty(PHZ.times) && ~isempty(PHZ.srate) && ~isempty(PHZ.data)
        %     if
    end
    
    
elseif ismember('freqs',fieldnames(PHZ))
    PHZ.freqs       = verifyNumeric(PHZ.freqs,[name,'.freqs'],verbose);
    PHZ.freqs       = checkAndFixRow(PHZ.freqs,[name,'.freqs'],nargout,verbose);
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

PHZ.tags.region = verifyCell(PHZ.tags.region,[name,'.tags.region'],verbose);
PHZ.tags.region = checkAndFixRow(PHZ.tags.region,[name,'.tags.region'],nargout,verbose);
if length(PHZ.tags.region) ~= 5, error('There should be 5 region names in PHZ.tags.region.'), end

%% resp
if ~isstruct(PHZ.resp), error([name,'.resp should be a structure.']), end

%% blc
if ismember('blc',fieldnames(PHZ))
    if ~isstruct(PHZ.blc), error([name,'.blc should be a structure.']), end
    PHZ.blc.region = verifyNumeric(PHZ.blc.region,[name,'.blc.region'],verbose);
    PHZ.blc.region = checkAndFix1x2(PHZ.blc.region,[name,'.blc.region'],nargout,verbose);
    
    if ~ismember('summary',fieldnames(PHZ))
        PHZ.blc.values = verifyNumeric(PHZ.blc.values,[name,'.blc.values'],verbose);
        PHZ.blc.values = checkAndFixColumn(PHZ.blc.values,[name,'.blc.values'],nargout,verbose);
    else
        if ~strcmp(PHZ.blc.values,'<collapsed>'), error('Problem with PHZ.blc and/or PHZ.summary.'), end
    end
end

%% rej
if ismember('rej',fieldnames(PHZ))
    if ~isstruct(PHZ.rej), error([name,'.rej should be a structure.']), end
    PHZ.rej.threshold   = verifyNumeric(PHZ.rej.threshold, [name,'.rej.threshold'],verbose);
    checkSingleNumber(PHZ.rej.threshold,[name,'.rej.threshold']);
    PHZ.rej.units = verifyChar(PHZ.rej.units,[name,'.rej.units'],verbose);
    
    if ~ismember('summary',fieldnames(PHZ))
        PHZ.rej.data        = verifyNumeric(PHZ.rej.data,      [name,'.rej.data'],verbose);
        PHZ.rej.data_locs   = verifyNumeric(PHZ.rej.data_locs, [name,'.rej.data_locs'],verbose);
        
        for i = {'participant','group','session','trials'}
            PHZ.rej.(i{1}) = verifyCategorical(PHZ.rej.(i{1}),[name,'.rej.(i{1})'],verbose);
            PHZ.rej.(i{1}) = checkAndFixColumn(PHZ.rej.(i{1}),[name,'.rej.(i{1})'],nargout,verbose);
        end
    else
        if ~strcmp(PHZ.rej.locs,'<collapsed>'),         error('Problem with PHZ.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.rej.data,'<collapsed>'),         error('Problem with PHZ.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.rej.data_locs,'<collapsed>'),    error('Problem with PHZ.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.rej.participant,'<collapsed>'),  error('Problem with PHZ.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.rej.group,'<collapsed>'),        error('Problem with PHZ.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.rej.session,'<collapsed>'),      error('Problem with PHZ.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.rej.trials,'<collapsed>'),       error('Problem with PHZ.rej and/or PHZ.summary.'), end
        if ~strcmp(PHZ.rej.data,'<collapsed>'),         error('Problem with PHZ.rej and/or PHZ.summary.'), end
    end
end

%% files
if ismember('files',fieldnames(PHZ))
    PHZ.files       = verifyCell(PHZ.files,[name,'.files'],verbose);
    PHZ.files       = checkAndFixColumn(PHZ.files,[name,'.files'],nargout,verbose);
end

%% history
PHZ.history         = verifyCell(PHZ.history,[name,'.history'],verbose);
PHZ.history         = checkAndFixColumn(PHZ.history,[name,'.history'],nargout,verbose);

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
if ~ismember('tags',fieldnames(PHZ))
    for i = {'participant','group','session','trials'}, field = i{1};
        PHZ.tags.(field) = PHZ.(field);
        PHZ.(field) = PHZ.spec.([field,'_order']);
        PHZ.spec.(field) = PHZ.spec.([field,'_spec']);
        PHZ.spec = rmfield(PHZ.spec,{[field,'_order'] [field,'_spec']});
    end
    PHZ.tags.region = PHZ.spec.region_order;
    PHZ.spec.region = PHZ.spec.region_spec;
    PHZ.spec = rmfield(PHZ.spec,{'region_order','region_spec'});
    PHZ.history{end+1} = 'Converted PHZ structure to v0.7.7.';
    if verbose, disp(PHZ.history{end}), end
end

% change field 'regions' to 'region'
if ismember('regions',fieldnames(PHZ))
    PHZ.region = PHZ.regions;
    PHZ = rmfield(PHZ,'regions');
end

if ismember('regions',fieldnames(PHZ.tags))
    PHZ.tags.region = PHZ.tags.regions;
    PHZ.tags = rmfield(PHZ.tags,'regions');
end

if ismember('regions',fieldnames(PHZ.spec))
    PHZ.spec.region = PHZ.spec.regions;
    PHZ.spec = rmfield(PHZ.spec,'regions');
end
end

function PHZ = orderPHZfields(PHZ)

% region structure
if isstruct(PHZ.region)
    
    % if spec order doesn't match the struct, recreate the struct
    if ~strcmp(strjoin(fieldnames(PHZ.region)),strjoin(PHZ.tags.region))
        rname = fieldnames(PHZ.region);
        for i = 1:length(PHZ.tags.region)
            temp.(PHZ.tags.region{i}) = PHZ.region.(rname{i});
        end
        PHZ.region = temp;
    end
end

% main structure
mainOrder = {'study'
    'datatype'
    
    'participant'
    'group'
    'session'
    'trials'
    'summary'
    
    'regions'
    'region'
    
    'times'
    'freqs'
    'data'
    
    'feature'
    'units'
    'srate'
    
    'resp'
    
    'proc'
        'norm'
        'blc'
        'rej'

    'misc'
        % 'srate'
        % 'times'
        % 'freqs'
        'tags'
        'spec'
        'files'
        
    'history'};

if ~all(ismember(fieldnames(PHZ),mainOrder))
    error('Invalid fields present in PHZ structure. Use PHZ.misc to store miscellaneous data.')
end

mainOrder = mainOrder(ismember(mainOrder,fieldnames(PHZ)));
PHZ = orderfields(PHZ,mainOrder);

end

function PHZ = resetSpec(PHZ,field)
for j = 1:length(PHZ.(field))
    PHZ.spec.(field){j} = '';
end
end
