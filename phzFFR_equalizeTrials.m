%PHZFFR_EQUALIZETRIALS  Make the number of each type of trial the same
%   by randomly removing trials.
%
% USAGE
%   PHZ = phzFFR_equalizeTrials(PHZ)
%   PHZ = phzFFR_equalizeTrials(PHZ, grpVar)
%
% INPUT
%   grpVar    = [string] One of the grouping variables 'participant',
%               'group', 'condition', 'session', or 'trials'. If the
%               numbers of trials with each label is unequal, then trials
%               are removed at random (from the label(s) with more trials)
%               until all groups have an equal number of trials. This
%               function takes into account trials that are already marked
%               for rejection by other methods, and calls phz_subset to
%               mark the new rejections. Beware that using phz_reject,
%               phz_subset, or phz_review after using this option may
%               result in the number of trials becoming unequal again. If
%               grpVar is not given or is empty, the default is used.
%               Default 'trials'.
% 
% OUTPUT
%   PHZ.data and PHZ.lib.tags.(grpVar) = All trials which were marked 
%               for rejection are discarded using phz_discard, and
%               phz_subset is used to mark trials for rejection in order
%               to equalize the number of labels.

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

function PHZ = phzFFR_equalizeTrials(PHZ, grpVar, verbose)

if nargout == 0 && nargin == 0, help phzFFR_equalizeTrials, return, end
if nargin < 2, grpVar = 'trials'; end
if nargin < 3, verbose = true; end
if isempty(grpVar), return, end

% equalize number of trials in each label of a grouping variable
grpVars = {'participant','group','condition','session','trials'};
if ~ismember(grpVar, grpVars)
    disp('Invalid value for equalVar. Aborting...')
    return
end

% get previous discard marks, but don't discard them
[~, keep] = phz_discard(PHZ, false);
keepInd = find(keep); % 'line numbers' of kept trials
keepTags = PHZ.lib.tags.(grpVar)(keep);
tags = PHZ.(grpVar);

% get number of trials of each type, accounting for already-marked rejections
numTrials = nan(1,length(tags));
for i = 1:length(tags)
    numTrials(i) = length(keepTags(keepTags==tags(i)));
end

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
    % even more meta, i know, i know
    ind = true(length(keep), 1); % mark all trials for inclusion
    rminds = keepInd(~subKeep);
    ind(rminds) = false;

    str = ['Equalized the number of labels in ', grpVar, ' to be the same (', num2str(maxTrials), ').'];
    PHZ = phz_subset(PHZ, ind, str, verbose);
    
else
    disp('  All labels already have the same number of epochs.')

end

end
