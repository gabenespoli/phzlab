function PHZ = phz_smooth(PHZ,win,verbose)
%PHZ_SMOOTH  Smooth data with a sliding window average or RMS. The mean/RMS
%   of the window is calculated, and the window is shifted by one sample
%   until the end of the signal. Note that the smoothed signal will be
%   shorter than the original signal.
% 
% usage:    
%     PHZ = phz_smooth(PHZ)
%     PHZ = phz_smooth(PHZ,WIN)
%     PHZ = phz_smooth(PHZ,SMOOTHTYPE)
% 
% input:   
%     PHZ         = PHZLAB data structure.
% 
%     WIN         = Sliding window length in milliseconds (if >= 1)
%                   or proportion of total epoch length. Default 0.05
%                   (5% of the total epoch length).
% 
%     SMOOTHTYPE  = String specifying 'mean' or 'rms', and optionally
%                   the window length (i.e., default is 'mean0.05'; 
%                   default RMS window is 100 ms).
% 
% output:  
%     PHZ.data = The smoothed data.
% 
% examples:
%     PHZ = phz_smooth(PHZ,500) >> 0.5-second sliding window average.
%     PHZ = phz_smooth(PHZ,0.1) >> Sliding window length is 10% of total
%                                  data length; e.g., 1s for 10s signal.
%     PHZ = phz_smooth(PHZ,'rms') >> Sliding average of RMS with a 0.1s 
%                                    sliding window.
%     PHZ = phz_smooth(PHZ,'rms50') >> Sliding average of RMS with a 0.05s
%                                    sliding window.
% 
% Written by Gabriel A. Nespoli 2016-03-14. Revised 2016-04-06.
if nargout == 0 && nargin == 0, help phz_smooth, return, end
if nargin == 1, win = 0.05; end
if nargin > 1 && isempty(win), return, end
if nargin < 3, verbose = true; end

% parse input
if ischar(win)
    winStr = win;
    if strfind(lower(win),'rms')
        smoothtype = 'RMS';
        if length(win) > 3
            win = str2double(win(4:end));
        else win = 100; % default RMS window in ms
        end
    
    elseif strfind(lower(win),'mean')
        smoothtype = 'Mean';
        if length(win) > 4
            win = str2double(win(5:end));
        else win = 0.05; % default mean window in proportion of length
        end
    end
    
elseif isnumeric(win)
    winStr = ['Mean',num2str(win)];
    smoothtype = 'Mean';
    
else error('Invalid input.')    
end

% check win length
if length(win) > 1 || win < 0, error('Invalid window length.'), end

% convert win to samples
if win < 1
    win = round(size(PHZ.data,2) * 0.05); % proportion of total length
else win = round(win / 1000 * PHZ.srate); % convert from seconds to samples
end

% do smoothing
b = ones(1,win) / win;
a = 1;
switch lower(smoothtype)
    case 'mean', temp = filter(b,a,PHZ.data,[],2);
    case 'rms',  temp = sqrt(filter(b,a,PHZ.data .^ 2,[],2));
end

% adjust lengths
PHZ.data = temp(:,win:end);
PHZ.times = PHZ.times(:,ceil(win / 2):(end - floor(win/2)));

% add to PHZ.history and PHZ.proc
PHZ.proc.smooth = [smoothtype,num2str(win)];
winStr = [smoothtype,' smoothing with a ',...
    num2str(win / PHZ.srate * 1000),...
    ' ms sliding window (',winStr,').'];
PHZ = phz_history(PHZ,winStr,verbose);


end