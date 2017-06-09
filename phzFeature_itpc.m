function PHZ = phzFeature_itpc(PHZ,keepVars)
% helper function for phz_feature
% first calculates the fft of each trial with phzFeature_fft, then 
% calculates intertrial phase coherence with the method described
% in Tierney & Kraus, 2013, Journal of Neuroscience. This paper 
% analyzed FFRs (frequency following response; the steady-state
% portion of the ABR (auditory brainstem response)).

% get complex fft
[PHZ.data,PHZ.freqs,PHZ.units,~] = phzFeature_fft(PHZ.data,PHZ.srate,PHZ.units,'spectrum','complex');
PHZ = rmfield(PHZ,'times');
PHZ.data = PHZ.data ./ abs(PHZ.data); % transform each vector to a unit vector (magnitude of 1)
PHZ = phz_summary(PHZ,keepVars); % average trials
PHZ.data = abs(PHZ.data); % magnitude of resultant vector is the measure of phase coherence
end
