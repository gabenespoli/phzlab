function groupingVars = phzUtil_readFilename(filename,namestr)
if isempty(namestr), return, end

% create empty output
groupingVars = struct(...
    'study',        '',...
    'datatype',     '',...
    'participant',  '',...
    'group',        '',...
    'condition',    '',...
    'session',      '');

if isempty(namestr), return, end

% find out which grpvars are in namestr & their order & their start/ends
vars = {'study','datatype','participant','group','condition','session'};
varsbeg = sort(cell2mat(regexp(namestr,vars,'start')));
varsend = sort(cell2mat(regexp(namestr,vars,'end')));
grpvars = cell(size(varsbeg));
for i = 1:length(grpvars), grpvars{i} = namestr(varsbeg(i):varsend(i)); end

% use start/ends to get delimstr that occur before & after each grpvar
% i.e., length(delimstr) = length(grpvars) + 1
delimstr = cell(1,length(grpvars) + 1);
for i = 1:length(delimstr)
    switch i
        
        case 1
            if varsbeg(i) == 1
                delimstr{i} = '';
            else
                delimstr{i} = namestr(1:varsbeg(i) - 1);
            end
            
        case length(delimstr)
            if varsend(i-1) == length(grpvars)
                delimstr{i} = ''; 
            else
                delimstr{i} = namestr(varsend(i-1) + 1:end);
            end
            
        otherwise
            delimstr{i} = namestr(varsend(i-1) + 1:varsbeg(i) - 1);
    end
end

if any(cellfun(@isempty,delimstr(2:end-1)))
    error('There must be some delimiter between grouping variables in the filename.'), end

[~,name,~] = fileparts(filename);

% move cursor past leading delimiter
if isempty(delimstr{1}), cursor = 1;
elseif strcmp(delimstr{1},name(1:length(delimstr{1})))
    cursor = 1 + length(delimstr{1});
else error(['Filename ''',name,''' doesn''t match the namestr.'])
end
delimstr(1) = []; % delimstr now holds delims that follow each grpvar

% loop through grpvars and get their vals from the filename
for i = 1:length(grpvars)
    
    if i == length(grpvars) && isempty(delimstr{i})
        groupingVars.(grpvars{i}) = name(cursor:end);
        
    else
        strend = min(strfind(name(cursor:end),delimstr{i}));
        groupingVars.(grpvars{i}) = name(cursor:cursor + strend - 2);
        cursor = cursor + strend + length(delimstr{i}) - 1;
    end
end


end