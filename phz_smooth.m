function PHZ = phz_smooth(PHZ,win,varargin)
%PHZ_SMOOTH  Smooth data with a sliding window average or RMS
% 
% usage:    PHZ = phz_smooth(PHZ)
%           PHZ = phz_smooth(PHZ,WIN)
%           PHZ = phz_smooth(PHZ,SMOOTHTYPE)
% 
% inputs:   PHZ = PHZLAB data structure.
%           WIN = Sliding window length in milliseconds (if >= 1) or
%               proportion of total epoch length. Default 0.05 (5% of
%               the total epoch length).
%           SMOOTHTYPE = String specifying 'mean' or 'rms', and optionally the
%               window length (i.e., default is 'mean0.05'; default RMS
%               window is 100 ms).
% 
% outputs:  PHZ.data = The smoothed data.
% 
% examples:
%   phz_smooth(PHZ,500)      >> 0.5-second sliding window average.
%   phz_smooth(PHZ,0.1)      >> Sliding window length is 10% of total data
%                               length; 1s if signal is 10s long.
%   phz_smooth(PHZ,'rms100') >> Sliding average of RMS with a 0.1s sliding
%                               window.
% 
% Written by Gabriel A. Nespoli 2016-03-14. Revised 2016-03-30.

if nargout == 0 && nargin == 0, help phz_smooth, end
if nargin == 1, win = 0.05; end
if nargin > 1 && isempty(win), return, end

% defaults
verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'verbose', verbose = varargin{i+1};
    end
end

% parse input
if ischar(win)
    winStr = win;
    if strfind(lower(win),'rms')
        smoothtype = 'rms';
        if length(win) > 3
            win = str2double(win(4:end));
        else win = 100; % default RMS window in ms
        end
    
    elseif strfind(lower(win),'mean')
        smoothtype = 'mean';
        if length(win) > 4
            win = str2double(win(5:end));
        else win = 0.05; % default mean window in proportion of length
        end
    end
    
elseif isnumeric(win)
    winStr = ['mean',num2str(win)];
    smoothtype = 'mean';
    
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
switch smoothtype
    case 'mean', temp = filter(b,a,PHZ.data,[],2);
    case 'rms',  temp = sqrt(filter(b,a,PHZ.data .^ 2,[],2));
end

% adjust lengths
PHZ.data = temp(:,win:end);
PHZ.times = PHZ.times(:,ceil(win / 2):(end - floor(win/2)));

% add to history
winStr = [smoothtype,' smoothing with a ',...
    num2str(win / PHZ.srate * 1000),' ms sliding window (',winStr,').'];
PHZ = phzUtil_history(PHZ,winStr,verbose);

end