%PHZFEATURE_SRC  Stimulus-Response Correlation. Returns the maximum
%   cross-correlation value between each row of the data matrix and the
%   stim vector.
% 
% USAGE
%   [r,lag] = phzFeature_src(data,stim,srate)
%   [r,lag] = phzFeature_src(...,laglimits)
% 
% INPUT
%   data      = [numeric] Each row of data is a single time-series.
% 
%   stim      = [numeric] Vector specifying the stimulus time-series.
% 
%   srate     = [numeric] Sampling frequency of data and stim.
%   
%   laglimits = [numeric] Vector of length 2 specifying the time limits
%               within which to search for the highest correlation (i.e.,
%               [min max]). Default 8-12 ms [0.008 0.012]. In seconds.
%               Note: setting laglimits to empty ([]) will use the default.
%
% OUTPUT
%   r         = [numeric] Column vector of the maximum correlation 
%               coefficient for each row of data.
% 
%   lag       = [numeric] Latency of the maximum correlation coefficient.
%               In seconds.

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

function [r,lag] = phzFeature_src(data,stim,Fs,varargin)
if nargin == 0 && nargout == 0, help phzFeature_src, return, end

% default lags (based on Parbery-Clark, Skoe, & Kraus, 2009, J.Neurosci.)
minlag = 0.008*Fs; % convert to samples
maxlag = 0.012*Fs;

% user-defined lags
if nargin > 3
    if isempty(varargin{1}) % do nothing; use default LAGLIMITS
        
    elseif length(varargin{1}) == 2
        minlag = varargin{1}(1) * Fs;
        maxlag = varargin{1}(2) * Fs;
    else
        warning('Invalid LAGLIMITS. Using default [0.008 0.012].')
    end
end

% check for non-integer window variables
if maxlag/round(maxlag) ~= 1, warning('Rounding MAXLAG...'), maxlag = round(maxlag); end
if minlag/round(minlag) ~= 1, warning('Rounding MINLAG...'), minlag = round(minlag); end

% create container variables
r = nan(size(data,1),maxlag * 2 + 1);
lags = nan(size(r));

% cross correlation (restrict to MAXLAG here)
do_waitbar=0;
tic
for i = 1:size(data,1) % loop epochs
    [r(i,:),lags(i,:)] = xcorr(data(i,:),stim,maxlag,'coeff');
    
    % start waitbar if this is taking longer than 2 seconds
    switch do_waitbar
        case 0
            if toc>2
                h=waitbar(i/size(data,1),'SRC is taking some time...');
                do_waitbar=1;
            end
        case 1
            waitbar(i/size(data,1),h);
    end
end
if do_waitbar, close(h), end

% only consider positive lags (restrict to MINLAG here)
startind = floor(size(r,2) / 2) + minlag;
r = r(:,startind:end);
lags = lags(:,startind:end) / Fs; % (convert to seconds)

% find maximum correlation and its index
[r,ind] = max(r,[],2);

% find lag value
lag = lags(ind);

end
