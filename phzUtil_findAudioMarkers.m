%PHZ_EPOCH  Split a PHZ structure into trials.
% PHZ = PHZ_EPOCH(PHZ,TIMES,WINDOW) finds epochs in 

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
%     'markerBetween'   =  Length of time (or silence, or sub-threshold
%                          points) between the end of a marker and the
%                          beginning of the next. In samples.
%
%     'markerMaxRegion' =  The region around each marker to search for a
%                          maximum and set that point as the marker
%                          instead. In samples.
%
%     'plotMarkers'     =  Enter 0 to suppress plot window. Default 1. Use
%                          when automated function is desired (i.e. script
%                          will not pause and wait for user feedback before
%                          continuing). Enter 2 to also plot lines for
%                          marker positions.
%
%
%     'numEpochs'       =  leave empty ([]) if unknown
%     'numEpochsPrompt' =  what to do if number of markers found doesn't
%                          match the number of expected markers. Enter 1 to
%                          be prompted for options, 0 to automatically
%                          cancel, and 2 to automatically continue.
%
%     'stim'
%
% Written by Gabe Nespoli 2013-07-23. Revised for PHZLAB 2016-03-24.

function markerInd = phzUtil_findAudioMarkers(markerData,threshold,varargin)

% verify input
if nargin < 2, error('Not enough input arguments.'), end
if nargin > 2 && mod(nargin,2) == 1, error('Incorrect number of parameter/value pairs.'), end
if ~isstruct(params), error('PARAMS input must be a structure variable.'), end

% break out params structure into variables
[audioInd,Fs,threshold,markerBetween,markerMaxRegion,stim,...
    numEpochs,numEpochsPrompt,plotMarkers,...
    markerTimes,extractWindow] = verifyParams(params);

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'fs',                  Fs = varargin{i+1};
        case 'threshold',           threshold = varargin{i+1};
        case 'markerbetween',       markerBetween = varargin{i+1};
        case 'markermaxregion',     markerMaxRegion = varargin{i+1};
        case 'stim',                stim = varargin{i+1};
        case 'numepochs',           numEpochs = varargin{i+1};
        case 'numepochsprompt',     numEpochsPrompt = varargin{i+1};            
        case 'plotmarkers',         plotMarkers = varargin{i+1};
        case 'markertimes',         markerTimes = varargin{i+1};
        case 'extractwindow',       extractWindow = varargin{i+1};
    end
end

% verify input
if threshold <= 0, error('Threshold must be greater than zero'), end

% prepare vars
foundMarkers = 0;
returnFlag = 0;

while ~foundMarkers
    
    if isempty(markerTimes)
        disp('Finding marker times...')
        AboveThresh = find(abs(markerData) > threshold); % find all suprathreshold points
        if ~isempty(AboveThresh) % adjust so only one suprathreshold point per marker
            AboveThreshDiff = diff(AboveThresh); % get time between each suprathreshold point
            diffs = find(AboveThreshDiff > markerBetween)+1; % ignore points too close to their neighbour
            markerTimes = [AboveThresh(1) AboveThresh(diffs)']; % add to container
        end
        disp(['- ',num2str(length(markerTimes)),' markers found at threshold ',num2str(threshold),'.'])
        foundMarkers = 1;
        
    else
        disp([num2str(length(markerTimes)),' markers specified.'])
        
    end
    
    % check for correct number of markers found
    if ~isempty(numEpochs)
        disp(['- ',num2str(numEpochs),' markers were expected.'])
        
        if length(markerTimes) == numEpochs
            foundMarkers = 1;
        else
            switch numEpochsPrompt
                case 0, returnFlag = 1; foundMarkers = 0; % cancel
                case 1, [threshold,markerTimes,foundMarkers,returnFlag] = prompt(markerData,Fs,threshold,markerTimes);
                case 2, returnFlag = 0; foundMarkers = 1; % continue anyway
            end
        end
    end
    
    % adjust markerTimes to be more precise
    if foundMarkers
        markerTimes = xcorrPrecision(markerData,markerTimes,stim,extractWindow);
        markerTimes = adjustMarkerMaxRegion(markerData,markerTimes,markerMaxRegion);
    end
    
    % plot if desired
    if foundMarkers && plotMarkers
        plotMarkerChannel(markerData,Fs,length(markerTimes),threshold,markerTimes);
        [threshold,markerTimes,foundMarkers,returnFlag] = prompt(markerData,Fs,threshold,markerTimes);
    end
    
    if returnFlag, disp('No epochs were extracted.'), return, end
end

end

function [threshold,markerTimes,foundMarkers,returnFlag] = prompt(markerData,Fs,threshold,markerTimes)
askAgain = 1;
returnFlag = 0;

while askAgain
    disp(' ')
    disp('How should AudioEpoch proceed?')
    disp('  x > Cancel epoching')
    disp('  c > Continue epoching')
    disp('  p > Plot audio channel and ask again')
    disp('  m > Plot audio channel with markers and ask again')
    disp('  r > Enter marker number(s) to delete')
    disp('  [number] > Try again with this threshold')
    resp = input('Enter your choice >> ','s');
    
    switch lower(resp)
        case 'x'
            returnFlag = 1;
            foundMarkers = 0;
            askAgain = 0;
            
        case 'c'
            disp('Continuing epoching...')
            foundMarkers = 1;
            askAgain = 0;
            
        case 'p'
            plotMarkerChannel(markerData,Fs,threshold,markerTimes,0)
            askAgain = 1;
            
        case 'm'
            plotMarkerChannel(markerData,Fs,threshold,markerTimes,1)
            askAgain = 1;
            
        case 'r'
            rmMarkers = input('  Enter marker number(s) to delete >> ');
            markerTimes(rmMarkers) = [];
            disp([num2str(length(markerTimes)),' markers remain.'])
            askAgain = 1;
            
        otherwise
            if ~isnan(str2double(resp))
                threshold = str2double(resp);
                markerTimes = [];
                askAgain = 0;
                foundMarkers = 0;
            else disp('Invalid input.')
            end
    end
end
end

function markerTimes = xcorrPrecision(markerData,markerTimes,stim,extractWindow)
if ~isempty(stim)
    disp('Using stimulus waveform and cross-correlation to optimize marker times...')
    h=waitbar(0,'Optimizing marker times with stimulus cross-correlation...');
    for i = 1:length(markerTimes)
        waitbar(i/length(markerTimes),h)
        
        % skip trials for which the epoch window is too large for the datafile
        if (markerTimes(i) + extractWindow(1) < 1) || (markerTimes(i) + extractWindow(2) > size(markerData,1))
            warning(['Skipping trial ',num2str(i),' because it is too close to ',...
                'edge of the datafile for the requested extractWindow.'])
            continue
        end
        
        % get current marker with extractWindow
        currentMarker = markerData(markerTimes(i)+extractWindow(1):markerTimes(i)+extractWindow(2));
        
        % find highest cross-correlation (both polarities)
        [r1,lag1] = xcorr(currentMarker,stim);
        [r2,lag2] = xcorr(currentMarker,stim * -1);
        
        if max(r1) > max(r2), [~,ind] = max(r1); lag = lag1;
        else [~,ind] = max(r2); lag = lag2;
        end
        
        if lag(ind) ~= 0
            markerTimes(i) = markerTimes(i) + lag(ind);
        end
    end
    close(h)
end
end

function markerTimes = adjustMarkerMaxRegion(markerData,markerTimes,markerMaxRegion)
if isempty(markerMaxRegion), return, end

disp('Adjusting markers to max instead of onset...')

% verify markerMaxRegion is within length of markerData
if markerTimes(1)+markerMaxRegion(1)<1
    warning('markerMaxRegion too long for first marker. First marker removed.')
    markerTimes(1)=[];
end

if markerTimes(end)+markerMaxRegion(2)>length(markerData)
    warning('markerMaxRegion too long for last marker. Last marker removed.')
    markerTimes(end)=[];
end

h=waitbar(0,'Adjusting markers to max instead of onset...');
for i=1:length(markerTimes)
    waitbar(i/length(markerTimes),h)
    [~,tempMaxInd]=max(markerData(markerTimes(i)+markerMaxRegion(1):markerTimes(i)+markerMaxRegion(2)));
    markerTimes(i)=markerTimes(i)+markerMaxRegion(1)+tempMaxInd;
end
close(h)
end

function plotMarkerChannel(markerData,Fs,threshold,markerTimes,plotMarkerTimes)
disp('Plotting audio marker channel...')

% if there is too much data, only plot a portion of it


figure('units','normalized','outerposition',[0 0 1 1]) % plot fullscreen
plot((1:1:length(markerData))/Fs,markerData);
title([num2str(length(markerTimes)),' markers found. See command window for options...'])
set(gca,'FontSize',16);
xlabel('Time (s)');

% plot threshold line
if threshold, line(xlim,[threshold threshold],'Color','c'), end

% plot marker positions
if plotMarkerTimes
    
    % warn if this might take a while
    if length(markerTimes) > 150
        disp('WARNING: There are more than 150 markers.')
        disp('This may take a very long time to plot.')
        cont = input('Do you want to continue? [Y/N] >> ','s');
        if ~strcmpi(cont,'n')
            plotMarkerTimes = 0;
        end
    end
    
    if plotMarkerTimes
        h = waitbar(0,'Plotting marker positions...');
        for i = 1:length(markerTimes)
            waitbar(i / length(markerTimes),h)
            line([markerTimes(i) markerTimes(i)] / Fs,ylim,'Color','r')
        end
        close(h)
    end
end

end

function [audioInd,Fs,threshold,markerBetween,markerMaxRegion,stim,...
    numEpochs,numEpochsPrompt,plotMarkers,...
    markerTimes,extractWindow] = verifyParams(params)

% required fields
audioInd = params.audioInd;
Fs = params.Fs;
threshold = params.threshold;
markerBetween = params.markerBetween;
extractWindow = params.extractWindow;

% optional fields - create empty defaults
markerMaxRegion = [];
stim = [];

numEpochs = [];
numEpochsPrompt = [];
plotMarkers = [];

markerTimes = [];

% optional fields, check for specified value
if isfield(params,'markerMaxRegion'), markerMaxRegion = params.markerMaxRegion; end
if isfield(params,'stim'), stim = params.stim; end

if isfield(params,'numEpochs'), numEpochs = params.numEpochs; end
if isfield(params,'numEpochsPrompt'), numEpochsPrompt = params.numEpochsPrompt; end
if isfield(params,'plotMarkers'), plotMarkers = params.plotMarkers; end

if isfield(params,'markerTimes'), markerTimes = params.markerTimes; end

end