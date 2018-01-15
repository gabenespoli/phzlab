%PHZFEATURE_ITRC  Inter-trial Response Consitency (usually for FFR data)
%   R = FFR_ITRC(FFR) takes the average of half the trials and calculates
%       the cross-correlation with the average of the other half of trials.
%       This is repeated 100 times (default) with different random
%       samplings. The mean of the resulting correlations is returned as a
%       measure of ITRC. If there are two polarities specified in FFR.pols,
%       FFR_ITRC ensures that each random sample has an equal number of
%       each polarity.
%
%   R = FFR_ITRC(FFR,REPS) additionally specifies the number of random
%       samplings (default 100).
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

function r = phzFeature_itrc(FFR,varargin)

% defaults
reps = 100;

% check input arguments
if nargin == 0 && nargout == 0, help phzFeature_itrc, return, end
if nargin > 1
    if ~isempty(varargin{1}) && ~isnan(varargin{1})
        reps = varargin{1};
    end
end

% if 2 polarities, separate polarities
p = unique(FFR.pols);
if length(p) == 2
    pol1=FFR.data(FFR.pols == p(1),:);
    pol2=FFR.data(FFR.pols == p(2),:);
elseif length(p) == 1
    pol1=FFR.data;
else
    error('There are an unusual number of polarities. Cannot calculate ITRC.')
end

% create output container
r = nan(reps,1);

% create waitbar
h = waitbar(0,['Calculating inter-trial response consistency (',num2str(FFR.trials),' trials)...']);

for i = 1:reps % loop for x random samplings
    switch length(p)
        case 2
            % split each polarity into two randomly-selected samples
            [sample1A,sample1B] = get2randomSamples(pol1);
            [sample2A,sample2B] = get2randomSamples(pol2);
            
            % average waveforms in each sample
            sample1 = mean([sample1A; sample2A],1);
            sample2 = mean([sample1B; sample2B],1);
            
        case {0,1}
            [sample1,sample2] = get2randomSamples(FFR.data);
            sample1 = mean(sample1,1);
            sample2 = mean(sample2,1);
            
        otherwise
            error('More than 2 polarities specified.')
    end
    
    % cross-correlate the average waveforms at lag zero
    C = xcorr(sample1,sample2,0,'coeff');
    
    % fill output container
    r(i) = C;
    
    % update waitbar
    waitbar(i/reps,h)
    
end

% average output containers
r = mean(r);

% close waitbar
close(h)

end

function [sample1,sample2] = get2randomSamples(data)
ind = randperm(size(data,1));
sample1 = data(ind(1:floor(length(ind)/2)),:);
sample2 = data(ind(ceil(1+length(ind)/2):end),:);
end
