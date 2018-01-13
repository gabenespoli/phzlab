%PHZ_SMOOTH  Smooth data with a sliding window average or RMS. The mean/RMS
%   of the window is calculated, and the window is shifted by one sample
%   until the end of the signal. Note that the smoothed signal will be
%   shorter than the original signal.
% 
% USAGE    
%   PHZ = phz_smooth(PHZ)
%   PHZ = phz_smooth(PHZ,win)
% 
% input:   
%   PHZ   = [struct] PHZLAB data structure.
% 
%   win   = [numeric|string|boolean] Sliding window length in milliseconds 
%           (if >= 1) or proportion of total epoch length (if < 1). 
%           Default 0.05 (5% of the total epoch length). WIN can also be
%           a string as shorthand for specifying both window length and
%           type of smoothing (i.e., mean or RMS). In this case the string 
%           must be the smoothing type followed by a number for the window
%           length (e.g., 'rms100', or the default 'mean0.05'). If 'mean' 
%           or 'rms' are specified without a number, the defaults are 
%           0.05 (5%) and 100 (ms) respectively. Logical true will use the 
%           defaults.
% 
% OUTPUT
%   PHZ.data = [numeric] The smoothed data.
% 
% EXAMPLES
%   PHZ = phz_smooth(PHZ,500) >> 0.5-second sliding window average.
% 
%   PHZ = phz_smooth(PHZ,0.1) >> Sliding window length is 10% of total
%                                data length; e.g., 1s for 10s signal.
% 
%   PHZ = phz_smooth(PHZ,'rms') >> Sliding average of RMS with a 0.1s 
%                                  sliding window.
% 
%   PHZ = phz_smooth(PHZ,'rms50') >> Sliding average of RMS with a 50ms
%                                    sliding window.

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

function PHZ = phz_smooth(PHZ,win,verbose)

if nargout == 0 && nargin == 0, help phz_smooth, return, end
if nargin == 1 || (nargin > 1 && islogical(win) && win)
    win = 0.05;
end
if nargin > 1 && (isempty(win) || (islogical(win) && ~win))
    return
end
if nargin < 3, verbose = true; end

% parse input
if ischar(win)
    winStr = win;
    if contains(lower(win),'rms')
        smoothtype = 'RMS';
        if length(win) > 3
            win = str2double(win(4:end));
        else
            win = 100; % default RMS window in ms
        end

    elseif contains(lower(win),'mean')
        smoothtype = 'Mean';
        if length(win) > 4
            win = str2double(win(5:end));
        else
            win = 0.05; % default mean window in proportion of length
        end

    else 
        smoothtype = 'Mean';
        winStr = ['mean',win];
        win = str2num(win);

    end

elseif isnumeric(win)
    winStr = ['mean',num2str(win)];
    smoothtype = 'Mean';

else
    error('Invalid input.')    

end

% check win length
if isempty(win) || length(win) > 1 || win < 0, error('Invalid window length.'), end

% convert win to samples
if win < 1
    win = round(size(PHZ.data,2) * 0.05); % proportion of total length
else
    win = round(win / 1000 * PHZ.srate); % convert from seconds to samples
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
PHZ.proc.smooth = [lower(smoothtype),num2str(win)];
winStr = [smoothtype,' smoothing with a ',...
    num2str(win / PHZ.srate * 1000),...
    ' ms sliding window (',winStr,').'];
PHZ = phz_history(PHZ,winStr,verbose);

end
