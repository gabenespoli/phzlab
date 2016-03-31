function varargout = phz_writetable(PHZ,varargin)
%PHZ_WRITETABLE  Write grouping variables and features to a table.
% 
% D = PHZ_WRITETABLE(PHZS) writes calculates features and writes
%   the results to a table D including grouping variables. Each row in the
%   table represents on trial. If the 'keepVars' parameter is used 
%   (described below), then each row represents a unique combination of the
%   values in the grouping variables specified in 'keepVars'. A feature or
%   set of feature(s) must be specified using parameter/value pairs as a
%   string or cell array of strings, respectively.
% 
%   Processing options: These parameter names will call the function with 
%     the same name, using the specified value as input. See the help of 
%     each function for a more detailed explanation of what they do and 
%     how to use them.
%   'subset'    = Only export a subset of the data in PHZ.
%   'rect'      = Full- or half-wave rectification of PHZ.data.
%   'blc'       = Subtract the mean of a baseline region from PHZ.data.
%   'rej'       = Reject trials with values above a threshold.
%   'region'    = Restrict feature extraction or plotting to a region.
%   'summary'   = Summarize data by grouping variables (e.g., group, etc.).
%                 Default is 'all' (don't do any averaging).
% 
% PHZ_WRITETABLE(PHZS,FEATURES,...,'filename',FILENAME) saves the table as
%   a .mat or a .csv file depending on the file extension of FILENAME.
% 
% Written by Gabriel A. Nespoli 2016-03-07. Revised 2016-03-21.

if nargout == 0 && nargin == 0, help phz_writetable, return, end

% gather raw data
if ~(isstruct(PHZ) && phzUtil_isphzs(PHZ))
    error('Problem with PHZS input.')
end
% if isempty(PHZS),                               PHZS = phz_gather;
% elseif ischar(PHZS) && isdir(PHZS),             PHZS = phz_gather(PHZS);
% elseif isstruct(PHZS) && phzUtil_isphzs(PHZS),
% else error('Problem with PHZS input.')
% end

% defaults
subset = {};
rect = [];
transform = [];
blc = [];
rej = [];
normtype = [];
region = '';
feature = '';
keepVars = {'all'};

filename = {};
infoname = {};

verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'subset',                  subset = varargin{i+1};
        case {'rect','rectify'},        rect = varargin{i+1};
        case 'transform',               transform = varargin{i+1};
        case {'blc','baselinecorrect'}, blc = varargin{i+1};
        case {'rej','reject'},          rej = varargin{i+1};
        case {'norm','normtype'},       normtype = varargin{i+1};
        case 'region',                  region = varargin{i+1};
        case {'feature','features'},    feature = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
            
        case {'save','filename'},       filename = addToCell(filename,varargin{i+1});
        case {'info','infoname'},       infoname = addToCell(infoname,varargin{i+1});
            
        case 'verbose',                 verbose = varargin{i+1};
    end
end

% verify input
if ~iscell(feature), feature = {feature}; end

% data preprocessing
PHZ = phz_check(PHZ);
PHZ = phz_subset(PHZ,subset);
PHZ = phz_rect(PHZ,rect,verbose);
PHZ = phz_transform(PHZ,transform,verbose);
PHZ = phz_blc(PHZ,blc,verbose);
PHZ = phz_rej(PHZ,rej,verbose);
PHZ = phz_norm(PHZ,normtype);
PHZ = phz_region(PHZ,region,verbose);

disp('Calculating features...')
for i = 1:length(feature)
    
    [s,featureTitle] = phz_feature(PHZ,feature{i},'summary',keepVars,'verbose',verbose);
    % (run phz_summary through phz_feature because fft feature needs to average
    %  over the summaryType by participant before doing the fft)
    
    if size(s.data,2) > 1
        error('Can only export features that return a single value per trial.')
    end
    
    % create table on first loop
    if i == 1
        if ismember(keepVars,{'all'})
            addVars = {'participant','group','session','trials'};
        else addVars = keepVars;
        end
        
        d = table(s.(addVars{1}),'VariableNames',addVars(1));
        d.Properties.VariableUnits = {''};
        d.Properties.VariableDescriptions = {''};
        d.Properties.Description = [PHZ.study,' ',upper(PHZ.datatype),' data'];
        
        d.Properties.UserData.study = PHZ.study;
        d.Properties.UserData.datatype = PHZ.datatype;
        if ischar(PHZ.region), d.Properties.UserData.region = PHZ.region;
        else d.Properties.UserData.region = 'epoch';
        end
        d.Properties.UserData.files = PHZ.files;
        d.Properties.UserData.misc = PHZ.misc;
        d.Properties.UserData.history = PHZ.history;
        
        for j = 1:length(addVars) - 1
            d.(addVars{j+1}) = s.(addVars{j+1});
            d.Properties.VariableUnits{end} = '';
            d.Properties.VariableDescriptions{end} = '';
        end
    end
    
    % add feature data to table
    d.(s.feature) = s.data;
    d.Properties.VariableUnits{end} = s.units;
    d.Properties.VariableDescriptions{end} = featureTitle;
     
end

d = insertOtherInfo(d,infoname);
printOrSaveToFile(filename,d)
varargout{1} = d;
disp('Done exporting PHZ features.')
end

function printOrSaveToFile(filename,d)
if ~isempty(filename)
    for i = 1:length(filename)
        [~,~,ext] = fileparts(filename{i});
        switch ext
            case {'.mat'},          save(filename{i},'d')
            case {'.csv','.txt'},   writetable(d,filename{i})
        end
        disp(['Saved file ''',filename{i},'''.'])
    end
end
end

function d = insertOtherInfo(d,infoname)
if isempty(infoname), return, end
for i = 1:length(infoname)
    infodata = readtable(infoname{i});
    
    % check that group variables match and prompt for what to do
    if any(strcmp('group',infodata.Properties.VariableNames))
        disp(['There is also a GROUP variable in ',infoname{i}])
        disp('What would you like to do?')
        disp('1 - use the GROUP variable from the FFR data')
        disp(['2 - use the GROUP variable from ',infoname{i}])
        disp('3 - retain both GROUP variables')
        val = input('  >> ');
        
        switch val
            case 1, infodata.group = [];
            case 2, d.group = [];
            case 3
        end
        
    end
    
    try d = join(d,infodata,'Keys','participant');
    catch
        try d = join(d,infodata,'LeftKeys','participant','RightKeys','id');
        catch, warning(['No ''participant'' or ''id'' variable found in ''',infoname{i},'''.']);
        end
    end
end
end

function C = addToCell(C,a)
if ischar(a), a = {a}; end
C = [C a];
end