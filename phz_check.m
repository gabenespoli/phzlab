% PHZ_CHECK  Verify and fix a PHZLAB data structure.
%
% USAGE
%  PHZ = phz_check(PHZ)

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

function PHZ = phz_check(PHZ,verbose)

if nargout == 0 && nargin == 0, help phz_check, end
if nargin < 2
    verbose = 1; % use verbose = 2 for even more verbose
end

% get name of input variable for accurate feedback
name = inputname(1);

% pre-checking
PHZ = backwardsCompatibility(PHZ,verbose);
PHZ = orderPHZfields(PHZ);

%% basic
if ~isstruct(PHZ), error([name,' variable should be a structure.']), end
PHZ.study       = verifyChar(PHZ.study,[name,'.study'],verbose);
PHZ.datatype    = verifyChar(PHZ.datatype,[name,'.datatype'],verbose);

PHZ.srate = verifyNumeric(PHZ.srate,[name,'.srate'],verbose);
checkSingleNumber(PHZ.srate,[name,'.srate']);

PHZ.units       = verifyChar(PHZ.units,[name,'.units'],verbose);
PHZ.data        = verifyNumeric(PHZ.data,[name,'.data'],verbose);

%% times / freqs
if all(ismember({'times','freqs'},fieldnames(PHZ))), error('Cannot have both TIMES and FREQS fields.'), end
if ismember('times',fieldnames(PHZ))
    PHZ.times = verifyNumeric(PHZ.times,[name,'.times'],verbose);
    PHZ.times = checkAndFixRow(PHZ.times,[name,'.times'],nargout,verbose);
    
    % fill times
    if isempty(PHZ.times) && ~isempty(PHZ.srate) && ~isempty(PHZ.data)
    end
    
elseif ismember('freqs',fieldnames(PHZ))
    PHZ.freqs = verifyNumeric(PHZ.freqs,[name,'.freqs'],verbose);
    PHZ.freqs = checkAndFixRow(PHZ.freqs,[name,'.freqs'],nargout,verbose);
end

%% grouping vars, lib.tags, lib.spec
if ~isstruct(PHZ.lib.tags), error([name,'.lib.tags should be a structure.']), end
if ~isstruct(PHZ.lib.spec), error([name,'.lib.spec should be a structure.']), end

for i = {'participant','group','condition','session','trials'}, field = i{1};
    
    % grouping vars
    PHZ.(field) = verifyCategorical(PHZ.(field),[name,'.',field],verbose);
    PHZ.(field) = checkAndFixRow(PHZ.(field),[name,'.',field],nargout,verbose);
    if length(PHZ.(field)) ~= length(unique(PHZ.(field))), error([name,'.',field,' cannot contain repeated values.']), end
    
    % tags
    if ischar(PHZ.lib.tags.(field)) && strcmp(PHZ.lib.tags.(field),'<collapsed>')
        PHZ = resetSpec(PHZ,field);
        continue
    end
    
    PHZ.lib.tags.(field) = verifyCategorical(PHZ.lib.tags.(field),[name,'.lib.tags.',field],verbose);
    PHZ.lib.tags.(field) = checkAndFixColumn(PHZ.lib.tags.(field),[name,'.lib.tags.',field],nargout,verbose);
    
    % grouping vars && tags
    if isempty(PHZ.lib.tags.(field)) || any(isundefined(PHZ.(field)))
        
        % both are empty, do nothing
        if isempty(PHZ.(field)) || any(isundefined(PHZ.(field)))
            PHZ.(field) = categorical(cellstr('-'));
        end
            
        % only 1 grouping var value, auto-create tags
        if length(PHZ.(field)) == 1
            PHZ.lib.tags.(field) = repmat(PHZ.(field),size(PHZ.data,1),1);
            
            % multiple grouping var values; tags remains empty
        elseif length(PHZ.(field)) > 1
            warning(['It is unknown which values of ''',field,''' apply to which trials.'])
            
        else 
            error(['Problem with ',name,'.',field,'.'])
        end
        
    else % if ~isempty(PHZ.lib.tags.(field))
        
        % make sure tags is same length as number of trials
        if (length(PHZ.lib.tags.(field)) ~= size(PHZ.data,1))
            
            % if only one value, repeat it to the number of trials
            if length(unique(PHZ.lib.tags.(field))) == 1
                PHZ.lib.tags.(field) = repmat(PHZ.lib.tags.(field),size(PHZ.data,1),1);
            else
                error([name,'.lib.tags.',field,' must be the same length as the number of trials.'])
            end
        end
        
        % if there are tags not represented, empty grouping var
        if ~isempty(PHZ.(field)) && ~all(ismember(cellstr(PHZ.lib.tags.(field)),cellstr(PHZ.(field))))
            %             PHZ.(field) = unique(PHZ.lib.tags.(field))';
            PHZ.(field) = [];
            resetStr = ' because it did not represent all trial tags';
        else
            resetStr = '';
        end
        
        
        % if empty grouping var, reset (auto-create) from tags
        if isempty(PHZ.(field))
            PHZ.(field) = unique(PHZ.lib.tags.(field))';
            if verbose == 2, verbose = true; else, verbose = false; end
            PHZ = phz_history(PHZ,[name,'.',field,' was reset',resetStr,'.'],verbose,0);
        end
        
        % if numeric, order numerically
        try
            if ~any(isnan(str2double(cellstr(PHZ.(field)))))
                temp = str2double(cellstr(PHZ.(field)));
                temp = sort(temp);
%                 PHZ.(field) = cellstr(num2str(PHZ.(field)));
%                 PHZ.(field) = strrep(PHZ.(field),' ','');
                temp = verifyCategorical(temp);
                temp = categorical(temp,temp,'Ordinal',true);
                if ~isequal(PHZ.(field),temp)
                    PHZ.(field) = temp;
                    PHZ = phz_history(PHZ,[name,'.',field,' was ordered numerically.'],verbose,0);
                end
            end
        catch
        end
    end
    
    % make ordinal
    if ~isempty(PHZ.(field)) && all(~isundefined(PHZ.(field)))
        PHZ.(field)           = categorical(PHZ.(field),          cellstr(PHZ.(field)),'Ordinal',true);
        PHZ.lib.tags.(field) = categorical(PHZ.lib.tags.(field),cellstr(PHZ.(field)),'Ordinal',true);
    end
    
    % verify spec
    do_resetSpec = [];
    if ~isempty(PHZ.(field))
        
        if ~ismember(PHZ.lib.tags.(field),{'<collapsed>'})
            %             || isundefined(PHZ.(i{1}))
            
            % if there is an order, make sure spec is same length
            if length(PHZ.(field)) ~= length(PHZ.lib.spec.(field))
                do_resetSpec = true;
                if nargout == 0, warning([name,'.lib.spec.',field,' has an incorrect number of items.'])
                % elseif verbose, disp(['- ',name,'.lib.spec.',field,' had an incorrect number of items and was reset to the default order.'])
                end
            end
        else
            PHZ.lib.spec.(field) = {};
        end
        
        % else _order is empty, make sure spec is empty
    elseif ~isempty(PHZ.lib.spec.(field))
        PHZ.lib.spec.(field) = {};
        % disp(['- ',name,'.lib.spec.',field,' was emptied (set to {})'])
        
    end
    
    if do_resetSpec
        PHZ = resetSpec(PHZ,field); end
    
end

%% region
if isstruct(PHZ.region)
    if length(unique(PHZ.lib.tags.region)) < length(PHZ.lib.tags.region), error('All region fields must have unique names.'), end
    
    rname = fieldnames(PHZ.region);
    
    for i = 1:length(rname)
        PHZ.region.(rname{i}) = verifyNumeric(PHZ.region.(rname{i}),[name,'.region.',(rname{i})],verbose);
        PHZ.region.(rname{i}) = checkAndFix1x2(PHZ.region.(rname{i}),[name,'.region.',(rname{i})],nargout,verbose);
        
        % rename the region if there is a new name in PHZ.lib.tags.region
        if ~strcmp(rname{i},PHZ.lib.tags.region{i})
            PHZ.region.(PHZ.lib.tags.region{i}) = PHZ.region.(rname{i});
            PHZ.region = rmfield(PHZ.region,rname{i});
        end
    end
    
    PHZ.region = orderfields(PHZ.region,PHZ.lib.tags.region);
    
elseif isnumeric(PHZ.region)
    PHZ.region = checkAndFix1x2(PHZ.region,[name,'.region'],nargout,verbose);
end

PHZ.lib.tags.region = verifyCell(PHZ.lib.tags.region,[name,'.lib.tags.region'],verbose);
PHZ.lib.tags.region = checkAndFixRow(PHZ.lib.tags.region,[name,'.lib.tags.region'],nargout,verbose);
% if length(PHZ.lib.tags.region) ~= 5
%     error('There should be 5 region names in PHZ.lib.tags.region.'), end

%% resp
if ~isstruct(PHZ.resp)
    error([name,'.resp should be a structure.']), end


%% proc

% filter
% ------

% epoch
% -----

% trials
% ------

% rectify
% -------
if ismember('rectify',fieldnames(PHZ.proc))
    verifyChar(PHZ.proc.rectify,[name,'.proc.rectify'],verbose); end

% smooth
% ------
if ismember('smooth',fieldnames(PHZ.proc))
    verifyChar(PHZ.proc.smooth,[name,'.proc.smooth'],verbose); end

% transform
% ---------
if ismember('transform',fieldnames(PHZ.proc))
    if ~ischar(PHZ.proc.transform)
        verifyCell(PHZ.proc.transform,[name,'.proc.transform'],verbose); end
end

% rej
% ---
% the 'rej' field is deprecated in favour of 'reject', in phzlab version >= 1
% this section is kept for backwards compatibility
if ismember('rej',fieldnames(PHZ.proc))
    if ~isstruct(PHZ.proc.rej)
        error([name,'.proc.rej should be a structure.']), end
    PHZ.proc.rej.threshold   = verifyNumeric(PHZ.proc.rej.threshold, [name,'.proc.rej.threshold'],verbose);
    checkSingleNumber(PHZ.proc.rej.threshold,[name,'.proc.rej.threshold']);
    PHZ.proc.rej.units = verifyChar(PHZ.proc.rej.units,[name,'.proc.rej.units'],verbose);
    
    if ~ismember('summary',fieldnames(PHZ.proc))
        PHZ.proc.rej.data        = verifyNumeric(PHZ.proc.rej.data,      [name,'.proc.rej.data'],verbose);
        PHZ.proc.rej.data_locs   = verifyNumeric(PHZ.proc.rej.data_locs, [name,'.proc.rej.data_locs'],verbose);
        
        for i = {'participant','group','session','trials'}
            PHZ.proc.rej.(i{1}) = verifyCategorical(PHZ.proc.rej.(i{1}),[name,'.proc.rej.(i{1})'],verbose);
            PHZ.proc.rej.(i{1}) = checkAndFixColumn(PHZ.proc.rej.(i{1}),[name,'.proc.rej.(i{1})'],nargout,verbose);
        end
    else
        if ~strcmp(PHZ.proc.rej.locs,'<collapsed>'),         error('Problem with PHZ.proc.rej and/or PHZ.proc.summary.'), end
        if ~strcmp(PHZ.proc.rej.data,'<collapsed>'),         error('Problem with PHZ.proc.rej and/or PHZ.proc.summary.'), end
        if ~strcmp(PHZ.proc.rej.data_locs,'<collapsed>'),    error('Problem with PHZ.proc.rej and/or PHZ.proc.summary.'), end
        if ~strcmp(PHZ.proc.rej.participant,'<collapsed>'),  error('Problem with PHZ.proc.rej and/or PHZ.proc.summary.'), end
        if ~strcmp(PHZ.proc.rej.group,'<collapsed>'),        error('Problem with PHZ.proc.rej and/or PHZ.proc.summary.'), end
        if ~strcmp(PHZ.proc.rej.session,'<collapsed>'),      error('Problem with PHZ.proc.rej and/or PHZ.proc.summary.'), end
        if ~strcmp(PHZ.proc.rej.trials,'<collapsed>'),       error('Problem with PHZ.proc.rej and/or PHZ.proc.summary.'), end
        if ~strcmp(PHZ.proc.rej.data,'<collapsed>'),         error('Problem with PHZ.proc.rej and/or PHZ.proc.summary.'), end
    end
end

% reject
% ------
if ismember('reject',fieldnames(PHZ.proc))
    checkSingleNumber(PHZ.proc.reject.threshold,[name,'.proc.reject.threshold']);
    PHZ.proc.reject.units     = verifyChar(PHZ.proc.reject.units,[name,'.proc.reject.units'],verbose);
    PHZ.proc.reject.keep      = verifyLogical(PHZ.proc.reject.keep,[name,'.proc.reject.keep'],verbose);
end

% review
% ------
if ismember('review',fieldnames(PHZ.proc))
    PHZ.proc.review.keep  = verifyLogical(PHZ.proc.review.keep,[name,'.proc.review.keep'],verbose);
end
if ismember('views',fieldnames(PHZ.lib.tags))
    PHZ.proc.review.views = verifyNumeric(PHZ.proc.review.views,[name,'.proc.review.views'],verbose);
end

% blsub
% ---
if ismember('blsub',fieldnames(PHZ.proc))
    if ~isstruct(PHZ.proc.blsub)
        error([name,'.blsub should be a structure.']), end
    PHZ.proc.blsub.region = verifyNumeric(PHZ.proc.blsub.region,[name,'.proc.blsub.region'],verbose);
    PHZ.proc.blsub.region = checkAndFix1x2(PHZ.proc.blsub.region,[name,'.proc.blsub.region'],nargout,verbose);
    
    if ~ismember('summary',fieldnames(PHZ.proc))
        PHZ.proc.blsub.values = verifyNumeric(PHZ.proc.blsub.values,[name,'.proc.blsub.values'],verbose);
        PHZ.proc.blsub.values = checkAndFixColumn(PHZ.proc.blsub.values,[name,'.proc.blsub.values'],nargout,verbose);
    else
        if ~strcmp(PHZ.proc.blsub.values,'<collapsed>')
            error('Problem with PHZ.proc.blsub and/or PHZ.proc.summary.'), end
    end
end

% norm
% ----
if ismember('norm',fieldnames(PHZ.proc))
    verifyChar(PHZ.proc.norm.type,[name,'.proc.norm.type'],verbose);
    verifyNumeric(PHZ.proc.norm.mean,[name,'.proc.norm.mean'],verbose);
    verifyNumeric(PHZ.proc.norm.stDev,[name,'.proc.norm.stDev'],verbose);
    verifyChar(PHZ.proc.norm.oldUnits,[name,'.proc.norm.oldUnits'],verbose);
    %     for i = {'mean','stDev'}, field = i{1};
    %         if length(PHZ.proc.norm.(field)) == 1, continue, end
    %
    %         if ismember('rej',fieldnames(PHZ.proc))
    %             if length(PHZ.proc.norm.(field)) ~= size(PHZ.data,1) + size(PHZ.proc.rej.data,1)
    %                 error([name,'.proc.norm.',field,' should either be of ',...
    %                     'length 1 or the same length as the number of trials.'])
    %             end
    %
    %         elseif length(PHZ.proc.norm.(field)) ~= size(PHZ.data,1)
    %             error([name,'.proc.norm.',field,' should either be of ',...
    %                 'length 1 or the same length as the number of trials.'])
    %         end
    %     end
end

%% lib (except tags & spec)

% filename
if ismember('filename',fieldnames(PHZ.lib))
    verifyChar(PHZ.lib.filename,[name,'.lib.filename'],verbose);
%     if ~exist(PHZ.lib.filename,'file')
%         disp('The filename for this PHZ file doesn''t seem to exist...')
%     end
end

% datafile
if ismember('datafile',fieldnames(PHZ.lib))
    verifyChar(PHZ.lib.datafile,[name,'.lib.datafile'],verbose);
end

% files
if ismember('files',fieldnames(PHZ.lib))
    PHZ.lib.files = verifyCell(PHZ.lib.files,[name,'.lib.files'],verbose);
    PHZ.lib.files = checkAndFixColumn(PHZ.lib.files,[name,'.lib.files'],nargout,verbose);
%     if mod(size(PHZ.data,1) / length(PHZ.lib.files),1)
%         error('The number of filenames in PHZ.lib.files does not divide evenly into the number of trials in PHZ.data.')
%     end
end

%% history
PHZ.history = verifyCell(PHZ.history,[name,'.history'],verbose);
PHZ.history = checkAndFixColumn(PHZ.history,[name,'.history'],nargout,verbose);

end

function PHZ = resetSpec(PHZ,field)
for j = 1:length(PHZ.(field))
    PHZ.lib.spec.(field){j} = '';
end
end

function C = verifyNumeric(C,name,verbose)
if isnumeric(C), return, end
try
    if iscategorical(C),    C = cellstr(C);     end
    if iscell(C),           C = C{:};           end
    if ischar(C),           C = str2double(C);  end
    if verbose == 2, disp(['- Changed ',name,' to a double.']), end
catch, error([name,' should be a numeric array.'])
end
end

function C = verifyLogical(C,name,verbose)
if logical(C), return, end
try
    if iscategorical(C),    C = cellstr(C);     end
    if iscell(C),           C = C{:};           end
    if ischar(C),           C = str2double(C);  end
    if isnumeric(C),        C = logical(C);     end
    if verbose == 2, disp(['- Changed ',name,' to a logical']), end
catch, error([name,' should be a logical array.'])
end
end

function C = verifyChar(C,name,verbose)
if ischar(C), return, end
try
    if isnumeric(C), C = num2str(C); end
    if iscell(C), C = C{:}; end
    if verbose == 2, disp(['- Changed ',name,' to a string.']), end
catch, error([name,' should be a string.'])
end
end

function C = verifyCell(C,name,verbose)
if iscell(C), return, end
try
    if isnumeric(C),        C = {C};        end
    if ischar(C),           C = cellstr(C); end
    if iscategorical(C),    C = cellstr(C); end
    if verbose == 2, disp(['- Changed ',name,' to a cell array.']), end
catch, error([name,' should be a cell array.'])
end
end

function C = verifyCategorical(C,name,verbose)
if iscategorical(C), return, end

try
%     if isnumeric(C), C = num2str(C);     end
    if isnumeric(C)
        C = num2cell(C);
        C = cellfun(@num2str,C,'UniformOutput',false);
    end
    
    if ischar(C),    C = cellstr(C);     end
    if iscell(C),    C = categorical(C); end
    if verbose == 2, disp(['- Changed ',name,' to a categorical array.']), end
catch, error([name,' should be a categorical array.'])
end
end

function x = checkAndFixRow(x,name,noutargs,verbose)
if isempty(x), return, end
if ~isrow(x)
    if iscolumn(x)
        x = x';
        if noutargs == 0, warning([name,' should be changed from a column vector to a row vector.'])
        elseif verbose == 2, disp(['- Changed ',name,' from a column vector to a row vector.'])
        end
    else
        error(['Something is wrong with ',name,'.'])
    end
end
end

function x = checkAndFixColumn(x,name,noutargs,verbose)
if isempty(x), return, end
if ~iscolumn(x)
    if isrow(x)
        x = x';
        if noutargs == 0, warning([name,' should be changed from a row vector to a column vector.'])
        elseif verbose == 2, disp(['- Changed ',name,' from a row vector to a column vector.'])
        end
    else
        error(['Something is wrong with ',name,'.'])
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
names = fieldnames(PHZ);

% swap grouping and order vars, add tags (older than v0.7.7)
if ~ismember('tags',names) && ~ismember('lib',names) && ismember('spec',names)
    
    for i = {'participant','group','session','trials'}, field = i{1};
        PHZ.tags.(field) = PHZ.(field);
        PHZ.(field) = PHZ.spec.([field,'_order']);
        PHZ.spec.(field) = PHZ.spec.([field,'_spec']);
        PHZ.spec = rmfield(PHZ.spec,{[field,'_order'] [field,'_spec']});
    end
    PHZ.tags.region = PHZ.spec.region_order;
    PHZ.spec.region = PHZ.spec.region_spec;
    PHZ.spec = rmfield(PHZ.spec,{'region_order','region_spec'});
    PHZ = phz_history(PHZ,'Updated PHZ structure to v0.7.7.',verbose,0);
    
end

% move stuff to lib and create proc (older than v0.8)
if ~all(ismember({'proc','lib'},names)) && any(ismember({'rej','blsub','norm'},names))
    warning(['Preprocessing (rej, blsub, norm) must be undone ',...
        'before this file can be compatible with this version of ',...
        'PHZLAB.'])
    s = input('Should PHZLAB undo this preprocessing? [y/n]','s');
    switch lower(s)
        case 'n'
            disp('Aborting...'), error(' ')
        case 'y'
            PHZ = phz_norm(PHZ,0);
            PHZ = phz_blc(PHZ,0);
            PHZ = phz_rej(PHZ,0);
    end
end

updateTo8 = false;

for i = {'tags','spec'}, field = i{1};
    if ismember(field,names), updateTo8 = true;
        PHZ.lib.(field) = PHZ.(field);
        PHZ = rmfield(PHZ,field);
    end
end

if ismember('files',names), updateTo8 = true;
    PHZ.lib.files = PHZ.files;
    PHZ = rmfield(PHZ,'files');
end

if ismember('filename',fieldnames(PHZ.misc)), updateTo8 = true;
    PHZ.meta = PHZ.misc.filename;
    PHZ.misc = rmfield(PHZ.misc,'filename');
end

if updateTo8
    if ~ismember('proc',names) || ~isstruct(PHZ.proc)
        PHZ.proc = struct;
        PHZ = phz_history(PHZ,'Updated PHZ structure to v0.8.',verbose,0);
    end
end

% add 'condition' as a grouping variable (v0.8.4)
if ~ismember('condition',names)
    PHZ.condition = categorical;
    PHZ.meta.tags.condition = categorical;
    PHZ.meta.spec.condition = {};
end

% change meta/misc fields to lib/etc (v1.0)
if ismember('meta', names)
    PHZ.lib = PHZ.meta;
    PHZ = rmfield(PHZ, 'meta');
    PHZ = phz_history(PHZ, 'Renamed ''meta'' field to ''lib''.');
end
if ismember('misc', names)
    PHZ.etc = PHZ.misc;
    PHZ = rmfield(PHZ, 'misc');
    PHZ = phz_history(PHZ, 'Renamed ''misc'' field to ''etc''.');
end

end

function PHZ = orderPHZfields(PHZ)

% region structure
if isstruct(PHZ.region)
    
    % if spec order doesn't match the struct, recreate the struct
%     if ~strcmp(strjoin(fieldnames(PHZ.region)),strjoin(PHZ.lib.tags.region))
    [~,regionMatch] = ismember(PHZ.lib.tags.region,fieldnames(PHZ.region));
    if length(regionMatch) > length(fieldnames(PHZ.region)) || ...
        ~all(regionMatch == 1:length(fieldnames(PHZ.region)))
        rname = fieldnames(PHZ.region);
        for i = 1:length(PHZ.lib.tags.region)
            if i > length(rname)
                temp.(PHZ.lib.tags.region{i}) = [];
            else
                temp.(PHZ.lib.tags.region{i}) = PHZ.region.(rname{i});
            end
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
    'condition'
    'session'
    'trials'
    
    'region'
    'times'
    'freqs'
    
    'data'
    'units'
    'srate'
    
    'resp'
    'proc'
    'lib'
    'etc'
    'history'};
if ~all(ismember(fieldnames(PHZ),mainOrder))
    error(['Invalid fields present in PHZ structure. ',...
        'Use PHZ.etc to store miscellaneous data.'])
end
mainOrder = mainOrder(ismember(mainOrder,fieldnames(PHZ)));
PHZ = orderfields(PHZ,mainOrder);

% lib structure
% --------------
libOrder = {
    'tags'
    'spec'
    
    'filename'
    'datafile'
    'files'
    };
if ~all(ismember(fieldnames(PHZ.lib),libOrder))
    error(['Invalid fields present in PHZ.lib structure. ',...
        'Use PHZ.etc to store miscellaneous data.'])
end
libOrder = libOrder(ismember(libOrder,fieldnames(PHZ.lib)));
PHZ.lib = orderfields(PHZ.lib,libOrder);

% lib.tags structure
% -------------------
libTagsOrder = {
    'participant'
    'group'
    'condition'
    'session'
    'trials'
    'region'
    };
if ~all(ismember(fieldnames(PHZ.lib.tags),libTagsOrder))
    error(['Invalid fields present in PHZ.lib.tags structure. ',...
        'Use PHZ.etc to store miscellaneous data.'])
end
libTagsOrder = libTagsOrder(ismember(libTagsOrder,fieldnames(PHZ.lib.tags)));
PHZ.lib.tags = orderfields(PHZ.lib.tags,libTagsOrder);

% lib.spec structure
% -------------------
libSpecOrder = {
    'participant'
    'group'
    'condition'
    'session'
    'trials'
    'region'
    };
if ~all(ismember(fieldnames(PHZ.lib.spec),libSpecOrder))
    error(['Invalid fields present in PHZ.lib.spec structure. ',...
        'Use PHZ.etc to store miscellaneous data.'])
end
libSpecOrder = libSpecOrder(ismember(libSpecOrder,fieldnames(PHZ.lib.spec)));
PHZ.lib.spec = orderfields(PHZ.lib.spec,libSpecOrder);

end
