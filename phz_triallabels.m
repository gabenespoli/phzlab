%PHZ_TRIALS  Add labels to trials/epochs.
%
% USAGE
%   PHZ = phz_triallabels(PHZ,labels)
%   PHZ = phz_triallabels(PHZ,labelType)
%   PHZ = phz_triallabels(PHZ,...,'Param1',Value1,etc.)
%
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
%
%   labels    = [numeric|cell of strings] Numeric or text labels for each
%               epoch. These labels will form the 'trials' grouping variable.
%               Must be the same length as the number of epochs.
%
%   labelType = ['seq'|'alt'] Adds either sequentially-numbered ('seq') or
%               alternating 1's and 2's ('alt') trials. Default is 'seq'.
% 
%   rminds    = [numeric|logical] Indices of labels to remove before
%               applying the labels. This is useful if epochs could not be
%               extracted or a trial was dropped, but you would like to
%               retain the original ordering (i.e., skipping a trial
%               label).

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

function PHZ = phz_triallabels(PHZ,labels,varargin)

if nargout == 0 && nargin == 0, help phz_triallabels, return, end

if nargin < 2, labels = 'seq'; end

rminds = [];
verbose = true;

for i = 1:2:length(varargin)
    switch(lower(varargin{i}))
        case 'rminds',      rminds = varargin{i+1};
        case 'verbose',     verbose = varargin{i+1};
    end
end

numTrials = size(PHZ.data,1) + length(rminds);

if ischar(labels)
    switch lower(labels)
        case {'seq','sequential'}
            PHZ.meta.tags.trials = 1:numTrials;
            PHZ.meta.tags.trials(rminds) = [];
            PHZ = phz_history(PHZ,'Added sequential trial labels.',verbose);
        
        case {'alt','alternating'}
            if ~mod(numTrials,2) % (if PHZ.trials is even)
                PHZ.meta.tags.trials = repmat([1;2],[numTrials/2,1]);
            else % (PHZ.trials is odd)
                PHZ.meta.tags.trials = [repmat([1;2],[(numTrials/2)-0.5,1]); 1];
            end
            
            PHZ.meta.tags.trials(rminds) = [];
            PHZ = phz_history(PHZ,'Added alternating trial labels.',verbose);        
            
        otherwise
            error(['Unknown trial labels type ''',labels,'''.'])
    end
    
else
    if ~isequal(length(labels),numTrials)
        error(['The number of labels (',num2str(length(labels)),...
            ') does not match the number of trials (',num2str(numTrials),').'])
    end
    
    PHZ.meta.tags.trials = labels;
    PHZ.meta.tags.trials(rminds) = [];
    PHZ = phz_history(PHZ,'Added custom trial labels.',verbose);
    
end

end