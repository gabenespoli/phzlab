function PHZ = phz_check(PHZ,varargin)
% PHZ_CHECK  Verify the integrity of a PHZ or PHZS structure.
% 
% USAGE:
%   PHZ = phz_check(PHZ)
% 
% Written by Gabriel A. Nespoli 2016-02-08. Revised 2016-03-29.

if nargout == 0 && nargin == 0, help phz_check, end

if nargin > 1, verbose = varargin{1};
else           verbose = true;
end

% get name of input variable for accurate feedback
name = inputname(1);

PHZ = orderPHZfields(PHZ);

% verify data types
% -----------------

% basic
if ~isstruct(PHZ), error([name,' variable should be a structure.']), end
PHZ.study       = verifyChar(PHZ.study,[name,'.study'],verbose);
PHZ.datatype    = verifyChar(PHZ.datatype,[name,'.datatype'],verbose);
PHZ.units       = verifyChar(PHZ.units,[name,'.units'],verbose);
PHZ.srate       = verifyNumeric(PHZ.srate,[name,'.srate'],verbose);
checkSingleNumber(PHZ.srate,[name,'.srate']);
PHZ.data        = verifyNumeric(PHZ.data,[name,'.data'],verbose);

% participant, group, session, trials
PHZ.participant = verifyCategorical(PHZ.participant,[name,'.partcipant'],verbose);
PHZ.group       = verifyCategorical(PHZ.group,[name,'.group'],verbose);
PHZ.session     = verifyCategorical(PHZ.session,[name,'.session'],verbose);
PHZ.trials      = verifyCategorical(PHZ.trials,[name,'.trials'],verbose);

PHZ.participant = checkAndFixColumn(PHZ.participant,[name,'.partcipant'],nargout,verbose);
PHZ.group       = checkAndFixColumn(PHZ.group,[name,'.group'],nargout,verbose);
PHZ.session     = checkAndFixColumn(PHZ.session,[name,'.session'],nargout,verbose);
PHZ.trials      = checkAndFixColumn(PHZ.trials,[name,'.trials'],nargout,verbose);


% times / freqs
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

% region
if isstruct(PHZ.region)
    rname = fieldnames(PHZ.region);
    for i = 1:length(rname)
        PHZ.region.(rname{i}) = verifyNumeric(PHZ.region.(rname{i}),[name,'.region.(rname{i})'],verbose);
        PHZ.region.(rname{i})   = checkAndFix1x2(PHZ.region.(rname{i}),[name,'.region.(rname{i})'],nargout,verbose);
    end
    
elseif isnumeric(PHZ.region)
    PHZ.region = checkAndFix1x2(PHZ.region,[name,'.region'],nargout,verbose);
end

% resp
if ~isstruct(PHZ.resp), error([name,'.resp should be a structure.']), end

% blc
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

% rej
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

% spec
if ~isstruct(PHZ.spec), error([name,'.spec should be a structure.']), end
for i = {'participant','group','session','trials','region'}
    PHZ.spec.([i{1},'_order']) = verifyCell(PHZ.spec.([i{1},'_order']),    [name,'.spec.',i{1},'_order'],verbose);
    PHZ.spec.([i{1},'_spec'])  = verifyCell(PHZ.spec.([i{1},'_spec']),     [name,'.spec.',i{1},'_spec'],verbose); 
end
PHZ = verifySpecAndOrder(PHZ,name,nargout,verbose);
for i = {'participant','group','session','trials','region'}
    PHZ.spec.([i{1},'_order']) = checkAndFixRow(PHZ.spec.([i{1},'_order']),[name,'.spec.',i{1},'_order'],nargout,verbose);
    PHZ.spec.([i{1},'_spec'])  = checkAndFixRow(PHZ.spec.([i{1},'_spec']), [name,'.spec.',i{1},'_spec'],nargout,verbose);
end

% files
if ismember('files',fieldnames(PHZ))
    PHZ.files       = verifyCell(PHZ.files,[name,'.files'],verbose);
    PHZ.files       = checkAndFixColumn(PHZ.files,[name,'.files'],nargout,verbose);
end

% history
PHZ.history         = verifyCell(PHZ.history,[name,'.history'],verbose);
PHZ.history         = checkAndFixColumn(PHZ.history,[name,'.history'],nargout,verbose);

end

function PHZ = verifySpecAndOrder(PHZ,name,noutargs,verbose)

for i = {'participant','group','session','trials'}
    resetOrder = false;
    resetSpec = false;
    
    % _order
    if ~isempty(PHZ.(i{1}))
        
        if ~ismember(PHZ.(i{1}),{'<collapsed>'}) 
%             || isundefined(PHZ.(i{1}))
            
            % if there is stuff that needs an order
            if length(PHZ.spec.([i{1},'_order'])) ~= length(unique(cellstr(PHZ.(i{1}))))
                resetOrder = true;
                if noutargs == 0, warning([name,'.spec.',i{1},'_order has an incorrect number of items.'])
                elseif verbose, disp([name,'.spec.',i{1},'_order had an incorrect number of items and was reset.'])
                end
                
            elseif ~all(ismember(unique(cellstr(PHZ.(i{1}))),PHZ.spec.([i{1},'_order'])))
                resetOrder = true;
                if noutargs == 0, warning([name,'.spec.',i{1},'_order has incorrect item names.'])
                elseif verbose, disp([name,'.spec.',i{1},'_order had incorrect item names and was reset.'])
                end
                
            end
            
            if resetOrder
                PHZ.spec.([i{1},'_order']) = cellstr(unique(cellstr(PHZ.(i{1}))));
                
                % if numeric, order numerically
                if ~any(isnan(str2double(PHZ.spec.([i{1},'_order']))))
                    PHZ.spec.([i{1},'_order']) = str2double(PHZ.spec.([i{1},'_order']));
                    PHZ.spec.([i{1},'_order']) = sort(PHZ.spec.([i{1},'_order']));
                    PHZ.spec.([i{1},'_order']) = cellstr(num2str(PHZ.spec.([i{1},'_order'])));
                    PHZ.spec.([i{1},'_order']) = strrep(PHZ.spec.([i{1},'_order']),' ','');
                end
            end
        end
        
        % make ordinal
        if iscategorical(PHZ.(i{1})) && all(~isundefined(PHZ.(i{1})))
            PHZ.(i{1}) = categorical(PHZ.(i{1}),PHZ.spec.([i{1},'_order']),'Ordinal',true);
            
            if ismember('rej',fieldnames(PHZ))
                if ismember(i{1},fieldnames(PHZ.rej)) && ~strcmp(PHZ.rej.(i{1}),'<collapsed>')
                    PHZ.rej.(i{1}) = categorical(PHZ.rej.(i{1}),PHZ.spec.([i{1},'_order']),'Ordinal',true);
                end
            end
        end
        
        % else make sure order is empty
    elseif ~isempty(PHZ.spec.([i{1},'_order']))
        PHZ.spec.([i{1},'_order']) = {};
        disp([name,'.spec.',i{1},'_order was emptied (set to {})'])
    end

    
    
    % _spec
    if ~isempty(PHZ.spec.([i{1},'_order']))
        
        if ~ismember(PHZ.(i{1}),{'<collapsed>'}) 
%             || isundefined(PHZ.(i{1}))
            
            % if there is an order, make sure spec is same length
            if length(PHZ.spec.([i{1},'_order'])) ~= length(PHZ.spec.([i{1},'_spec']))
                resetSpec = true;
                if noutargs == 0, warning([name,'.spec.',i{1},'_spec has an incorrect number of items.'])
                elseif verbose, disp([name,'.spec.',i{1},'_spec had an incorrect number of items and was reset to the default order.'])
                end
            end
        else PHZ.spec.([i{1},'_spec']) = {};
        end
        
        % else _order is empty, make sure spec is empty
    elseif ~isempty(PHZ.spec.([i{1},'_spec']))
        PHZ.spec.([i{1},'_spec']) = {};
        disp([name,'.spec.',i{1},'_spec was emptied (set to {})'])

    end
    
    if resetSpec
        for j = 1:length(PHZ.spec.([i{1},'_order']))
            PHZ.spec.([i{1},'_spec']){j} = '';
        end
    end
end
end

function checkSameLength(a,b,name1,name2)
if length(a) ~= length(b)
    error([name1,' & ',name2,' should be the same length.'])
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

function PHZ = orderPHZfields(PHZ)

% region structure
if isstruct(PHZ.region)
    
    % if spec order doesn't match the struct, recreate the struct
    if ~strcmp(strjoin(fieldnames(PHZ.region)),strjoin(PHZ.spec.region_order))
        rname = fieldnames(PHZ.region);
        for i = 1:length(PHZ.spec.region_order)
            temp.(PHZ.spec.region_order{i}) = PHZ.region.(rname{i});
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
    
    'times'
    'freqs'
    'data'
    
    'units'
    'srate'

    'summary'
    'feature'
    'region'
    'regions'
    'rej'
    'blc'
    'rect'
    'norm'
    
    'resp'
    'spec'
    'files'
    
    'misc'
    'history'};

if ~all(ismember(fieldnames(PHZ),mainOrder))
    error('Invalid fields present in PHZ structure. Use PHZ.misc to store miscellaneous data.')
end

mainOrder = mainOrder(ismember(mainOrder,fieldnames(PHZ)));
PHZ = orderfields(PHZ,mainOrder);



end
