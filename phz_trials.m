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
%               ['seq'|'alt'] If the value of 'labels' is a string, it adds
%               either sequentially-numbered ('seq') or alternating 
%               1's and 0's ('alt') trials.
%
%   'equal'   = [string] One of the grouping variables 'participant', 'group',
%               'condition', 'session', or 'trial'. If the numbers of trials
%               with each label is unequal, then trials are removed at random
%               (from the label(s) with more trials) until all groups have an
%               equal number of trials. Note that trials which were marked for
%               rejection will be discarded before performing equalization.
%               Then trials will be equalized using phz_subset.
% 
%   Note that labels are always added before equalizing.
%
% OUTPUT
%
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
equalVar = '';
verbose = true;

for i = 1:2:length(varargin)
    switch(lower(varargin{i}))
        case 'labels',              labels = varargin{i+1};
        case {'equal','equalVar'},  equalVar = varargin{i+1};
        case 'verbose',             verbose = varargin{i+1};
    end
end

totTrials = size(PHZ.data,1);

% add trial labels
if ~isempty(labels)
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
        
    else
        if ~isequal(length(labels),totTrials)
            error(['The number of labels (',num2str(length(labels)),...
                ') does not match the number of trials (',num2str(totTrials),').'])
        end
        
        PHZ.meta.tags.trials = labels;
        PHZ = phz_history(PHZ,'Adjusted trial labels.',verbose);
        
    end
end

% equalize number of trials in each label of a grouping variable
if ~isempty(equalVar)

    grpVars = {'participant','group','condition','session','trials'};
    if ~ismember(equalVar, grpVars)
        disp('Invalid value for equalVar. Aborting...')
        return
    end

    PHZ = phz_discard(PHZ,verbose);

    numTrials = nan(1,length(PHZ.trials));
    for i = 1:length(PHZ.trials)
        numTrials(i) = length(PHZ.meta.tags.(equalVar)(PHZ.meta.tags.(equalVar)==PHZ.trials(i)));
    end

    if sum(diff(numTrials))
        maxTrials = min(numTrials);
        ind = true(length(PHZ.meta.tags.(equalVar)), 1); % mark all trials for inclusion
        for i = 1:length(PHZ.trials)
            if numTrials(i) > maxTrials
                % get indices for this label
                labelInd = find(PHZ.meta.tags.(equalVar)==PHZ.trials(i));
                % randomly select indices to drop
                sel = randperm(length(labelInd), numTrials(i) - maxTrials);
                % get the label indices of the selected indices (it's pretty meta, i know)
                rminds = labelInd(sel);
                % mark those indices for removal
                ind(rminds) = false;
            end
        end
        str = ['Equalized the number of labels in ', equalVar, ' to be the same (', num2str(maxTrials), ').'];
        PHZ = phz_subset(PHZ, ind, str, verbose);
        
    else
        disp('All labels already have the same number of epochs.')
    end
end

end
