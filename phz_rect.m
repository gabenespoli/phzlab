function PHZ = phz_rect(PHZ,varargin)
%PHZ_RECT  Full- or half-wave rectification.
% 
% PHZ = PHZ_RECT(PHZ,RECTTYPE) applies full- or half-wave rectification to
%   all trials in PHZ.data and PHZ.rej.data. RECTTYPE is a string; 'full'
%   takes the absolute value and 'half' sets all negative values to 0.
% 
%   New fields are created in the PHZ structure:
%     PHZ.rect = The value specified in RECTTYPE.
%
% Written by Gabriel A. Nespoli 2016-01-27. Revised 2016-03-21.

if nargout == 0 && nargin == 0, help phz_rect, return, end

% defaults
recttype = 'full'; % 'full' or 'half'
verbose = true;

% user-defined
if nargin > 1, recttype = varargin{1}; end
if nargin > 2, verbose = varargin{2}; end

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
PHZ.rect = recttype;
PHZ = phzUtil_history(PHZ,[recttype,' wave rectification.'],verbose);

end