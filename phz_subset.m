%PHZ_SUBSET  Extract a subset of data from a PHZ or PHZS structure.
%
% USAGE    
%   PHZ = phz_subset(PHZ,subset)
%   PHZ = phz_subset(PHZ,ind)
%
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
% 
%   subset    = {'string' value} A cell array of length 2, where the first
%               value is a field to restrict by (i.e., 'participant', 
%               'group', 'condition', 'session', 'trials', or a PHZ.resp 
%               field) and the second item is a number, string, or cell
%               array of strings with the value(s) of the field to include.
% 
%   ind       = A logcial vector (i.e., 1's & 0's) the same length as the
%               number of trials. Positions with a 1 are included,
%               positions with a 0 are excluded.
%
% OUTPUT
%   The following fields are restricted to the specified subset:
%       PHZ.(participant/group/condition/session/trials)
%       PHZ.data
%       PHZ.resp.*
%       PHZ.meta.spec.*
%       PHZ.meta.tags.*
%
% EXAMPLES
%   phz_subset(PHZ,{'session' '1'}) >> Only include data from session 1.
%   phz_subset(PHZ,{'acc' '1'})     >> Only include data from trials with
%                                      an accurate response.
%   phz_subset(PHZ,PHZ.resp.q1_rt < 10) >> Only include data from trials
%                                      with a reaction time less than 10 s.

% Copyright (C) 2016 Gabriel A. Nespoli, gabenespoli@gmail.com
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

function PHZ = phz_subset(PHZ,subset,verbose)

if nargout == 0 && nargin == 0, help phz_subset, return, end
if isempty(subset), return, end
if nargin < 3, verbose = true; end

% get indices to keep
if isnumeric(subset) || islogical(subset)
    indall = subset;
    if ~ismember('rej',fieldnames(PHZ.proc)) && length(subset) == size(PHZ.data,1) % ok, no rej
        inddata = subset;
        indrej = [];
        
    elseif ismember('rej',fieldnames(PHZ.proc)) && length(subset) == length(PHZ.proc.rej.locs) + length(PHZ.proc.rej.data_locs)
        inddata = subset(PHZ.proc.rej.data_locs);
        indrej = subset(PHZ.proc.rej.locs);
    else
        error('Index vector is an invalid length.')
    end
    
    subsetStr = 'Restricted data by indices.';
    
elseif iscell(subset)
    [field,labels] = verifySubsetInput(PHZ,subset);
    
    if strcmp(field,'acc'), field = 'acc1'; end
    switch field
        case {'acc1','acc2','acc3','acc4','acc5'},
            indall = ismember(PHZ.resp.(['q',field(4),'_acc']),labels);
            if ismember('rej',fieldnames(PHZ.proc))
                indrej = indall(PHZ.proc.rej.locs);
                inddata = indall(PHZ.proc.rej.data_locs);
            else
                indrej = [];
                inddata = indall;
            end
            
        case {'participant','group','condition','session','trials'}
            inddata = ismember(PHZ.meta.tags.(field),labels);
            if ismember('rej',fieldnames(PHZ.proc))
                indrej = ismember(PHZ.proc.rej.(field),labels);
                indall = nan(length(PHZ.proc.rej.locs) + length(PHZ.proc.rej.data_locs),1);
                indall(inddata) = inddata;
                indall(indrej) = indrej;
            else
                indrej = [];
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

inddata = logical(inddata);
indall = logical(indall);
indrej = logical(indrej);

% adjust tags and grouping vars (also rej)
for i = {'participant','group','condition','session','trials'}, field = i{1};
    if ~isempty(PHZ.(field))
        PHZ.meta.tags.(field) = PHZ.meta.tags.(field)(inddata);
        if ismember('rej',fieldnames(PHZ.proc)), PHZ.proc.rej.(field) = PHZ.proc.rej.(field)(indrej); end
    end
end

% adjust grouping vars
for i = {'participant','group','condition','session','trials'}, field = i{1};
    if length(PHZ.(field)) ~= length(unique(PHZ.meta.tags.(field)))
        ind = ismember(PHZ.(field),unique(PHZ.meta.tags.(field)));
        PHZ.(field)      = PHZ.(field)(ind);
        PHZ.meta.spec.(field) = PHZ.meta.spec.(field)(ind);
    end
end

% adjust values in data, tags, grouping vars, and rej
PHZ.data = PHZ.data(inddata,:);
if ismember('rej',fieldnames(PHZ.proc))
    PHZ.proc.rej.data = PHZ.proc.rej.data(indrej,:);
end

% adjust values in PHZ.blc
if ismember('blc',fieldnames(PHZ.proc))
    PHZ.proc.blc.values = PHZ.proc.blc.values(indall);
end

% adjust values in PHZ.resp
for i = 1:5
    qx = ['q',num2str(i)];
    if ~isempty(PHZ.resp.(qx))
        PHZ.resp.(qx) = PHZ.resp.(qx)(indall);
        PHZ.resp.([qx,'_acc'])  = PHZ.resp.([qx,'_acc'])(indall);
        PHZ.resp.([qx,'_rt'])   = PHZ.resp.([qx,'_rt'])(indall);
    end
end

% add to history
PHZ = phz_history(PHZ,subsetStr,verbose);

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