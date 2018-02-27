%PHZFEATURE_ITPC  Intertrial Phase Coherence (usually for FFR data)
%   helper function for phz_feature
%   first calculates the fft of each trial with phzUtil_fft, then 
%   calculates intertrial phase coherence with the method described
%   in Tierney & Kraus, 2013, Journal of Neuroscience. This paper 
%   analyzed FFRs (frequency following response; the steady-state
%   portion of the ABR (auditory brainstem response)).
%
% USAGE
%   PHZ = phzFeature_itpc(PHZ,keepVars)
%
% INPUT
%   PHZ       = PHZLAB data structure.
%
%   keepVars  = See phz_summary.m.
%
% OUTPUT
%   PHZ       = PHZLAB data structure with ITPC.

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

function PHZ = phzFeature_itpc(PHZ,keepVars)

% get complex fft
[PHZ.data,PHZ.freqs,~,PHZ.units] = phzUtil_fft(PHZ.data,PHZ.srate,'units',PHZ.units,'spectrum','complex');
PHZ = rmfield(PHZ,'times');

% transform each vector to a unit vector (magnitude of 1)
PHZ.data = PHZ.data ./ abs(PHZ.data);

% average trials
PHZ = phz_summary(PHZ,keepVars);

% magnitude of resultant vector is the measure of phase coherence
PHZ.data = abs(PHZ.data);

end
