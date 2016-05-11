%PHZ_EPOCH  Split a PHZ structure into trials.
%
% USAGE
%   PHZ = phz_epoch(PHZ,times,win)
%   PHZ = phz_epoch(PHZ,times,win,'Param1',Value1,etc.)
%
% INPUTS
%   PHZ       = [struct] PHZLAB data structure.
%
%   times     = [numeric|string] If a vector, the sample numbers from where
%               to extract epochs. If a string, a filename to load with the
%               epoch times. Use parameter/value pairs (described below) to
%               control options for the import.
%
%   win       = [numeric] a Vector of length 2 specifying the start and end
%               times of epochs relative to the values in TIMES.
%
%   

%AUDIOEPOCH Finds audio markers/triggers in a data file using a threshold
%   and epochs the file based on these locations.
%
%   EPOCHS = AUDIOEPOCH(DATA,PARAMS) takes the array DATA, finds audio
%   markers on the specifed channel, and epochs the file at each marker
%   based on the specified time limits. DATA should be TIME-by-CHANNELS,
%   and EPOCHS is EPOCHS-by-TIME-by-CHANNELS. PARAMS is a structure
%   variable that specifies parameters for epoching. All of the variables
%   below should be fields in PARAMS.
%
%   EPOCHS = AUDIOEPOCH(DATA,PARAMS,'Param1',Value1,...) allows
%   modification of the parameters in PARAMS from the command line.
%
%     'threshold'       =  Threshold to use when searching for markers.
%
%     'extractWindow'   =  Window around marker to extract and export data.
%                          Enter in the form [start end] in samples
%                          relative to the marker. e.g. [-1 2]*Fs (one
%                          second before and two seconds after the marker).
%
%     'filter'    =  Call phz_filter with this value as input.
%
%     'transform'
%
% Written by Gabe Nespoli 2013-07-23. Revised for PHZLAB 2016-05-09.

function PHZ = phz_epoch(PHZ,times,win,varargin)

if nargin == 0 && nargout == 0, help phz_epoch, return, end

if size(PHZ.data,1) > 1, error('PHZ.data seems to already be epoched...'), end

% defaults
units = 'samples';
transform = [];
cutoff = [];
verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'units',               units = varargin{i+1};
        case 'transform',           transform = varargin{i+1};
        case {'filter','freq'},     cutoff = varargin{i+1};
        case 'verbose',             verbose = varargin{i+1};
    end
end

[times,win] = verifyInput(times,win,units);

% adjust data before epoching
PHZ = phzUtil_filter(PHZ,cutoff);
PHZ = phz_transform(PHZ,transform);

% extract epochs
PHZ.data = extractEpochs(PHZ.data,times,win);

% add info to PHZ structure
PHZ.misc.markerTimes = times;
PHZ.misc.extractWindow = win;

PHZ = phzUtil_history(PHZ,'Extracted epochs from data.',verbose);
end

function epochs = extractEpochs(data,markerTimes,extractWindow)

disp('Extracting epochs...')
h = waitbar(0,'Extracting epochs...');

% EPOCHS is trials X time X channels (DATA is time X channels)
epochs = zeros(length(markerTimes),extractWindow(2) - extractWindow(1) + 1);

% split data file
rminds = [];
for i = 1:length(markerTimes) % loop through trials
    waitbar(i/length(markerTimes),h)
    
    % skip trials for which the epoch window is too large for the datafile
    if (markerTimes(i) + extractWindow(1) < 1) || (markerTimes(i) + extractWindow(2) > size(data,2))
        warning(['Removing trial ',num2str(i),' because it is too close to ',...
            'edge of the datafile for the requested extraction window.'])
        rminds = [rminds i];
        continue
    end
    
    epochs(i,:) = data(:,markerTimes(i) + extractWindow(1):markerTimes(i) + extractWindow(2));
end
if rminds, epochs(rminds,:) = []; end

close(h)
end

function [markerTimes,extractWindow] = verifyInput(markerTimes,extractWindow,units)
if strcmp(units,'samples'), return, end

switch lower(units)
    case {'s','seconds'}
        markerTimes = markerTimes / PHZ.srate;
        extractWindow = extractWindow / PHZ.srate;
        
    case {'ms','milliseconds'}
        markerTimes = markerTimes / 1000 / PHZ.srate;
        extractWindow = extractWindow / 1000 / PHZ.srate;
        
    case {'m','minutes'}
        markerTimes = markerTimes * 60 / PHZ.srate;
        extractWindow = extractWindow * 60 / PHZ.srate;
        
    otherwise, error('Unknown units.')
end

if any(mod(markerTimes,1))
    warning('Adjusting some marker times to align with digital sampling.')
    markerTimes = round(markerTimes);
end

if any(mod(extractWindow,1))
    warning('Adjusting extraction window to align with digital sampling.')
    extractWindow = round(extractWindow);
    switch lower(units)
        case {'s','seconds'},       extractWindowStr = extractWindow * PHZ.srate;
        case {'ms','milliseconds'}, extractWindowStr = extractWindow * PHZ.srate / 1000;
        case {'m','minutes'},       extractWindowStr = extractWindow * PHZ.srate / 60;
    end
    disp(['New extraction window is [',num2str(extractWindowStr),'].'])
end
end