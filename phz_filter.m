function PHZ = phz_filter(PHZ,cutoff,varargin)
%PHZ_FILTER  Apply a Butterworth or smoothing filter to the data.
%
% usage:    PHZ = phz_filter(PHZ,CUTOFF)
%           PHZ = phz_filter(PHZ,CUTOFF,'Param1','Value1',etc.)
%
% inputs:   PHZ       = PHZLAB data structure.
%           CUTOFF    = Cutoff frequencies for filtering in Hertz, in the
%                       form [locut hicut notch]. Default is a Butterworth
%                       filter.
%           'ord'     = Filter order. Default 3.
%           'verbose' = Print history in command window. Default true.
% 
% outputs:  PHZ.data  = The filtered data.
%
% examples:
%   PHZ = phz_filter(PHZ,1)        >> 1 Hz high pass Butterworth filter
%   PHZ = phz_filter(PHZ,[0 10])   >> 10 Hz low pass Butterworth filter
%   PHZ = phz_filter(PHZ,[1 10])   >> 1-10 Hz band pass Butterworth filter
%   PHZ = phz_filter(PHZ,[0 0 60]) >> 59-61 Hz band stop Butterworth filter
%
% Written by Gabriel A. Nespoli 2014-03-18. Revised 2016-03-31.

if nargout == 0 && nargin == 0, help phz_filter, return, end
if isempty(cutoff), return, end

% defaults and input
filtertype = 'butter';
ord = 3;
verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case {'ord','order'},       ord = varargin{i+1};
        case 'verbose',             verbose = varargin{i+1};
    end
end


% if input is a cell, specify butter vs cheby1 vs cheby2 vs bessel


if isnumeric(cutoff) % Butterworth Filtering

    % create filter coeffs
    hpB = []; hpA = []; lpB = []; lpA = []; nB = []; nA = [];
    
    if cutoff(1) ~= 0
        [hpB,hpA] = butter(ord,cutoff(1) / (PHZ.srate / 2),'high');
        PHZ = phzUtil_history(PHZ,['Butterworth highpass filter at ',num2str(cutoff(1)),' Hz.'],verbose);
    end
    
    if cutoff(2) ~= 0
        [lpB,lpA] = butter(ord,cutoff(2) / (PHZ.srate / 2),'low');
        PHZ = phzUtil_history(PHZ,['Butterworth lowpass filter at ',num2str(cutoff(2)),' Hz.'],verbose);
    end
    
    if cutoff(3) ~= 0
        [nB,nA] = butter(ord,[(cutoff(3) - 1) / (PHZ.srate / 2) (cutoff(3) + 1) / (PHZ.srate / 2)]);
        PHZ = phzUtil_history(PHZ,['Butterworth bandstop filter at ',num2str(cutoff(3)),' ± 1 Hz.'],verbose);
        
    end
    
    % filter data
    for i = 1:size(PHZ.data,1)
        % highpass
        if cutoff(1) ~= 0, PHZ.data(i,:) = filtfilt(hpB,hpA,PHZ.data(i,:)); end
        
        % lowpass
        if cutoff(2) ~= 0, PHZ.data(i,:) = filtfilt(lpB,lpA,PHZ.data(i,:)); end
        
        % notch
        if cutoff(3) ~= 0, PHZ.data(i,:) = filtfilt(nB,nA,PHZ.data(i,:)); end
    end
    
else error('Invalid input.')
end

end