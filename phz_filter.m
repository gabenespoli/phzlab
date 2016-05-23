function PHZ = phz_filter(PHZ,cutoff,verbose)
%PHZ_FILTER  Apply a zero-phase shift filter to the data.
%
% USAGE  
%   PHZ = phz_filter(PHZ,CUTOFF)
%
% INPUT
%   PHZ       = PHZLAB data structure.
%   CUTOFF    = Cutoff frequencies for filtering in Hertz, in the form 
%               [locut hicut notch order]. Default is a 3rd-order
%               Butterworth filter.
%               
% OUTPUT
%   PHZ.data  = The filtered data.
%
% EXAMPLES
%   PHZ = phz_filter(PHZ,1)        >> 1 Hz high pass Butterworth filter
%   PHZ = phz_filter(PHZ,[0 10])   >> 10 Hz low pass Butterworth filter
%   PHZ = phz_filter(PHZ,[1 10])   >> 1-10 Hz band pass Butterworth filter
%   PHZ = phz_filter(PHZ,[0 0 60]) >> 59-61 Hz band stop Butterworth filter
%   PHZ = phz_filter(PHZ,[0 10 0 4]) >> 4th order 10 Hz low pass filter
%
% Written by Gabriel A. Nespoli 2014-03-18. Revised 2016-04-05.

if nargout == 0 && nargin == 0, help phz_filter, return, end
if isempty(cutoff), return, end
if nargin < 3, verbose = true; end

% defaults and input
filtertype = 'butter';
lp = 0;
nt = 0;
ord = 3;

% if input is a cell, specify butter vs cheby1 vs cheby2 vs bessel
if ~isnumeric(cutoff), error('Invalid input.'), end

% create cutoffs and order
hp = cutoff(1);
if length(cutoff) > 1, lp = cutoff(2); end
if length(cutoff) > 2, nt = cutoff(3); end
if length(cutoff) > 3, ord = cutoff(3); end

% create filter coeffs
hpB = []; hpA = []; lpB = []; lpA = []; nB = []; nA = [];

if hp ~= 0
    [hpB,hpA] = butter(ord,hp / (PHZ.srate / 2),'high');
    PHZ = phz_history(PHZ,['Butterworth highpass filter at ',num2str(hp),' Hz.'],verbose);
end

if lp ~= 0
    [lpB,lpA] = butter(ord,lp / (PHZ.srate / 2),'low');
    PHZ = phz_history(PHZ,['Butterworth lowpass filter at ',num2str(lp),' Hz.'],verbose);
end

if nt ~= 0
    [nB,nA] = butter(ord,[(nt - 1) / (PHZ.srate / 2) (nt + 1) / (PHZ.srate / 2)]);
    PHZ = phz_history(PHZ,['Butterworth bandstop filter at ',num2str(nt),' ± 1 Hz.'],verbose);
end

% filter data
if verbose, fprintf('Filtering... '), end
for i = 1:size(PHZ.data,1)
    % highpass
    if hp ~= 0, PHZ.data(i,:) = filtfilt(hpB,hpA,PHZ.data(i,:)); end
    
    % lowpass
    if lp ~= 0, PHZ.data(i,:) = filtfilt(lpB,lpA,PHZ.data(i,:)); end
    
    % notch
    if nt ~= 0, PHZ.data(i,:) = filtfilt(nB,nA,PHZ.data(i,:)); end
end
if verbose, fprintf('Done.\n'), end
end