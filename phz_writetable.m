function varargout = phz_writetable(PHZ,varargin)
%PHZ_WRITETABLE  Write grouping variables and features to a table.
% 
% usage:    PHZ = PHZ_WRITETABLE(PHZ,'feature',FEATURE)
%           PHZ = PHZ_WRITETABLE(PHZ,'Param1','Value1',etc.)
% 
% inputs:   PHZ       = PHZLAB data structure.
%           FEATURE   = A 'string' or {'cell' 'array' 'of' 'strings'}
%                       specfying the feature(s) to calculate. FEATURE is
%                       entered as a paramter/value pair so that the input
%                       format is the same as phz_plot.
%           'unstack' = Rearranges the table so that columns for grouping
%                       variables are "unstacked" across columns. Enter a
%                       maximum of 2 columns that should be unstacked. See
%                       examples for more details.
%           'save'    = Filename and path to save resultant table as either
%                       a MATLAB file (.mat) or text file of comma-
%                       separated values (.csv). The file extension
%                       determines the type of file.
%   
%           The following functions can be called as parameter/value pairs,
%           and are executed in the same order as they appear in the
%           function call. See the help of each function for more details.
%               'subset'    = Calls phz_subset.
%               'rectify'   = Calls phz_rect.
%               'filter'    = Calls phz_filter.
%               'smooth'    = Calls phz_smooth.
%               'transform' = Calls phz_transform.
%               'blc'       = Calls phz_blc.
%               'rej'       = Calls phz_rej.
%               'norm'      = Calls phz_norm.
% 
%           The following functions can be called as parameter/value pairs,
%           and are always executed in the order listed here, after all of
%           the processing funtions. See the help of each function for more
%           details.
%               'region'    = Calls phz_region.
%               'summary'   = Calls phz_summary. The default summary is
%                             'none', which returns all trials.
% 
% outputs:  d = MATLAB table.
% 
% examples:
%   d = phz_writetable(PHZ,'feature',{'mean','max'},'save','myfile.csv')
%       >> Finds the mean and max of each trial, and writes a .csv file
%          where each trial is a row, and all grouping variable headings
%          are present (i.e., participant, group, session, trials).
% 
%   d = phz_writetable(PHZ,'feature','mean','summary','trials')
%       >> Finds the mean of each trial, then averages across each trial
%          type. If there are 4 different trial types, then the table d
%          will contain 4 rows, one for each trial type.
% 
%   d = phz_writetable(PHZ,'feature','mean','unstack','trials')
%       >> Finds the mean of each trial type and unstacks the 'trials'
%          grouping variable column. The resultant headings of the table
%          will be: participant, group, session, mean_trialtype1,
%          mean_trialtype2, etc.
%           
% Written by Gabriel A. Nespoli 2016-03-07. Revised 2016-04-04.
if nargout == 0 && nargin == 0, help phz_writetable, return, end
if isempty(PHZ), PHZ = phz_gather; else PHZ = phz_check(PHZ); end

% defaults
feature = [];
region = [];
keepVars = {'all'};

unstackVars = [];

filename = {};
infoname = {};

verbose = true;

% user-defined
if any(strcmp(varargin(1:2:end),'verbose'))
    i = find(strcmp(varargin(1:2:end),'verbose')) * 2 - 1;
    verbose = varargin{i+1};
    varargin([i,i+1]) = [];
end

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        
        % do preprocessing in order of input
        case 'subset',                  PHZ = phz_subset(PHZ,varargin{i+1},verbose);
        case {'rect','rectify'},        PHZ = phz_rect(PHZ,varargin{i+1},verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,varargin{i+1},verbose);
        case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,varargin{i+1},verbose);
        case 'transform',               PHZ = phz_transform(PHZ,varargin{i+1},verbose);
        case {'blc','baselinecorrect'}, PHZ = phz_blc(PHZ,varargin{i+1},verbose);
        case {'rej','reject'},          PHZ = phz_rej(PHZ,varargin{i+1},verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,varargin{i+1},verbose);
        
        case 'region',                  region = varargin{i+1};
        case {'feature','features'},    feature = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
            
        case {'unstack','cast'},        unstackVars = varargin{i+1};
            
        case {'save','filename'},       filename = addToCell(filename,varargin{i+1});
        case {'info','infoname'},       infoname = addToCell(infoname,varargin{i+1});
            
    end
end

% verify input
if isempty(feature), error('A feature must be specified.'), end
if ~iscell(feature), feature = {feature}; end

% data preprocessing
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
        
        d = table(s.tags.(addVars{1}),'VariableNames',addVars(1));
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
            d.(addVars{j+1}) = s.tags.(addVars{j+1});
            d.Properties.VariableUnits{end} = '';
            d.Properties.VariableDescriptions{end} = '';
        end
    end
    
    % add feature data to table
    d.(s.feature) = s.data;
    d.Properties.VariableUnits{end} = s.units;
    d.Properties.VariableDescriptions{end} = featureTitle;
    
end

% unstack
if ~isempty(unstackVars)
    if ~iscell(unstackVars), unstackVars = {unstackVars}; end
    d = unstack(d,feature,unstackVars{1});
    
    if length(unstackVars) == 2
        dataVars = d.Properties.VariableNames;
        rm = ismember(dataVars,{'participant','group','session','trials'});
        dataVars(rm) = [];
        
        d = unstack(d,dataVars,unstackVars{2});
        
    elseif length(unstackVars) > 2, error('Cannot unstack more than 2 variables.')
    end
end

% finish up
checkForEmptyCells(d);
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

function checkForEmptyCells(d)
rm = [];
for i = 1:width(d)
    if ~isnumeric(d{:,i}), rm = [rm i]; end
end
temp = d;
temp(:,rm) = [];
if any(isnan(table2array(temp)))
    warning('There are empty cells in the data table.')
end
end

function C = addToCell(C,a)
if ischar(a), a = {a}; end
C = [C a];
end