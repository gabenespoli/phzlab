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
%               equal number of trials. This function takes into account 
%               trials that are already marked for rejection by other methods,
%               and calls phz_subset to mark the new rejections. Beware that
%               using phz_reject, phz_subset, or phz_review after using this
%               option may result in the number of trials becoming unequal 
%               again.
% 
%   Note that labels are always added before equalizing.
%
% OUTPUT
%   PHZ.meta.tags.trials = If 'labels' is used, this field is filled with
%               the specified trial labels.
%
%   PHZ.data and PHZ.meta.tags.() = If 'equal' is used, all trials which
%               were marked for rejection are discarded using phz_discard,
%               and phz_subset is used to mark trials for rejection in order
%               to equalize the number of labels.

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

function PHZ = phz_trials(PHZ,varargin)

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

    [~, keep] = phz_discard(PHZ, false); % keep is a logical
    keepInd = find(keep); % 'line numbers' of kept trials

    keepTags = PHZ.meta.tags.(equalVar)(keep);
    tags = PHZ.(equalVar);

    % get number of trials of each type, accounting for already-marked rejections
    numTrials = nan(1,length(tags));
    for i = 1:length(tags)
        numTrials(i) = length(keepTags(keepTags==tags(i)));
    end
    disp(numTrials)

    if sum(diff(numTrials))
        maxTrials = min(numTrials);
        subKeep = true(length(keepTags), 1); % mark all trials for inclusion
        for i = 1:length(tags)
            if numTrials(i) > maxTrials
                % get indices for this label
                labelInd = find(keepTags==tags(i)); % indices of this label in keepTags / subKeep
                % randomly select indices to drop
                sel = randperm(length(labelInd), numTrials(i) - maxTrials);
                % get the label indices of the selected indices (it's pretty meta, i know)
                rminds = labelInd(sel);
                % mark those indices for removal
                subKeep(rminds) = false;
            end
        end

        % 'subKeep' is only the length of the subset of trials not marked for rejection
        % now we have to convert these indices into 'general' indices
        ind = true(length(keep), 1); % mark all trials for inclusion
        rminds = keepInd(~subKeep);
        ind(rminds) = false;

        str = ['Equalized the number of labels in ', equalVar, ' to be the same (', num2str(maxTrials), ').'];
        PHZ = phz_subset(PHZ, ind, str, verbose);
        
    else
        disp('  All labels already have the same number of epochs.')
    end
end

end
