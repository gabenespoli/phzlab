function PHZ = phz_subset(PHZ,subset,verbose)
%PHZ_SUBSET  Extract a subset of data from a PHZ or PHZS structure.
%
% usage:    PHZ = phz_subset(PHZ,SUBSET)
%           PHZ = phz_subset(PHZ,IND)
%
% inputs:   PHZ = PHZLAB data structure.
%           SUBSET = A cell array of length 2, where the first value is a
%                 field to restrict by (i.e., 'participant', 'group',
%                 'session', 'trials', or a PHZ.resp field) and the second
%                 item is a number, string, or cell array of strings with
%                 the value(s) of the field to include.
%           IND = A logcial vector (i.e., 1's & 0's) the same length as
%                 the number of trials. Positions with a 1 are included,
%                 positions with a 0 are excluded.
%
% outputs:  The following fields are restricted to the specified subset:
%               PHZ.(participant/group/session/trials)
%               PHZ.data
%               PHZ.resp.*
%               PHZ.spec.*
%               PHZ.tags.(participant/group/session/trials)
%
% examples:
%   phz_subset(PHZ,{'session' '1'}) >> Only include data from session 1.
%   phz_subset(PHZ,{'acc' '1'})     >> Only include data from trials with
%                                      an accurate response.
%   phz_subset(PHZ,PHZ.resp.q1_rt < 10) >> Only include data from trials
%                                      with a reaction time less than 10 s.
%
% Written by Gabriel A. Nespoli 2016-03-08. Revised 2016-04-01.

if nargout == 0 && nargin == 0, help phz_subset, return, end
if isempty(subset), return, end
if nargin < 3, verbose = true; end

% get indices to keep
if isnumeric(subset) || islogical(subset)
    indall = subset;
    if ~ismember('rej',fieldnames(PHZ)) && length(subset) == size(PHZ.data,1) % ok, no rej
        inddata = subset;
        indrej = [];
        
    elseif ismember('rej',fieldnames(PHZ)) && length(subset) == length(PHZ.rej.locs) + length(PHZ.rej.data_locs)
        inddata = subset(PHZ.rej.data_locs);
        indrej = subset(PHZ.rej.locs);
        
    else error('Index vector is an invalid length.')
    end
    
    subsetStr = 'Restricted data by indices.';
    
elseif iscell(subset)
    [field,labels] = verifySubsetInput(PHZ,subset);
    
    if strcmp(field,'acc'), field = 'acc1'; end
    switch field
        case {'acc1','acc2','acc3','acc4','acc5'},
            indall = ismember(PHZ.resp.(['q',field(4),'_acc']),labels);
            if ismember('rej',fieldnames(PHZ))
                indrej = indall(PHZ.rej.locs);
                inddata = indall(PHZ.rej.data_locs);
            else indrej = [];
                inddata = indall;
            end
            
        case {'participant','group','session','trials'}
            inddata = ismember(PHZ.tags.(field),labels);
            if ismember('rej',fieldnames(PHZ))
                indrej = ismember(PHZ.rej.(field),labels);
                indall = nan(length(PHZ.rej.locs) + length(PHZ.rej.data_locs),1);
                indall(inddata) = inddata;
                indall(indrej) = indrej;
                
            else indrej = [];
                indall = inddata;
            end
            
        otherwise
            error('Invalid field by which to restrict.')
    end
    
    if isnumeric(labels), labels = num2str(labels); end
    subsetStr = ['Restricted data to: ',field,' = ',...
        strjoin(cellstr(labels)),'.'];
    
else error('Invalid input.')
end



% adjust tags and grouping vars (also rej)
for i = {'participant','group','session','trials'}, field = i{1};
    PHZ.tags.(field) = PHZ.tags.(field)(inddata);
    if ismember('rej',fieldnames(PHZ)), PHZ.rej.(field) = PHZ.rej.(field)(indrej); end
end

% adjust grouping vars
for i = {'participant','group','session','trials'}, field = i{1};
    
    if length(PHZ.(field)) ~= length(unique(PHZ.tags.(field)))
        ind = ismember(PHZ.(field),unique(PHZ.tags.(field)));
        PHZ.(field)      = PHZ.(field)(ind);
        PHZ.spec.(field) = PHZ.spec.(field)(ind);
    end
end

% adjust values in data, tags, grouping vars, and rej
PHZ.data = PHZ.data(inddata,:);
if ismember('rej',fieldnames(PHZ))
    PHZ.rej.data = PHZ.rej.data(indrej,:);
end

% adjust values in PHZ.blc
if ismember('blc',fieldnames(PHZ))
    PHZ.blc.values = PHZ.blc.values(indall);
end

% adjust values in PHZ.resp
for i = 1:5
    qx = ['q',num2str(i)];
    if ~isempty(PHZ.resp.(qx))
        PHZ.resp.(qx) = PHZ.resp.(qx){indall};
        PHZ.resp.([qx,'_acc'])  = PHZ.resp.([qx,'_acc'])(indall);
        PHZ.resp.([qx,'_rt'])   = PHZ.resp.([qx,'_rt'])(indall);
    end
end

% add to history
PHZ = phzUtil_history(PHZ,subsetStr,verbose);

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