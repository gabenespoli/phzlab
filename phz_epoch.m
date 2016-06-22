%PHZ_EPOCH  Split a PHZ structure into trials.
%
% USAGE
%   PHZ = phz_epoch(PHZ,win,times)
%   PHZ = phz_epoch(PHZ,win,times,'Param1',Value1,etc.)
%
% INPUTS
%   PHZ           = [struct] PHZLAB data structure.
%
%   extractWindow = [numeric] A vector of length 2 specifying the window 
%                   around each epoch time to extract. Enter in the form 
%                   [start end] relative to the marker. Default units is 
%                   seconds. e.g. [-1 2] (one second before and two seconds
%                   after the marker).
% 
%   times         = [numeric|string] If a vector, TIMES is the indices 
%                   (sample numbers from where the epochs should be 
%                   extracted. If a string, TIMES is a filename of a csv 
%                   file containing the epoch times. If empty, phz_epoch 
%                   attempts to open the raw data file to get the epoch 
%                   times from there. Default units is samples.
% 
%   'winUnits'    = [string] Specifies the units of the values in 
%                   EXTRACTWINDOW. Options are 'samples', 's'/'seconds', 
%                   'ms'/'milliseconds', 'min'/'minutes'.
%                   Default 'samples'.
% 
%   'timesUnits'  = [string] Specifies the units of the values in TIMES.
%                   Options are the same as 'winUnits'. Default 'seconds'.
% 
% x 'labels'      = [any] Specifies labels to use for each epoch. Must
%                   have the same number of elements as times. If LABELS 
%                   is a string, it specifies the filename containing the
%                   labels.
% 
% OUTPUT
%   PHZ.data              = Epoched data. Each row is a different epoch.
%   PHZ.proc.epoch.times  = The marker times that were used.
%   PHZ.proc.epoch.win    = The extract window used.
%   PHZ.proc.epoch.tUnits = The units of the marker times.
%   PHZ.proc.epoch.wUnits = The units of the extract window.
% 
% Written by Gabe Nespoli 2013-07-23. Revised for PHZLAB 2016-06-21.

function PHZ = phz_epoch(PHZ,extractWindow,times,varargin)

if nargin == 0 && nargout == 0, help phz_epoch, return, end
if size(PHZ.data,1) > 1, error('PHZ.data seems to already be epoched...'), end

% defaults
winUnits = 'seconds';
timesUnits = 'samples';
verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'wunits',              winUnits = varargin{i+1};
        case 'tunits',              timesUnits = varargin{i+1};
        case 'verbose',             verbose = varargin{i+1};
    end
end

PHZ.proc.epoch.extractWindow = extractWindow;
PHZ.proc.epoch.winUnits = winUnits;
PHZ.proc.epoch.times = times;
PHZ.proc.epoch.timesUnits = timesUnits;

times = convertToSamples(times,timesUnits,PHZ.srate);
extractWindow = convertToSamples(extractWindow,winUnits,PHZ.srate);

PHZ.data = extractEpochs(PHZ.data,times,extractWindow);
PHZ.times = (extractWindow(1):1:extractWindow(2)) / PHZ.srate; % convert times to seconds

PHZ = phz_history(PHZ,'Extracted epochs from data.',verbose);
end

function epochs = extractEpochs(data,times,extractWindow)

disp('Extracting epochs...')

epochs = zeros(length(times),extractWindow(2) - extractWindow(1) + 1);

rminds = [];
w = '';
for i = 1:length(times) % loop through trials
    w = phzUtil_progressbar(w,i/length(times));
    
    % skip trials for which the epoch window is too large for the datafile
    if (times(i) + extractWindow(1) < 1) || (times(i) + extractWindow(2) > size(data,2))
        warning(['Removing trial ',num2str(i),' because it is too close to ',...
            'edge of the datafile for the requested extraction window.'])
        rminds = [rminds i]; %#ok<AGROW>
        continue
    end
    
    epochs(i,:) = data(:,times(i) + extractWindow(1):times(i) + extractWindow(2));
end
if rminds, epochs(rminds,:) = []; end
end

function val = convertToSamples(val,units,srate)
% converts data in TIMES and WIN to samples

switch lower(units)
    case {'s','seconds'},       val = val * srate;
    case {'ms','milliseconds'}, val = val * srate / 1000;
    case {'min','minutes'},     val = val * srate / 60;
end

if any(mod(val,1/srate))
    warning(['Adjusting some values in ',inputname(1),' to align with digital sampling.'])
    val = round(val);
end
end