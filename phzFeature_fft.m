function PHZ = phzFeature_fft(PHZ,varargin)
%PHZFEATURE_FFT  Single-sided FFT for PHZ tables with spectrum options.
%   [YFFT,F] = GETFFT(Y,FS) computes the fast Fourier transform and
%       returns the single-sided spectrum YFFT and frequency bin vector
%       F (in Hz) of signal Y and sampling rate FS. Like FFT, GETFFT
%       for matrices operates along the first non-singlton dimension.
%
%   [YFFT,F] = GETFFT(...,OPTARGS) allows entering any of the following in
%       any order for the associated functionality:
%
%       Spectrum options:
%           'amplitude' = uses ABS function (default)
%           'power'     = uses CONJ function
%           'phase'     = uses ANGLE function
%           'none'      = Complex single-sided FFT
%
%       [vector of length 1] = Specifies the number points for the FFT.
%           Enter 1 to pad Y with zeros to the next power of 2 (default),
%           0 for the same length as Y (no padding), or any other value.
%
%       [vector of length > 2] performs the FFT on only these indices
%           of Y (TARGET region). If there are two vector arguments of
%           length > 2, the first is the TARGET and the second is the
%           BASELINE. GETFFT calulates the FFT of both regions and
%           subtracts the spectrum of the BASELINE from the spectrum
%           of the TARGET. Resultant negative values are set to 0.
%
%       'plot' = Plots the resultant spectrum on the current axis. If no
%           output arguments are specified this is done automatically.
%           If Y is a matrix, the mean of all spectra is plotted.
%
%       'hanning' = Applies a Hanning window amplitude envelope before
%           calculating the FFT. Default.
% 
%       'nowindow' = No windowing applied before calculating FFT.
%
% Written by Gabe Nespoli 2014-02-27. Revised for PHYZLAB 2016-03-22.

if nargout == 0 && nargin == 0, help phzUtil_getfft, end

% defaults
spectrum = 'Amplitude';
nfft = 1;
target = [];
baseline = [];
winType = 'hanning';

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'spectrum',                spectrum = varargin{i+1};
        case {'n','nfft'},              nfft = varargin{i+1};
        case 'window',                  winType  = varargin{i+1};
        case 'target',                  target = varargin{i+1};
        case 'baseline',                baseline = varargin{i+1};
        case 'verbose',                 verbose = varargin{i+1};
    end
end

% cleanup user-defined
switch nfft
    case 0,     nfft = size(PHZ.data,2);
    case 1,     nfft = 2^nextpow2(size(PHZ.data,2));
end

% define undefined vars
if isempty(target), target = 1:size(PHZ.data,2); end

% copy rejected trials to the bottom of PHZ.data (we'll move them back later)
if ismember('rej',fieldnames(PHZ)), PHZ.data = [PHZ.data; PHZ.rej.data]; end

% windowing
switch lower(winType)
    case {'hanning','hann'}
        PHZ.data = PHZ.data .* repmat(hann(size(PHZ.data,2))',[size(PHZ.data,1) 1]);
    case 'nowindow'
    otherwise, error('Unknown window type.')
end

% do fft
PHZ.data = fft(PHZ.data(:,target),nfft,2);
PHZ.data = PHZ.data/length(PHZ.data);
PHZ.data = PHZ.data(:,1:floor(nfft/2)+1); % make single-sided

% create frequency vector
PHZ.freqs = PHZ.srate/2*linspace(0,1,floor(nfft/2)+1);
PHZ = rmfield(PHZ,'times');

% convert spectrum
switch lower(spectrum)
    % if power spectrum, units are [PHZ.units,'^2']
    case {'amplitude','amp','abs'}, PHZ.data = abs(PHZ.data); spectrum = 'Amplitude';
    case {'power','pwr','conj'},    PHZ.data = PHZ.data.*conj(PHZ.data);
                                    PHZ.units = [PHZ.units,'^2'];
                                    spectrum = 'Power';
    case {'phase','angle'},         PHZ.data = angle(PHZ.data); spectrum = 'Phase';
    otherwise, spectrum = 'Complex';
end

% do baseline
if ~isempty(baseline)
    PHZb = phzFeature_fft(PHZ,baseline,spectrum,nfft,winType); % spectrum of baseline
    PHZ.data = PHZ.data-PHZb.data; % subtract baseline spectrum from target spectrum
    PHZ.data(PHZ.data < 0) = 0; % set negative values to zero
end

PHZ = phz_history(PHZ,['Calculated ',spectrum,' spectrum.'],verbose);

% clear out blc values
if ismember('blc',fieldnames(PHZ))
    PHZ.blc.values = [];
end

% move rejected trials back to rej
if ismember('rej',fieldnames(PHZ))
    nRej = size(PHZ.rej.data,1) - 1;
    PHZ.rej.data = PHZ.data(end - nRej:end,:);
    PHZ.data(end-nRej:end,:) = [];
end

end