function PHZ = phz_trials(PHZ)
%PHZ_ALTERNATETRIALS  Create alternating trials.
% 
% PHZ = PHZ_ALTERNATETRIALS(PHZ) fills PHZ.TRIALS with alternating trials
%   '1' and '2'. This is useful for FFR data where every other trial was 
%   presented with the opposite polarity.

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

if nargout == 0 && nargin == 0, help phz_trials, return, end

numTrials = size(PHZ.data,1);

if ~mod(numTrials,2) % (if FFR.trials is even)
    PHZ.meta.tags.trials = repmat([1;2],[numTrials/2,1]);
    
else % (FFR.trials is odd)
    PHZ.meta.tags.trials = [repmat([1;2],[(numTrials/2)-0.5,1]); 1];

end

PHZ = phz_history(PHZ,'Added alternating trials.');

end