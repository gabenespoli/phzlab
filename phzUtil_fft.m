%PHZUTIL_FFT  Single-sided FFT.
%
% USAGE
%   [data,freqs,featureTitle,units] = phzUtil_fft(data,srate)
%   [...] = phzUtil_fft(...,'Param1',Value1,etc.)
% 
% INPUT
%   data          = [numeric] A trials-by-time array of data.
% 
%   srate         = [numeric] Sampling frequency of the data.
% 
%   'spectrum'    = ['amplitude'|'power'|'phase'|'complex'] Specifies the
%                   type of spectrum to calculate. Default 'amplitude'.
% 
%   'wintype'     = ['hanning'|'none'] Type of windowing to apply to the
%                   epoch. Default 'hanning'.
% 
%   'nfft'        = [numeric] Number of points in the FFT. Default is the
%                   next power of two after the length of the epoch.
%
%   'detrend'     = [true|false] Whether or not to remove the mean from the
%                   signal before calculating the FFT. This is done twice:
%                   before and after applying the window. Default true.
%
%   'units'       = [string] The units of the data, to be adjusted if
%                   power spectrum.
%
% OUTPUT
%   data          = [numeric] Matrix where each row is the spectrum of the
%                   corresponding row in the input matrix.
% 
%   freqs         = [numeric] Vector of frequencies corresponding to each
%                   column of the output data.
% 
%   featureTitle  = [string] Formatted title of type of spectrum for plotting.
% 

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

function [data,f,featureTitle,units] = phzUtil_fft(data,srate,varargin)

if nargout == 0 && nargin == 0, help phzUtil_fft, return, end

% defaults
spectrum = 'amplitude';
winType = 'hanning';
nfft = 1;
do_detrend = true;
units = '';

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'spectrum',    spectrum = varargin{i+1};
        case 'wintype',     winType  = varargin{i+1};
        case 'nfft',        nfft = varargin{i+1};
        case 'detrend',     do_detrend = varargin{i+1};
        case 'units',       units = varargin{i+1};
    end
end

% cleanup user-defined
switch nfft
    case 0,     nfft = size(data,2);
    case 1,     nfft = 2^nextpow2(size(data,2));
end

if do_detrend
    data = transpose(detrend(transpose(data), 'constant'));
end

% windowing
switch lower(winType)
    case {'hanning','hann'}
        data = data .* repmat(hann(size(data,2))',[size(data,1) 1]);
    case {'nowindow','none'}
    otherwise
        error('Unknown window type.')
end

if do_detrend
    data = transpose(detrend(transpose(data), 'constant'));
end

% do fft
data = fft(data,nfft,2);
data = data/size(data,2);
data = data(:,1:floor(nfft/2)+1); % make single-sided

% create frequency vector
f = srate/2*linspace(0,1,floor(nfft/2)+1);

% convert spectrum
switch lower(spectrum)
    case {'amplitude','amp','abs'}
        featureTitle = 'Amplitude';
        data = abs(data);

    % if power spectrum, units are [PHZ.units,'^2']
    case {'power','pwr','conj'}
        featureTitle = 'Power';
        data = data .* conj(data);
        units = [units,'^2'];

    case {'phase','angle'}
        featureTitle = 'Phase';
        data = angle(data); 

    otherwise, featureTitle = 'Complex';
end

end
