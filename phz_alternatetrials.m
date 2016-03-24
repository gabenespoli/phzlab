function PHZ = phz_alternatetrials(PHZ)
%PHZ_ALTERNATETRIALS  Create alternating trials.
% 
% PHZ = PHZ_ALTERNATETRIALS(PHZ) fills PHZ.TRIALS with alternating trials
%   '1' and '2'. This is useful for FFR data where every other trial was 
%   presented with the opposite polarity.
%
% Written by Gabe Nespoli 2016-01-27. Revised 2016-03-22.

if nargout == 0 && nargin == 0, help phz_alternatetrials, return, end

numTrials = size(PHZ.data,1);

if ~mod(numTrials,2) % (if FFR.trials is even)
    PHZ.trials = repmat([1;2],[numTrials/2,1]);
    
else % (FFR.trials is odd)
    PHZ.trials = [repmat([1;2],[(numTrials/2)-0.5,1]); 1];

end

PHZ = phzUtil_history(PHZ,'Added alternating trials.');

end