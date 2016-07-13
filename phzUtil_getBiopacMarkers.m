function [times,labels] = phzUtil_getBiopacMarkers(filename)

if nargin < 1, filename = []; end

if isempty(filename)
    [filename,folder] = uigetfile('*.txt');
    if isequal(filename,0) || isequal(folder,0), 
        disp('Aborting...')
        return
    end
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