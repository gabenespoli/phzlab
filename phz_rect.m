function PHZ = phz_rect(PHZ,recttype,verbose)
%PHZ_RECT  Full- or half-wave rectification.
% 
% usage:    PHZ = phz_rect(PHZ,RECTTYPE)
% 
% inputs:   PHZ         = PHZLAB data structure.
%           RECTTYPE    = Type of rectification to perform. Enter 'full'
%                         to take the absolute value of each data point,
%                         or 'half' to set all negative values to 0.
% 
% outputs:  PHZ.data    = Rectified data.
% 
% examples:
%   PHZ = phz_rect(PHZ,'full')  >> Full-wave rectification.
%   PHZ = phz_rect(PHZ,'half')  >> Half-wave rectification.
%
% Written by Gabriel A. Nespoli 2016-01-27. Revised 2016-04-01.

% get input
if nargout == 0 && nargin == 0, help phz_rect, return, end
if nargin < 2, recttype = 'full'; end % 'full' or 'half'
if nargin < 3, verbose = true; end

% check input
if isempty(recttype), return, end
if ismember('rej',fieldnames(PHZ)), do_rej = true; else do_rej = false; end

% rectify signal
switch lower(recttype)
    case 'full'
        PHZ.data = abs(PHZ.data);
        if do_rej, PHZ.rej.data = abs(PHZ.rej.data); end
        
    case 'half'
        PHZ.data(PHZ.data < 0) = 0;
        if do_rej, PHZ.rej.data(PHZ.rej.data < 0) = 0; end     
end

% add to PHZ.history
PHZ = phzUtil_history(PHZ,[upper(recttype(1)),lower(recttype(2:end)),' wave rectification.'],verbose);

if ismember('blc',fieldnames(PHZ))
    PHZ.blc.values = [];
    PHZ = phzUtil_history(PHZ,'Due to rectification, the current baseline-correction is no longer undoable.',verbose);
end