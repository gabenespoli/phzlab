%PHZ_EPOCH  Split a PHZ structure into trials.
% 
% USAGE
%   PHZ = PHZ_EPOCH(PHZ,times,win)
%   PHZ = PHZ_EPOCH(PHZ,times,win,'Param1',Value1,etc.)
% 
% INPUT
%   PHZ   = PHZLAB data structure.
% 
%   times = [numeric|string] If numeric, a vector of times in seconds. Use
%           the 'units' parameter for different time units. If a string, it
%           specifies a filename containing the epoch times.
% 
%   win   = [numeric] A vector of length 2 specifying the window around
%           each epoch time to extract. Enter in the form [start end] in 
%           samples relative to the marker. e.g. [-1 2]*Fs (one second 
%           before and two seconds after the marker).
% 
%   'units'   = [string] Specifies the units of the specified times.
%               Options are 'samples', 's'/'seconds', 'ms'/'milliseconds',
%               'min'/'minutes'. Default 'seconds';
% 
% x 'labels'  = [numeric|cell] Specifies labels to use for each epoch. Must
%               have the same number of elements as times.
% 
% OUTPUT
%   PHZ.data              = Epoched data. Each row is a different epoch.
%   PHZ.proc.epoch.times  = The marker times that were used.
%   PHZ.proc.epoch.win    = The extract window used.
% 
% Written by Gabe Nespoli 2013-07-23. Revised for PHZLAB 2016-05-11.

 function PHZ = phz_epoch(PHZ,times,win,varargin)

if nargin == 0 && nargout == 0, help phz_epoch, return, end

if size(PHZ.data,1) > 1, error('PHZ.data seems to already be epoched...'), end

% defaults
units = 'seconds';
verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'units',               units = varargin{i+1};
        case 'verbose',             verbose = varargin{i+1};
    end
end

[times,win] = verifyInput(times,win,units);

PHZ.data = extractEpochs(PHZ.data,times,win);

PHZ.proc.epoch.times = times;
PHZ.proc.epoch.win = win;

PHZ = phz_history(PHZ,'Extracted epochs from data.',verbose);
end

function epochs = extractEpochs(data,times,win)

disp('Extracting epochs...')
h = waitbar(0,'Extracting epochs...');

epochs = zeros(length(times),win(2) - win(1) + 1);

% split data file
rminds = [];
for i = 1:length(times) % loop through trials
    waitbar(i/length(times),h)
    
    % skip trials for which the epoch window is too large for the datafile
    if (times(i) + win(1) < 1) || (times(i) + win(2) > size(data,2))
        warning(['Removing trial ',num2str(i),' because it is too close to ',...
            'edge of the datafile for the requested extraction window.'])
        rminds = [rminds i];
        continue
    end
    
    epochs(i,:) = data(:,times(i) + win(1):times(i) + win(2));
end
if rminds, epochs(rminds,:) = []; end

close(h)
end

function [times,win] = verifyInput(times,win,units)
if strcmp(units,'samples'), return, end

switch lower(units)
    case {'s','seconds'}
        times = times / PHZ.srate;
        win = win / PHZ.srate;
        
    case {'ms','milliseconds'}
        times = times / 1000 / PHZ.srate;
        win = win / 1000 / PHZ.srate;
        
    case {'min','minutes'}
        times = times * 60 / PHZ.srate;
        win = win * 60 / PHZ.srate;
        
    otherwise, error('Unknown units.')
end

if any(mod(times,1))
    warning('Adjusting some marker times to align with digital sampling.')
    times = round(times);
end

if any(mod(win,1))
    warning('Adjusting extraction window to align with digital sampling.')
    win = round(win);
    switch lower(units)
        case {'s','seconds'},       extractWindowStr = win * PHZ.srate;
        case {'ms','milliseconds'}, extractWindowStr = win * PHZ.srate / 1000;
        case {'min','minutes'},       extractWindowStr = win * PHZ.srate / 60;
    end
    disp(['New extraction window is [',num2str(extractWindowStr),'].'])
end
end