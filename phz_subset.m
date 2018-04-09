%PHZ_SUBSET  Extract a subset of data from a PHZ structure, either by
%   specifying values of grouping variables, or by a logical vector.
%
% USAGE    
%   PHZ = phz_subset(PHZ, subset)
%   PHZ = phz_subset(PHZ, subset, message)
%
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
% 
%   subset    = [cell|logical|numeric|string] If cell array of length 2,
%               the first value is a field to restrict by (i.e.,
%               'participant', 'group', 'condition', 'session', 'trials')
%               and the second item is a number, string, or cell array of
%               strings with the value(s) of the field to include.
%           
%               If a logcial vector (i.e., 1's & 0's) the same length 
%               as the number of trials. Positions with a 1 are included,
%               positions with a 0 are excluded.
%
%               If a numeric vector, values cannot be below zero or 
%               greater than the number of trials. Values that are 
%               specified are included.
%
%               If a string, it is evaluated (using the eval function). It
%               must evaluate to one of the types above. If you are
%               subsetting by indices based on the resp field, use PHZ as
%               the variable name, since the string will be evaluated in
%               the context of this function, where the PHZ structure
%               variable name is PHZ. This is useful for controlling
%               different plots with PHZ.lib.plots.
%
%   message   = [string] Message to include in the PHZ.proc structure,
%               usually to log the reason for this subset.
%
% OUTPUT
%   PHZ.proc.subset.message = The string in MESSAGE.
%
%   PHZ.proc.subset.input = If cell array input, it is copied here 
%               for reference.
%
%   PHZ.proc.subset.keep = Logical vector the same length as the number
%               of trials, where 1's are included and 0's are not.
%
% EXAMPLES
%   phz_subset(PHZ,{'group','control'})  >> Only include data from the 
%                                           control group.
%   phz_subset(PHZ,{'session',1})        >> Only include session 1 data.
%   phz_subset(PHZ,PHZ.resp.q1_acc == 1) >> Only include data from trials
%                                           with an accurate response.
%   phz_subset(PHZ,PHZ.resp.q1_rt < 9)   >> Only include trials with
%                                           reaction time less than 9 s.
%   phz_subset(PHZ,'PHZ.resp.q1_rt < 9') >> As above, but using the string
%                                           syntax.

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

function PHZ = phz_subset(PHZ, subset, varargin)

if nargout == 0 && nargin == 0, help phz_subset, return, end
if isempty(subset), return, end

msg = '';
verbose = true;

if nargin > 2
    for i = 1:length(varargin)
        if isnumeric(varargin{i}) || islogical(varargin{i})
            verbose = varargin{i};
        elseif ischar(varargin{i})
            msg = varargin{i};
        end
    end
end

% evaulate string first
if ischar(subset)
    subset = eval(subset);
end

% get indices to keep
if islogical(subset) || ...
    (isnumeric(subset) ...
    && length(subset) == size(PHZ.data,1) ...
    && all(ismember(subset, [true false])))
    if length(subset) ~= size(PHZ.data,1)
        error('Logical vector must be the same length as the number of trials.')
    end
    ind = subset;
    subsetInput = '';
    subsetStr = 'Restricted data by indices.';

elseif isnumeric(subset)
    if any(subset <= 0) || any(subset > size(PHZ.data,1))
        error('Indices cannot be below zero or larger than the number of trials.')
    end
    ind = false(size(PHZ.data,1), 1);
    ind(subset) = true;
    subsetInput = '';
    subsetStr = 'Restricted data by indices.';

elseif iscell(subset)
    subsetInput = subset;
    [field, labels] = verifySubsetInput(PHZ, subset);

    ind = ismember(PHZ.lib.tags.(field), labels);

    if isnumeric(labels), labels = num2str(labels); end
    subsetStr = ['Restricted data to: ',field,' = ',...
        strjoin(cellstr(labels)),'.'];

else
    error('Invalid input.')
end

% add to history
subsetStr = [subsetStr, ' ', msg];
PHZ = phz_history(PHZ,subsetStr,verbose);
procName = phzUtil_getUniqueProcName(PHZ,'subset');
PHZ.proc.(procName).message = msg;
PHZ.proc.(procName).input = subsetInput;
PHZ.proc.(procName).keep = ind;
PHZ.proc.(procName).discarded = false;

end

function [field,labels] = verifySubsetInput(PHZ,subset)

if length(subset) ~= 2
    error('Cell array input must be of length 2.')
end

field = subset{1};
labels = subset{2};

if ~ischar(field)
    error('The first item in subset cell array input must be a string.')
end
if ~ismember(field, {'participant','group','condition','session','trials'})
    error(['The first item in subset cell array input must be a grouping ', ...
       'variable; i.e., participant, group, condition, session, or trials.'])
end

if isnumeric(labels)
    labels = num2str(labels);
end
if ischar(labels)
    labels = cellstr(labels);
end
if iscell(labels)
    labels = categorical(labels,categories(PHZ.(field)),'Ordinal',true);
end
end
