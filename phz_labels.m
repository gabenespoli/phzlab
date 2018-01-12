%PHZ_LABELS  Add labels (tags) to trials.
%
% USAGE
%   PHZ = phz_labels(PHZ, labels)
%
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
%
%   'labels'  = [numeric|cell of strings] Numeric or text labels for each
%               epoch. These labels will form the 'trials' grouping variable.
%               Must be the same length as the number of epochs.
%
%               ['seq'|'alt'] If the value of 'labels' is a string, it adds
%               either sequentially-numbered ('seq') or alternating 
%               1's and 0's ('alt') trials.
%
% OUTPUT
%   PHZ.meta.tags.trials = The specified trial labels.
%

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

function PHZ = phz_labels(PHZ, labels, verbose)

if nargout == 0 && nargin == 0, help phz_labels, return, end
if nargin < 2 || isempty(labels), return, end
if nargin < 3, verbose = true; end

totTrials = size(PHZ.data,1);

if ischar(labels)

    switch lower(labels)

        case {'seq','sequential'}
            PHZ.meta.tags.trials = 1:totTrials;
            PHZ = phz_history(PHZ,'Added sequential trial labels (i.e., 1, 2, 3, etc.).',verbose);
        
        case {'alt','alternating'}
            if ~mod(totTrials,2) % (if PHZ.trials is even)
                PHZ.meta.tags.trials = repmat([1;0],[totTrials/2,1]);
            else % (PHZ.trials is odd)
                PHZ.meta.tags.trials = [repmat([1;0],[(totTrials/2)-0.5,1]); 1];
            end
            
            PHZ = phz_history(PHZ,'Added alternating trial labels (i.e., 0, 1, 0, 1, etc.).',verbose);        
            
        otherwise
            error(['Unknown trial labels type ''',labels,'''.'])

    end
    
elseif isnumeric(labels) || iscell(labels) || iscategorical(labels)

    if ~isequal(length(labels),totTrials)
        error(['The number of labels (',num2str(length(labels)),...
            ') does not match the number of trials (',num2str(totTrials),').'])
    end
    
    PHZ.meta.tags.trials = labels;
    PHZ = phz_history(PHZ,'Adjusted trial labels.',verbose);
    
else
    error('Invalid input.')

end

end
