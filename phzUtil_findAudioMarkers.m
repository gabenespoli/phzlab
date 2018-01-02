%PHZUTIL_FINDAUDIOMARKERS  Finds audio markers/triggers in a signal
%   using a threshold and returns the indices of their start times.
%
% USAGE
%   times = phzUtil_findAudioMarkers(data,threshold,timeBetween)
%   times = phzUtil_findAudioMarkers(data,threshold,timeBewteen,...
%                                                   'Param1',Value1,etc.)
%
% INPUT
%
%   data              = [numeric]
%
%   threshold         = [numeric]
%
%   timeBetween       = [numeric] Length of time (or silence, or
%                       sub-threshold points) between the end of a marker
%                       and the beginning of the next. In samples.
%
%   'maxRegion'       = [numeric] A 1-by-2 vector specifying the region
%                       around each marker to search for a maximum and set
%                       that point as the marker instead. In samples.
%
%   'waveform'        = [numeric] Vector of the waveform of the audio
%                       stimulus. 'markerWindow' must also be specified.
%                       After the marker time is found, a cross-correlation
%                       is calculated between DATA and MARKERWAVEFORM,
%                       within the MARKERWINDOW. The marker time is
%                       adjusted to the location of the maximum
%                       cross-correlation.
%
%   'window'          = [numeric] A 1-by-2 vector specifying the times
%                       around the marker time with which to calculate the
%                       cross-correlation. In samples.
%
%   'numMarkers'      = [numeric] Expected number of markers to find. Enter
%                       empty ([]) if unknown.
%
%   'numMarkersPrompt'= [0|1|2] What to do if number of markers found
%                       doesn't match the number of expected markers.
%                       Enter 0 to automatically cancel, 1 to be prompted
%                       for options, and 2 to automatically continue.
%                       Default 1.
%
%   'plotMarkers'     = [true|false] Option to plot the locations of the
%                       markers. Enter true to plot or false to not.
%                       Default true. If plot is shown, user is prompted
%                       with options for cancelling the process, deleting
%                       markers, or changing the threshold.
%
%   'srate'           = [numeric] Entering a sampling rate changes the
%                       units of the plot from samples to seconds. Output
%                       times are still in samples.
%
% OUTPUT
%   times             = [numeric] Indices of start times of markers
%                       (i.e., units are samples).

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

function times = phzUtil_findAudioMarkers(data,threshold,timeBetween,varargin)
if nargin == 0 && nargout == 0, help phzUtil_findAudioMarkers, return, end
if threshold <= 0, error('Threshold must be greater than zero'), end

maxRegion = [];
waveform = [];

numMarkers = [];
numMarkersPrompt = 1;
plotMarkers = true;
plotMarkerTimes = true;

srate = [];

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'maxregion',           maxRegion = varargin{i+1};
        case 'waveform',            waveform = varargin{i+1};
        case {'window','win'},      win = varargin{i+1};
            
        case 'nummarkers',          numMarkers = varargin{i+1};
        case 'nummarkersprompt',    numMarkersPrompt = varargin{i+1};
        case 'plotmarkers',         plotMarkers = varargin{i+1};
            
        case 'srate',               srate = varargin{i+1};
        
        otherwise, warning(['Unknown parameter ''',varargin{i},'''.'])
    end
end

% prepare vars
foundMarkers = false;
returnFlag = false;
times = [];

while ~foundMarkers
    
    if isempty(times)
        disp('Finding marker times...')
        aboveThresh = find(abs(data) > threshold); % find all suprathreshold points
        if ~isempty(aboveThresh) % adjust so only one suprathreshold point per marker
            aboveThreshDiff = diff(aboveThresh); % get time between each suprathreshold point
            diffs = find(aboveThreshDiff > timeBetween)+1; % ignore points too close to their neighbour
            times = [aboveThresh(1) aboveThresh(diffs)]; % add to container
        end
        disp(['',num2str(length(times)),' markers found at threshold ',num2str(threshold),'.'])
        foundMarkers = true;
    else
        disp([num2str(length(times)),' markers specified.'])
    end
    
    % check for correct number of markers found
    if ~isempty(numMarkers)
        disp([num2str(numMarkers),' markers were expected.'])
        
        if length(times) == numMarkers
            foundMarkers = true;
        else
            switch numMarkersPrompt
                case 0, returnFlag = true; foundMarkers = false; % cancel
                case 1, [threshold,times,foundMarkers,returnFlag] = prompt(data,srate,threshold,times);
                case 2, returnFlag = false; foundMarkers = true; % continue anyway
            end
        end
    end
    
    % adjust markerTimes to be more precise
    if foundMarkers
        if ~isempty(waveform),  times = xcorrPrecision(data,times,waveform,win);     end
        if ~isempty(maxRegion), times = adjustMarkerMaxRegion(data,times,maxRegion); end
    end
    
    % plot if desired
    if foundMarkers && plotMarkers
        h = plotMarkerChannel(data,srate,threshold,times,plotMarkerTimes);
        [threshold,times,foundMarkers,returnFlag] = prompt(data,srate,threshold,times,h);
    end
    
    if returnFlag, disp('No epochs were extracted.'), return, end
end

end

function [threshold,times,foundMarkers,returnFlag] = prompt(data,srate,threshold,times)
askAgain = true;
returnFlag = false;

while askAgain
    disp(' ')
    disp('How would you like to proceed?')
    disp('  x > Cancel')
    disp('  c > Continue')
    disp('  p > Plot data and ask again')
    disp('  m > Plot data with markers and ask again')
    disp('  r > Enter marker number(s) to delete')
    disp('  [number] > Try again with this threshold')
    resp = input('Enter your choice >> ','s');
    
    switch lower(resp)
        case 'x'
            returnFlag = true;
            foundMarkers = false;
            askAgain = false;
            
        case 'c'
            disp('Continuing...')
            foundMarkers = true;
            askAgain = false;
            
        case 'p'
            plotMarkerChannel(data,srate,threshold,times,false);
            askAgain = true;
            
        case 'm'
            plotMarkerChannel(data,srate,threshold,times,true);
            askAgain = true;
            
        case 'r'
            rmMarkers = input('  Enter marker number(s) to delete >> ');
            times(rmMarkers) = [];
            disp([num2str(length(times)),' markers remain.'])
            askAgain = true;
            
        otherwise
            if ~isnan(str2double(resp))
                threshold = str2double(resp);
                times = [];
                askAgain = false;
                foundMarkers = false;
            else
                disp('Invalid input.')
            end
    end
end
end

function times = xcorrPrecision(data,times,waveform,win)
disp('Using marker waveform and cross-correlation to optimize marker times...')
str = '';
for i = 1:length(times)
    str = phzUtil_progressbar(str,i/length(times));
    
    % skip trials for which the epoch window is too large for the datafile
    if (times(i) + win(1) < 1) || (times(i) + win(2) > size(data,2))
        warning(['Skipping trial ',num2str(i),' because it is too close to ',...
            'edge of the datafile for the requested window.'])
        continue
    end
    
    % get current marker with extractWindow
    currentMarker = data(times(i)+win(1):times(i)+win(2));
    
    % find highest cross-correlation (both polarities)
    [r1,lag1] = xcorr(currentMarker,waveform);
    [r2,lag2] = xcorr(currentMarker,waveform * -1);
    
    if max(r1) > max(r2)
        [~,ind] = max(r1);
        lag = lag1;
    else
        [~,ind] = max(r2); lag = lag2;
    end
    
    if lag(ind) ~= 0
        times(i) = times(i) + lag(ind);
    end
end
end

function times = adjustMarkerMaxRegion(data,times,maxRegion)
disp('Adjusting markers to max instead of onset...')

if times(1) + maxRegion(1) < 1, times(1) = [];
    warning('maxRegion too long for first marker. First marker removed.'), end

if times(end) + maxRegion(2) > size(data,2), times(end) = [];
    warning('maxRegion too long for last marker. Last marker removed.'), end

disp('Adjusting markers to max instead of onset...')
str = '';
for i = 1:length(times)
    str = phzUtil_progressbar(str,i/length(times));
    [~,tempMaxInd] = max(data(times(i) + maxRegion(1):times(i) + maxRegion(2)));
    times(i) = times(i) + maxRegion(1) + tempMaxInd;
end
end

function h = plotMarkerChannel(data,srate,threshold,times,plotMarkerTimes)
disp('Plotting audio marker channel...')

if isempty(srate)
    srate = 1;
    xtitle = 'Time (samples)';
else
    xtitle = 'Time (s)';
end
x = (0:1:length(data)-1)/srate;

h = figure('units','normalized','outerposition',[0 0 1 1]);

ax1 = axes('box','off');
plot(ax1,x,data)
hold(ax1,'on')
plot(ax1,x,repmat(threshold,size(x)))
xlim(ax1,[x(1) x(end)])
set(ax1,'FontSize',16)
xlabel(ax1,xtitle);

if threshold, line(ax1,xlim,[threshold threshold],'Color','r'), end

if plotMarkerTimes
    if length(times) > 150
        disp('WARNING: There are more than 150 markers.')
        disp('This may take a long time to plot.')
        cont = input('Do you want to plot the marker positions? [y/n] >> ','s');
        if strcmpi(cont,'n')
            plotMarkerTimes = 0;
        end
    end
    
    if plotMarkerTimes
        title(ax1,'Plotting marker positions...')
        for i = 1:length(times)
            line(ax1,[times(i) times(i)] / srate,ylim,'Color','r')
            if i == 1, pause(0.1), end % script hangs without this line, no idea why
        end
        
        % make axis for threshold info
        ax2 = axes('Position',get(ax1,'Position'),...
                   'Color','none',...
                   'box','off');
        ylabel(ax2,'Threshold')
        set(ax2,...
            'YAxisLocation','Right',...
            'FontSize',16,...
            'XLim',get(ax1,'XLim'),...
            'YLim',get(ax1,'YLim'),...
            'XTick',[],...
            'YTick',threshold)
        
        % make axis for marker info
        ax3 = axes('Position',get(ax1,'Position'),...
                   'Color','none',...
                   'box','off');
        xlabels = 1:length(times);
        set(ax3,...
            'XAxisLocation','Top',...
            'FontSize',8,...
            'XLim',get(ax1,'XLim'),...
            'YLim',get(ax1,'YLim'),...
            'XTick',times,...
            'YTick',[],...
            'XTickLabel',cellstr(num2str(xlabels(:))))
        
    end
end

title(ax1,{[num2str(length(times)),' markers found. See command window for options...'];' '})

end
