% PHZUTIL_GETBIOPACMARKERS  Get marker times from Biopac journal text.
% 
% USAGE
%   times = phzUtil_getBiopacMarkers
%   times = phzUtil_getBiopacMarkers('Param1',Value1,etc.)
%   [times,labels] = phzUtil_getBiopacMarkers(...)
% 
% INPUT
%   'filename'= [string] Optionally specify the journal file. If not
%               specified, a dialog box will pop up to choose a file.
%               Note that this file must be manually created from within
%               AcqKnowledge. The following steps to do so are taken from
%               the Biopac website "https://www.biopac.com/knowledge-base/
%               exporting-event-labels-into-matlab/":
% 
%                   In AcqKnowledge, choose ?Display > Show > Event 
%                   Palette...? (a toolbar button is also available for 
%                   this at the far right edge of the events toolbar). 
%                   Under ?Actions? click ?Summarize in Journal?. The 
%                   journal will then have a list of lines such as:
%                   
%                   1277.13 sec Skin Conductance Response CH1, 
%                   GSR100C No label
% 
%               Copy the lines of the journal, paste them into a text file,
%               and save the file to disk as a .txt file. This is the file
%               that should be used as input for this function.
% 
%   'eventTypes' = [string|cell of strings] Only return these event types.
%               Default (leave empty []) returns all event types (except
%               see 'rmAppendEvents' option).
% 
%   'rmAppendEvents' = [1|0] Removes events of the type 'Append'. When the 
%               acquisition type is set to 'Append', there is an 'Append'
%               event inserted every time you stop and start the recording.
%               Set this parameter to TRUE (1) to ignore these events or
%               FALSE (0) to keep them. Default 1.
% 
%   'rmTimeStamp' = [1|0] Removes the time stamp which can be
%               appended to the event labels. e.g., changes the label 
%               'User event Tue Jul 19 2016 12:41:30' to 'User event'.
%               Default 1.
% 
% OUTPUT
%   times     = [numeric] A vector of times (in seconds).
% 
%   labels    = [cell of strings] A cell array vector of strings, the
%               same length as TIMES, containing the labels associated 
%               with each time.
%   
% TOOLBOX DEPENDENCIES
%   Statistics and Machine Learning Toolbox
%     - caseread.m

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

function [times,labels] = phzUtil_getBiopacMarkers(varargin)

if nargin == 0 && nargout == 0, help phzUtil_getBiopacMarkers, return, end

filename = [];
eventTypes = [];
rmAppendEvents = true;
rmTimeStampFromLabels = true;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'filename',        filename = varargin{i+1};
        case 'eventtypes',      eventTypes = varargin{i+1};
        case 'rmappendevents',  rmAppendEvents = varargin{i+1};
        case 'rmtimestamp',     rmTimeStampFromLabels = varargin{i+1};
        otherwise, warning(['Unknown parameter ''',varargin{i},'''.'])
    end
end

if isempty(filename)
    [filename,folder] = uigetfile('*.txt');
    filename = fullfile(folder,filename);
end

% read data from file
data = caseread(filename); % need Stats Toolbox for caseread.m
data = regexp(cellstr(data),'\t','split');

% strip html if journal file
[~,~,ext] = fileparts(filename);
if strcmp(ext,'.jcq')
    error('This function can''t read .jcq files yet.')
end

% remove header stuff if present & convert to table
if isequal(data{1},{'Event Summary'}), data(1) = []; end
if isequal(data{1},{'Index' 'Time' 'Type' 'Channel' 'Label'}), data(1) = []; end
if isequal(data{1},{'0' '0.00 ns' 'Append' 'Global' 'Segment 1'}), data(1) = []; end

data = cat(1,data{:});
data = cell2table(data,'VariableNames',{'Index' 'Time' 'Type' 'Channel' 'Label'});

if rmAppendEvents
    data(categorical(data.Type) == 'Append',:) = [];
end

if ~isempty(eventTypes)
    if ischar(eventTypes), eventTypes = cellstr(eventTypes); end
    
    ind = zeros(size(data,1),1);
    for i = 1:length(eventTypes)
        
        temp = categorical(data.Type) == eventTypes{i};
        
        ind = ind + temp;
        
    end
        
    ind = logical(ind);
    data = data(ind,:);
    
end

data.Time = convertTimesToSeconds(data.Time);

% show all event markers to the user, ask to remove some


if rmTimeStampFromLabels
    data.Label = do_rmTimeStampFromLabel(data.Label);
end


times = data.Time;
labels = data.Label;


end

function times = convertTimesToSeconds(timeStr)
timeStr = regexp(timeStr,' ','split');
times = nan(size(timeStr));
for i = 1:length(timeStr)
    times(i) = str2double(timeStr{i}{1});
    switch timeStr{i}{2}
        case 'hrs', times(i) = times(i) * 60 * 60;
        case 'min', times(i) = times(i) * 60;
        case 'sec' % nothing to adjust
        otherwise, error(['Unknown time unit ''',timeStr{i}{2},'''.'])
    end
end
end

function labels = do_rmTimeStampFromLabel(labels)

dayStr = {'Mon','Tue','Wed','Thu','Fri','Sat','Sun'};
monthStr = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
dayNumStr = cellfun(@num2str,num2cell(1:31),'UniformOutput',false);

for i = 1:length(labels)
    if length(labels{i}) > 23
        temp = regexp(labels{i},' ','split');
        
        % check if there is a time stamp appended to the label
        if ismember(temp(end-4),dayStr) && ...
                ismember(temp(end-3),monthStr) && ...
                ismember(temp(end-2),dayNumStr) && ...
                length(temp{end-1}) == 4 && ...
                length(temp{end}) == 8
            
            switch length(temp(end-2))
                case 1, lengthOfTimeStamp = 23+1; % include leading space
                case 2, lengthOfTimeStamp = 24+1;
            end
            labels{i} = labels{i}(1:end-lengthOfTimeStamp);
        end
    end
    labels{i} = strtrim(labels{i});
end
end
