%PHZFEATURE_FFT  Single-sided FFT.
%
% USAGE
%   PHZ = phzFeature_fft(PHZ)
%   PHZ = phzFeature_fft(PHZ,'Param1',Value1,etc.)
%   [PHZ,featureTitle] = phzFeature_fft(PHZ,...)
% 
% INPUT
%   PHZ           = [struct] PHZLAB data structure.
%
%   Parameter-value pairs are passed directly to phzUtil_fft. See
%       help phzUtil_fft explanation of the options.
%
%   Options can be stored as a struct in PHZ.lib.fft. This allows you to
%       control the FFT when it is called from phz_plot or phz_writetable.
%       For example, to use the power spectrum instead of the default
%       amplitude spectrum, add the following to the PHZ structure:
%
%       PHZ.lib.fft.spectrum = 'power'
%
%       If you wish to override this setting later, adding a parameter-
%       value pair to the phzFeature_fft call will do it.
%
% OUTPUT
%   PHZ.data      = [numeric] Spectral data.
% 
%   PHZ.freqs     = [numeric] Vector of frequencies corresponding to each
%                   column of the output data. This replaces PHZ.times.
% 
%   PHZ.units     = [string] The units of the data, adjusted to include 
%                   '^2' if power spectrum.
% 
%   featureTitle  = [string] Formatted title of type of spectrum for
%                   plotting.

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

function [PHZ,featureTitle] = phzFeature_fft(PHZ,varargin)

if nargout == 0 && nargin == 0, help phzFeature_fft, return, end

% param/value pairs are the fft opts to pass through to phzUtil_fft
fftopts = varargin;

% add units from PHZ.units
fftopts = [{'units', PHZ.units} fftopts];

% get default fft options from PHZ.lib.fft
if ismember('fft', fieldnames(PHZ.lib))
    % put varargin 2nd, so that they override the defaults in PHZ.lib.fft
    fftopts = [phzUtil_struct2paramValuePairs(PHZ.lib.fft) fftopts];
end

% call phzUtil_fft with parts of PHZ, passing all options
[PHZ.data, PHZ.freqs, featureTitle, PHZ.units] = ...
    phzUtil_fft(PHZ.data, PHZ.srate, fftopts{:});

% remove times field (it will have freqs instead)
PHZ = rmfield(PHZ, 'times');

end
