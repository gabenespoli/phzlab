%PHZ_TRIALS  Manage labels to trials/epochs.
%
% USAGE
%   PHZ = phz_trials(PHZ)
%   PHZ = phz_trials(PHZ,'Param1',Value1,etc.)
%
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
%
%   'labels'  = [numeric|cell of strings] Numeric or text labels for each
%               epoch. These labels will form the 'trials' grouping variable.
%               Must be the same length as the number of epochs.
%
%             = ['seq'|'alt'] If the value of 'labels' is a string, it adds
%               either sequentially-numbered ('seq') or alternating 
%               1's and 0's ('alt') trials.
%
%   'equal'   = [string] One of the grouping variables 'participant', 'group',
%               'condition', 'session', or 'trial'. If the numbers of trials
%               with each label is unequal, then trials are removed at random
%               (from the label(s) with more trials) until all groups have an
%               equal number of trials.
% 
%   'plot'    = [0|1] Enter 1 (true) to draw a bar plot showing the number of 
%               trials assigned to each label of the given grouping variable.
%               If phz_trials is called with one input (PHZ), then do_plot
%               defaults to 1 (draw the plot). If other input is given, it
%               defatuls to 0 (don't draw the plot).
%
%   Note that processing is always done in this order: labels, equal, plot.
%
% OUTPUT
%
%
% EXAMPLES
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

function PHZ = phz_trial(PHZ,varargin)

if nargout == 0 && nargin == 0, help phz_trials, return, end

labels = [];
equal = '';
if nargin == 1, do_plot = true;
else,           do_plot = false;
end
verbose = true;

for i = 1:2:length(varargin)
    switch(lower(varargin{i}))
        case 'labels',              labels = varargin{i+1};
        case {'equal','do_equal'},  do_equal = varargin{i+1};
        case {'plot','do_plot'},    do_plot = varargin{i+1};
        case 'verbose',             verbose = varargin{i+1};
    end
end

numTrials = size(PHZ.data,1);

% add trial labels
if ~isempty(labels)
    if ischar(labels)
        switch lower(labels)
            case {'seq','sequential'}
                PHZ.meta.tags.trials = 1:numTrials;
                PHZ = phz_history(PHZ,'Added sequential trial labels (i.e., 1, 2, 3, etc.).',verbose);
            
            case {'alt','alternating'}
                if ~mod(numTrials,2) % (if PHZ.trials is even)
                    PHZ.meta.tags.trials = repmat([1;0],[numTrials/2,1]);
                else % (PHZ.trials is odd)
                    PHZ.meta.tags.trials = [repmat([1;0],[(numTrials/2)-0.5,1]); 1];
                end
                
                PHZ = phz_history(PHZ,'Added alternating trial labels (i.e., 0, 1, 0, 1, etc.).',verbose);        
                
            otherwise
                error(['Unknown trial labels type ''',labels,'''.'])
        end
        
    else
        if ~isequal(length(labels),numTrials)
            error(['The number of labels (',num2str(length(labels)),...
                ') does not match the number of trials (',num2str(numTrials),').'])
        end
        
        PHZ.meta.tags.trials = labels;
        PHZ = phz_history(PHZ,'Added or changed trial labels.',verbose);
        
    end
end

% equalize number of trials in each label of a grouping variable

% plot - bar plot showing number of trials in each label of a grouping variable

end
