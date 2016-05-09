function PHZ = phzFeature_src(PHZ,varargin)
%PHZFEATURE_SRC  Stimulus-Response Correlation. Returns the maximum
%   cross-correlation value between each epoch and a vector specified
%   in PHZ.misc.stim.
% 
% USAGE
%   PHZ = phzFeature_src(PHZ)
%   PHZ = phzFeature_src(...,srcType)
%   PHZ = phzFeature_src(...,laglimits)
% 
% INPUT
%   PHZ       = PHZLAB data structure.
% 
%   srcType   = ['r'|'lag'] Specifies whether to return the correlation
%               coefficient ('r') or the lag time ('lag'). Default 'r'.
%   
%   laglimits = [numeric] Vector of length 2 specifying the time limits
%               within which to search for the highest correlation (i.e.,
%               [min max]). Default 8-12 ms [0.008 0.012].
%
% Written by Gabriel A. Nespoli 2016-04-05. Revised 2016-05-09.

% verify input
if isempty(PHZ.misc.stim), error('No stimulus waveform found in FFR.stim.'), end

% defaults
srcType = 'r';
laglimits = [];
meanType = 'add';

% user-defined
for i = 1:length(varargin)
    if isnumeric(varargin{i}), laglimits = varargin{i};
    elseif ischar(varargin{i}), srcType = varargin{i};
    end
end




% get xcorr
[r,lag] = ffrxcorr(PHZ.data,PHZ.misc.stim,PHZ.srate,laglimits);

switch srcType
    case {'r','corr'},  PHZ.data = r;
    case {'lag'},       PHZ.data = lag;
end

end

function [r,lag] = ffrxcorr(y,stim,Fs,varargin)
%FFRXCORR  Cross-correlation for frequency-following responses.
%   [R,LAG] = FFRXCORR(Y,STIM,FS) returns the correlation coefficient R and
%       lag LAG (in seconds) of the highest cross correlation between the
%       signals Y and STIM. FS is the sampling frequency. If Y is a matrix,
%       FFRXCORR operates columnwise.
%
%   R = FFRXCORR(...,LAGLIMITS) additionally specifies the time limits
%       within which to search for the highest correlation. LAGLIMITS is a 
%       two-column vector that specifies the minimum and maximum lag, in
%       seconds ([MINLAG MAXLAG]). Default 8-12 ms: [0.008 0.012].
%
%   See also FFRSHIFT.
%
% Written by Gabriel A. Nespoli 2015-03-25. Revised for PHZLAB 2016-05-09.

% default lags (based on Parbery-Clark, Skoe, & Kraus, 2009, J.Neurosci.)
minlag = 0.008*Fs; % in samples
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
r = nan(size(y,1),maxlag * 2 + 1);
lags = nan(size(r));

% cross correlation (restrict to MAXLAG here)
do_waitbar=0;
tic
for i = 1:size(y,1) % loop epochs
    [r(i,:),lags(i,:)] = xcorr(y(i,:),stim,maxlag,'coeff');
    
    % start waitbar if this is taking longer than 2 seconds
    switch do_waitbar
        case 0
            if toc>2
                h=waitbar(i/size(y,1),'SRC is taking some time...');
                do_waitbar=1;
            end
        case 1
            waitbar(i/size(y,1),h);
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