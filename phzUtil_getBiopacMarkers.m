% PHZUTIL_GETBIOPACMARKERS  Get marker times from Biopac journal text.
% 
% USAGE
%   times = phzUtil_getBiopacMarkers
%   times = phzUtil_getBiopacMarkers(filename)
%   times = phzUtil_getBiopacMarkers(
%   [times,labels] = phzUtil_getBiopacMarkers(...)
% 
% INPUT
%   filename  = [string] Optionally specify the journal file. If not
%               specified, a dialog box will pop up to choose a file.
%               Note that this file must be manually created from within
%               AcqKnowledge. The following steps to do so are taken from
%               the Biopac website "https://www.biopac.com/knowledge-base/
%               exporting-event-labels-into-matlab/":
% 
%               In AcqKnowledge, choose ?Display > Show > Event Palette?? 
%               (a toolbar button is also available for this at the far 
%               right edge of the events toolbar). Under ?Actions? click 
%               ?Summarize in Journal?. The journal will then have a list 
%               of lines such as:
%               1277.13 sec Skin Conductance Response CH1, GSR100C No label
% 
%               Copy the lines of the journal, paste them into a text file,
%               and save the file to disk as a .txt file. This is the file
%               that should be used as input for this function.
% 
% OUTPUT
%   times     = [numeric] A vector of times (in seconds) 
% 
%   labels    = [cell of strings] A cell array vector of strings, the same
%               length as TIMES, containing the labels associated with each
%               time.
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

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'filename',        filename = varargin{i+1};
        otherwise, warning(['Unknown parameter ''',varargin{i},'''.'])
    end
end

if isempty(filename)
    [filename,folder] = uigetfile('*.txt');
    filename = fullfile(folder,filename);
end


rmTimeFromLabels = true;


data = caseread(filename);
data = regexp(cellstr(data),'\t','split');

% strip html if journal file
[~,~,ext] = fileparts(filename);
if strcmp(ext,'.jcq'), data = convertJournalToText(data); end

% remove header stuff if present & convert to table
if isequal(data{1},{'Event Summary'}), data(1) = []; end
if isequal(data{1},{'Index' 'Time' 'Type' 'Channel' 'Label'}), data(1) = []; end
if isequal(data{1},{'0' '0.00 ns' 'Append' 'Global' 'Segment 1'}), data(1) = []; end

data = cat(1,data{:});
data = cell2table(data,'VariableNames',{'Index' 'Time' 'Type' 'Channel' 'Label'});

% convert times to numberic values in seconds
data.Time = convertTimesToSeconds(data.Time);



% show all event markers to the user, ask to remove some



% return a list of times and labels
if rmTimeFromLabels, data.Label = rmLabelTimeStamp(data.Label); end


times = data.Time;
labels = data.Label;


end

function times = convertTimesToSeconds(timeStr)
timeStr = regexp(timeStr,' ','split');
times = nan(size(timeStr));
for i = 1:length(timeStr)
    times(i) = str2double(timeStr{i}{1});
    switch timeStr{i}{2}
        case 'min', times(i) = times(i) * 60;
        case 'sec', % nothing to adjust
        otherwise, error(['Unknown time unit ''',timeStr{i}{2},'''.'])
    end
end
end

function labels = rmLabelTimeStamp(labels)

for i = 1:length(labels)
    if length(labels{i}) > 23
        testStr = labels{i}(end-22:end);
        if ismember(testStr(1:3),{'Mon','Tue','Wed','Thu','Fri','Sat','Sun'}) && ...
                ismember(testStr(5:7),{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'})
            labels{i} = labels{i}(1:end-23);
        end
    end
    labels{i} = strtrim(labels{i});
end
end

function data = convertJournalToText(data)
error('This function can''t read .jcq files yet.')
end