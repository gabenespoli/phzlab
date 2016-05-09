function PHZ = phz_rectify(PHZ,recttype,verbose)
%PHZ_RECTIFY  Full- or half-wave rectification.
% 
% usage:    
%     PHZ = phz_rectify(PHZ,RECTTYPE)
% 
% input:   
%     PHZ         = PHZLAB data structure.
%     RECTTYPE    = Type of rectification to perform. Enter 'full' to take
%                   the absolute value of each data point, or 'half' to set
%                   all negative values to 0.
% 
% output:  
%     PHZ.data    = Rectified data.
% 
% examples:
%     PHZ = phz_rectify(PHZ,'full')  >> Full-wave rectification.
%     PHZ = phz_rectify(PHZ,'half')  >> Half-wave rectification.
%
% Written by Gabriel A. Nespoli 2016-01-27. Revised 2016-04-01.
if nargout == 0 && nargin == 0, help phz_rectify, return, end
if nargin > 1 && isempty(recttype), return, end
if nargin < 2, recttype = 'full'; end % 'full' or 'half'
if nargin < 3, verbose = true; end

if ismember('rej',fieldnames(PHZ.proc)), do_rej = true; else do_rej = false; end

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