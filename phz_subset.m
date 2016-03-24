function PHZ = phz_subset(PHZ,subset,varargin)
%PHZ_SUBSET  Extract a subset of data from a PHZ or PHZS structure.
% 
% PHZ = PHZ_SUBSET(PHZ,VAL), VAL is a cell array of length 2, where the 
%   first item is a field to restrict by (i.e., 'participant', 'group',
%   'session', 'trials', or a PHZ.resp field) and the second item is a 
%   number, string, or cell array of strings with the value(s) of the 
%   field to include.
%
% Written by Gabriel A. Nespoli 2016-03-08. Revised 2016-03-22.

if nargout == 0 && nargin == 0, help phz_subset, return, end

% verify input
if isempty(subset), return, end
[field,labels] = verifySubsetInput(PHZ,subset);
if nargin > 2, verbose = varargin{1}; else verbose = true; end

% unreject all trials
if ismember('rej',fieldnames(PHZ))
    threshold = PHZ.rej.threshold;
    PHZ = phz_rej(PHZ,[],verbose);
else threshold = [];
end

% get indices of items to keep
if strcmp(field,'acc'), field = 'acc1'; end
switch field
    case {'acc1','acc2','acc3','acc4','acc5'}, 
        fieldData = PHZ.resp.(['q',field(4),'_acc']);
    case {'participant','group','session','trials'}
        fieldData = PHZ.(field);
    otherwise
        error('Problem with first item in SUBSET.')
end

% subset = subset{2};
% if ~iscell(subset), subset = {subset}; end

ind = [];
for i = 1:length(labels)
    ind = [ind; find(fieldData == labels(i))];
end

% adjust values in PHZ.data and grouping variables
if length(PHZ.participant) > 1, PHZ.participant = PHZ.participant(ind); end
if length(PHZ.group) > 1,       PHZ.group = PHZ.group(ind); end
if length(PHZ.session) > 1,     PHZ.session = PHZ.session(ind); end
if length(PHZ.trials) > 1,      PHZ.trials = PHZ.trials(ind); end

PHZ.data = PHZ.data(ind,:);

% adjust values in PHZ.blc
if ismember('blc',fieldnames(PHZ))
    PHZ.blc.values = PHZ.blc.values(ind);
end

% adjust values in PHZ.resp
for i = 1:5
    qx = ['q',num2str(i)];
    if ~isempty(PHZ.resp.(qx))
        PHZ.resp.(qx) = PHZ.resp.(qx){ind};
        PHZ.resp.([qx,'_acc'])  = PHZ.resp.([qx,'_acc'])(ind);
        PHZ.resp.([qx,'_rt'])   = PHZ.resp.([qx,'_rt'])(ind);
    end
end

% fix lengths of spec
for i = {'participant','group','session','trials'}
    vals = unique(PHZ.(i{1}));
    if length(PHZ.spec.([i{1},'_order'])) ~= length(vals)
        ind = [];
        for j = 1:length(vals)
            [~,temp] = ismember(vals(j),PHZ.spec.([i{1},'_order']));
            ind = [ind; temp];
        end
        PHZ.spec.([i{1},'_order']) = PHZ.spec.([i{1},'_order'])(ind);
        PHZ.spec.([i{1},'_spec'])  = PHZ.spec.([i{1},'_spec'])(ind);
    end
end

if isnumeric(labels), labels = num2str(labels); end
PHZ = phzUtil_history(PHZ,['Restricted data by the ',...
    strjoin(cellstr(labels)),' labels of the ',field,' field.'],verbose);

if threshold, PHZ = phz_reject(PHZ,threshold,verbose); end

end

function [field,labels] = verifySubsetInput(PHZ,subset)

if ~iscell(subset), error('SUBSET must be a cell array.'), end

if length(subset) ~= 2, error('SUBSET must be of length 2.'), end

field = subset{1};
labels = subset{2};

if ~ischar(field), error('The first item in SUBSET must be a string.'), end

if ischar(labels), labels = cellstr(labels); end
if iscell(labels), labels = categorical(labels,categories(PHZ.(field)),'Ordinal',true); end

end