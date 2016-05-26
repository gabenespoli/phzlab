%PHZFEATURE_FFT  Single-sided FFT.
%
% USAGE
%   [data,freqs,units,featureTitle] = phzFeature_fft(data,srate,units)
%   [...] = phzFeature_fft(...,'Param1',Value1,etc.)
% 
% INPUT
%   data          = [numeric] Matrix of where each row is a time-series 
%                   trial.
% 
%   srate         = [numeric] Sampling frequency of the data.
% 
%   units         = [string] The units of the data, to be adjusted if
%                   power spectrum.
% 
% OUTPUT
%   data          = [numeric] Matrix where each row is the spectrum of the
%                   corresponding row in the input matrix.
% 
%   freqs         = [numeric] Vector of frequencies corresponding to each
%                   column of the output data.
% 
%   units         = [string] The units of the data, adjusted to include 
%                   '^2' if power spectrum.
% 
%   featureTitle  = [string] Formatted title of type of spectrum for 
%                   plotting.
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
% Written by Gabe Nespoli 2014-02-27. Revised for PHYZLAB 2016-05-11.

function [data,f,units,featureTitle] = phzFeature_fft(data,srate,units,varargin)

if nargout == 0 && nargin == 0, help phzFeature_fft, return, end

% defaults
spectrum = 'amplitude';
winType = 'hanning';
nfft = 1;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'spectrum',    spectrum = varargin{i+1};
        case 'wintype',     winType  = varargin{i+1};
        case 'nfft',        nfft = varargin{i+1};
    end
end

% cleanup user-defined
switch nfft
    case 0,     nfft = size(data,2);
    case 1,     nfft = 2^nextpow2(size(data,2));
end

% windowing
switch lower(winType)
    case {'hanning','hann'}
        data = data .* repmat(hann(size(data,2))',[size(data,1) 1]);
    case 'nowindow'
    otherwise, error('Unknown window type.')
end

% do fft
data = fft(data,nfft,2);
data = data/size(data,2);
data = data(:,1:floor(nfft/2)+1); % make single-sided

% create frequency vector
f = srate/2*linspace(0,1,floor(nfft/2)+1);

% convert spectrum
switch lower(spectrum)
    % if power spectrum, units are [PHZ.units,'^2']
    case {'amplitude','amp','abs'}, featureTitle = 'Amplitude';
        data = abs(data);
        
    case {'power','pwr','conj'}, featureTitle = 'Power';
        data = data .* conj(data);
        units = [units,'^2'];
                                    
    case {'phase','angle'}, featureTitle = 'Phase';
        data = angle(data); 
    
    otherwise, featureTitle = 'Complex';
end

end