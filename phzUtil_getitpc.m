function [pc,f] = phzUtil_getitpc(y,Fs,varargin)
%PHZUTIL_GETITPC  Intertrial phase coherence
%   [PC,F] = PHZUTIL_GETITPC(Y,FS) calculates the spectral phase coherence 
%       amongst trials in dataset DATA with sampling frequency FS. ITPC 
%       takes the complex FFT of each trial, sets the magnitude of each 
%       complex value to 1, then averages across trials. The magnitude of 
%       the resulting  complex value at each frequency bin is taken as the 
%       measure of  phase coherence. A value of 1 indicates that all trials 
%       are perfectly in phase; a value of 0 indicates that they are 180 
%       degrees out of phase. PC is a vector of length NFFT containing 
%       phase coherence values for each frequency bin; F is a vector of
%       corresponding frequencies.
%
%   [PC,F] = PHZUTIL_GETITPC(Y,FS,NFFT) additionally sets the number of 
%       points for the FFT (default is the length of each trial).
% 
% Adapted from Tierney & Kraus, 2013, Journal of Neuroscience.
% Written by Gabe Nespoli 2015-02-27. Revised for PHYZLAB 2016-03-15.

if nargout == 0 && nargin == 0, help phzUtil_getitpc, end

% defaults
nfft = [];
target = [];
baseline = [];

if nargin > 2
    for i = 1:length(varargin)
        switch class(varargin{i})
                
            case {'single','double'} % is numeric
                switch length(varargin{i})
                    
                    case 1 % nfft
                        switch varargin{i}
                            case 0,     nfft = size(y,1);
                            case 1,     nfft = 2^nextpow2(size(y,1));
                            otherwise,  nfft = varargin{i};
                        end
                        
                    otherwise % target & baseline
                        if isempty(target),         target = varargin{i};
                        elseif isempty(baseline),   baseline = varargin{i};
                        end
                end
                
            otherwise, warning('Unknown input.')
        end
    end
end

% define undefined vars
if isempty(target), target = 1:size(y,2); end
if isempty(nfft), nfft = 2^nextpow2(size(y,2)); end

% get complex fft for each trial (i.e. each column)
yfft = fft(y(:,target),nfft);
yfft = yfft/nfft;

% get phase coherence
yfft = yfft ./ abs(yfft); % transform each vector to a unit vector (magnitude of 1)
yfft = mean(yfft,1); % average vectors across trials for each frequency bin
pc = abs(yfft); % magnitude of resultant vector is the measure of phase coherence
pc = pc(1:floor(nfft / 2) + 1); % make fft one-sided
f = Fs / 2 * linspace(0,1,floor(nfft / 2) + 1); % create frequency vector

% remove itpc of baseline
if ~isempty(baseline)
    bpc = phzUtil_getitpc(y(baseline,:),Fs,nfft);
    pc = pc - bpc;
    pc(pc < 0) = 0;
end

end