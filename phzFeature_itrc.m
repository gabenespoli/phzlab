%PHZFEATURE_ITRC  Inter-trial Response Consitency (usually for ABR data).
%   Takes the average of half the trials and calculates the
%   cross-correlation with the average of the other half of trials. This
%   is repeated with many different random samplings. The mean of the
%   resulting correlations is returned as a measure of ITRC.
%
% Usage:
%   r = phzFeature_itrc(PHZ, reps, equalizeTrials)
%
% Input:
%   PHZ   = [struct] PHZLAB data structure.
%
%   reps  = [numeric] Number of times to repeat sampling. You can control
%           this by setting PHZ.lib.itrc.reps. Default 100.
%
%   equalizeTrials = [true|false] Make sure there are an equal number of
%           each trial type in each average. There must be exactly two
%           trial types for this to work. You can control this by setting
%           PHZ.lib.itrc.equalizeTrials. Default true.
%
% Output:
%   r       = [numeric] Average of a REPS number of cross-correlations.
%   
% Adapted from Tierney & Kraus, 2013, Journal of Neuroscience.

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

function r = phzFeature_itrc(PHZ, reps, equalizeTrials)

if nargin == 0 && nargout == 0, help phzFeature_itrc, return, end
if nargin < 2 || isempty(reps)
    if ismember('itrc', fieldnames(PHZ.lib)) && ...
        ismember('reps', fieldnames(PHZ.lib.itrc))
        reps = PHZ.lib.itrc.reps;
    else
        reps = 100;
    end
end
if nargin < 3 || isempty(equalizeTrials)
    if ismember('itrc', fieldnames(PHZ.lib)) && ...
        ismember('equalizeTrials', fieldnames(PHZ.lib.itrc))
        equalizeTrials = PHZ.lib.itrc.equalizeTrials;
    else
        equalizeTrials = true;
    end
end

% separate polarities if equalizing trials
if equalizeTrials 
    if length(PHZ.trials) == 2
        reg = PHZ.data(PHZ.lib.tags.trials == PHZ.trials(1), :);
        inv = PHZ.data(PHZ.lib.tags.trials == PHZ.trials(2), :);

    elseif length(PHZ.trials) == 1
        warning('There is only one trial type. Not equalizing polarities.')
        equalizeTrials = false;

    else
        error('There are an invalid number of trials for equalizing trials.')

    end
end

% create output container
r = nan(reps, 1);

w = '';
for i = 1:reps % loop for x random samplings
    w = phzUtil_progressbar(w, i / reps, ...
        'Calculating inter-trial response consistency...');

    if equalizeTrials

        % split each polarity into two randomly-selected samples
        [reg1, reg2] = get2randomSamples(reg);
        [inv1, inv2] = get2randomSamples(inv);

        % average waveforms in each sample
        sample1 = mean([reg1; inv1], 1);
        sample2 = mean([reg2; inv2], 1);

    else
        % split data into two randomly-selected samples and average them
        [sample1, sample2] = get2randomSamples(PHZ.data);
        sample1 = mean(sample1, 1);
        sample2 = mean(sample2, 1);

    end

    % cross-correlate the average waveforms at lag zero
    r(i) = xcorr(sample1, sample2, 0, 'coeff');

end

% average output containers
r = mean(r);

end

function [sample1, sample2] = get2randomSamples(data)
ind = randperm(size(data, 1));
sample1 = data(ind(1:floor(length(ind) / 2)), :);
sample2 = data(ind(ceil(1 + length(ind) / 2):end), :);
end
