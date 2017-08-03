%PHZ_DISCARD  Actually remove trials that are marked for rejection.
%   Trials can be marked using phz_reject, phz_subset, and 
%   phz_review. This function is primarily used by phz_summary,
%   phz_feature, phz_plot, and phz_writetable.
%
% USAGE
%   PHZ = phz_discard(PHZ)
%
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
%   
%   At least one of the following fields should be populated using
%   the appropriate function:
%       PHZ.proc.reject.keep
%       PHZ.proc.subset.keep
%       PHZ.proc.review.keep
%
% OUTPUT
%   PHZ.data  = Data with marked trials removed.
%
%   PHZ.meta.tags.* = The trial tags (i.e., participant, group,
%               condition, session, trials) also have the 
%               corresponding rows removed.
%
%   PHZ.resp.* = The behavioural responses also have the 
%               corresponding rows removed.

% Copyright (C) 2017 Gabriel A. Nespoli, gabenespoli@gmail.com
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

function PHZ = phz_discard(PHZ)

if nargin == 0 && nargout == 0, help phz_discard, return, end









% issues:
% - should the rejections from the different sources be done in
%   the order they appear, or some other order?
%
% - could find indices of any of them, loop them, and switch/case
%   them to do the rejections
%
% - the proc fields that are actually dependant on each other
%   such that it matters which order they are done in are:
%   reject, blsub, norm, transform
%







end
