%PHZ_FILTER  Apply a zero-phase shift filter to the data.
%
% USAGE  
%   PHZ = phz_filter(PHZ,cutoff)
%   PHZ = phz_filter(PHZ,cutoff,'Param1',Value1,etc.)
%
% INPUT
%   PHZ           = [struct] PHZLAB data structure.
% 
%   cutoff        = [numeric] Cutoff frequencies for filtering in Hertz, 
%                   in the form [hipass lopass notch]. Notch filters are a 
%                   freq - 1 to freq + 1 band stop filter.
% 
%   'order'       = [numeric] Specifies the filter order. Default 3.
% 
%   'zerophase'   = [0|1] Specifies whether to use zero-phase filtering
%                   (1; filtfilt.m) or not (0; filter.m). Default 0.
%               
% OUTPUT
%   PHZ.data  = The filtered data.
%
% EXAMPLES
%   PHZ = phz_filter(PHZ,1)        >> 1 Hz high pass Butterworth filter
%   PHZ = phz_filter(PHZ,[0 10])   >> 10 Hz low pass Butterworth filter
%   PHZ = phz_filter(PHZ,[1 10])   >> 1-10 Hz band pass Butterworth filter
%   PHZ = phz_filter(PHZ,[0 0 60]) >> 59-61 Hz band stop Butterworth filter
% 
% TOOLBOX DEPENDENCIES
%   Signal Processing Toolbox
%     - butter.m
%     - filtfilt.m

% potential future funtionality
% -----------------------------
% if input is a cell, specify butter vs cheby1 vs cheby2 vs bessel
%   'type'        = [string] Specifies the type of filter used. Default 
%                   'butter' for Butterworth filter.

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

function PHZ = phz_filter(PHZ,cutoff,varargin)

if nargout == 0 && nargin == 0, help phz_filter, return, end

if isempty(cutoff), return, end
if ~isnumeric(cutoff), error('Invalid input.'), end
hipass = cutoff(1);
if length(cutoff) < 2, lopass = 0; else lopass = cutoff(2); end
if length(cutoff) < 3, notch = 0; else notch = cutoff(3); end

filterType = 'butter';
filterOrder = 3;
do_zeroPhase = true;
verbose = true;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'type',        filterType = varargin{i+1};
        case 'order',       filterOrder = varargin{i+1};
        case 'zerophase',   do_zeroPhase = varargin{i+1};
        case 'verbose',     verbose = varargin{i+1};
        otherwise, warning(['Unknown parameter ''',varargin{i},'''.'])
    end
end

% create filter coeffs
hpB = []; hpA = []; lpB = []; lpA = []; nB = []; nA = [];

if hipass ~= 0
    [hpB,hpA] = butter(filterOrder,hipass / (PHZ.srate / 2),'high');
    PHZ = phz_history(PHZ,['Butterworth highpass filter at ',num2str(hipass),' Hz.'],verbose);
end

if lopass ~= 0
    [lpB,lpA] = butter(filterOrder,lopass / (PHZ.srate / 2),'low');
    PHZ = phz_history(PHZ,['Butterworth lowpass filter at ',num2str(lopass),' Hz.'],verbose);
end

if notch ~= 0
    [nB,nA] = butter(filterOrder,[(notch - 1) / (PHZ.srate / 2) (notch + 1) / (PHZ.srate / 2)]);
    PHZ = phz_history(PHZ,['Butterworth bandstop filter at ',num2str(notch),' ± 1 Hz.'],verbose);
end

% filter data
if verbose, fprintf('Filtering... '), end
for i = 1:size(PHZ.data,1)
    
    if do_zeroPhase
        
        if hipass ~= 0, PHZ.data(i,:) = filtfilt(hpB,hpA,PHZ.data(i,:)); end
        if lopass ~= 0, PHZ.data(i,:) = filtfilt(lpB,lpA,PHZ.data(i,:)); end
        if notch ~= 0,  PHZ.data(i,:) = filtfilt(nB,nA,PHZ.data(i,:)); end
        
    else
        
        if hipass ~= 0, PHZ.data(i,:) = filter(hpB,hpA,PHZ.data(i,:)); end
        if lopass ~= 0, PHZ.data(i,:) = filter(lpB,lpA,PHZ.data(i,:)); end
        if notch ~= 0,  PHZ.data(i,:) = filter(nB,nA,PHZ.data(i,:)); end
    end
end
if verbose, fprintf('Done.\n'), end


PHZ.proc.filter.hipass = hipass;
PHZ.proc.filter.lopass = lopass;
PHZ.proc.filter.notch = notch;
PHZ.proc.filter.filterType = filterType;
PHZ.proc.filter.order = filterOrder;
PHZ.proc.filter.zeroPhase = do_zeroPhase;

end