%PHZ_RECTIFY  Full- or half-wave rectification.
% 
% USAGE    
%   PHZ = phz_rectify(PHZ,RECTTYPE)
% 
% INPUT   
%   PHZ       = [struct] PHZLAB data structure.
% 
%   RECTTYPE  = ['full'|'half'] Type of rectification to perform. Enter 
%               'full' to take the absolute value of each data point, or 
%               'half' to set all negative values to 0.
% 
% OUTPUT
%   PHZ.data  = [numeric] Rectified data.
% 
% EXAMPLES
%   PHZ = phz_rectify(PHZ,'full')  >> Full-wave rectification.
%   PHZ = phz_rectify(PHZ,'half')  >> Half-wave rectification.

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

function PHZ = phz_rectify(PHZ,recttype,verbose)

if nargout == 0 && nargin == 0, help phz_rectify, return, end
if nargin > 1 && isempty(recttype), return, end
if nargin < 2, recttype = 'full'; end % 'full' or 'half'
if nargin < 3, verbose = true; end

if ismember('rej',fieldnames(PHZ.proc))
    do_rej = true;
else
    do_rej = false;
end

% rectify signal
recttype = [upper(recttype(1)),lower(recttype(2:end))];
switch recttype
    case 'Full'
        PHZ.data = abs(PHZ.data);
        if do_rej, PHZ.proc.rej.data = abs(PHZ.proc.rej.data); end
        
    case 'Half'
        PHZ.data(PHZ.data < 0) = 0;
        if do_rej, PHZ.proc.rej.data(PHZ.proc.rej.data < 0) = 0; end     
end

% add to PHZ.history and PHZ.proc
PHZ = phz_history(PHZ,[recttype,' wave rectification.'],verbose);
PHZ.proc.rectify = recttype;

if ismember('blc',fieldnames(PHZ))
    PHZ.proc.blc.values = [];
    PHZ = phz_history(PHZ,'Due to rectification, the current baseline-correction is no longer undoable.',verbose);
end
