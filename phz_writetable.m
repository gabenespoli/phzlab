%PHZ_WRITETABLE  Write grouping variables and features to a table.
% 
% USAGE    
%   PHZ = phz_writetable(PHZ, 'Param1', 'Value1', etc.)
%   PHZ = phz_writetable(PHZ, preset, 'Param1','Value1',etc.)
% 
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
% 
%   preset    = [string] Presets can be specified in PHZ.lib.plots by
%               creating a field there (e.g., PHZ.lib.plots.plot1).
%               Default settings for this plot can be specified like
%               so: PHZ.lib.plots.plot1.smooth = 1. Putting the name
%               of the preset as the second argument (in this case
%               'plot1') is the same as inserting those arguments as
%               parameter-value pairs. Add other arguments after to
%               override the preset's default. 
% 
%   'unstack' = [string|cell of strings] Rearranges the table so that 
%               columns for grouping variables are "unstacked" across 
%               columns. Enter a maximum of 2 columns that should be 
%               unstacked. This is useful if you will be using SPSS
%               with a repeated measures design. See examples.
% 
%   'filename'= Filename and path to save resultant table as either a
%               MATLAB file (.mat) or text file of comma-separated values
%               (.csv). The file extension determines the type of file.
%
%   'force'   = See help phzUtil_getUniqueSaveName.
%   
%   The following functions can be called as parameter/value pairs,
%   and are executed in the same order as they appear in the
%   function call. See the help of each function for more details.
%   'subset'    = Calls phz_subset.
%   'rectify'   = Calls phz_rectify.
%   'filter'    = Calls phz_filter.
%   'smooth'    = Calls phz_smooth.
%   'transform' = Calls phz_transform.
%   'blsub'     = Calls phz_blsub.
%   'reject'    = Calls phz_reject.
%   'norm'      = Calls phz_norm.
% 
%   The following functions can be called as parameter/value pairs, and
%   are always executed in the order listed here, after all of the
%   processing funtions. See the help of each function for more details.
%   'region'    = Calls phz_region.
%   'feature'   = Calls phz_feature. Input can be a cell of many features
%                 or a string for a single feature.
%   'summary'   = Calls phz_summary.
%   'ffrsummary'= Calls phzFFR_summary. If specified, this is called 
%                 before phz_summary.
% 
% OUTPUT
%   d                 = [table] MATLAB table.
%   path/filename.csv = If the 'save' parameter is used, a comma delimited 
%                       values file of the table data is saved to disk.
% 
% EXAMPLES
%   phz_writetable(PHZ,'feature',{'mean','max'},'save','myfile.csv')
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

% Copyright (C) 2018 Gabriel A. Nespoli, gabenespoli@gmail.com
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

function varargout = phz_writetable(PHZ,varargin)

if nargout == 0 && nargin == 0, help phz_writetable, return, end
if isempty(PHZ)
    PHZ = phz_combine;
else
    PHZ = phz_check(PHZ);
end

% defaults
feature = [];
region = [];
keepVars = [];
summaryFunction = '';

unstackVars = [];

filename = {};
infoname = {};
force = 0;

verbose = true;

% user presets
if mod(length(varargin), 2) % if varargin is odd
    if ismember('tables', fieldnames(PHZ.lib)) && ...
        ismember(varargin{1}, fieldnames(PHZ.lib.tables))

        preset = phzUtil_struct2pairs(PHZ.lib.tables.(varargin{1}));
        varargin(1) = [];
        varargin = [preset varargin];

    else
        error(['Either the preset doesn''t exist in PHZ.lib.tables', ...
              ' or there are an invalid number of arguments.'])
    end
end

% user-defined
if any(strcmp(varargin(1:2:end),'verbose'))
    i = find(strcmp(varargin(1:2:end),'verbose')) * 2 - 1;
    verbose = varargin{i+1};
    varargin([i,i+1]) = [];
end

for i = 1:2:length(varargin)
    val = varargin{i+1};
    switch lower(varargin{i})
        
        % do preprocessing in order of input
        case 'subset',                  PHZ = phz_subset(PHZ,val,verbose);
        case {'rect','rectify'},        PHZ = phz_rectify(PHZ,val,verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,val,'verbose',verbose);
        case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,val,verbose);
        case 'transform',               PHZ = phz_transform(PHZ,val,verbose);
        case {'blsub','blc'},           PHZ = phz_blsub(PHZ,val,verbose);
        case {'rej','reject'},          PHZ = phz_reject(PHZ,val,verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,val,verbose);
        
        case 'region',                  region = val;
        case {'feature','features'},    feature = val;
        case {'summary','keepvars'},    keepVars = val;
        case {'ffrsummary','summaryfunction'}, summaryFunction = val;
            
        case {'unstack','cast'},        unstackVars = val;
            
        case {'save','filename','file'},filename = addToCell(filename,val);
        case {'info','infoname'},       infoname = addToCell(infoname,val);
        case {'force'},                 force = val;
            
    end
end

% verify input
if isempty(feature), error('A feature must be specified.'), end
if ~iscell(feature), feature = {feature}; end
if ischar(keepVars), keepVars = cellstr(keepVars); end
if ~isempty(summaryFunction), PHZ = phzFFR_summary(PHZ, summaryFunction, verbose); end

disp('  Calculating features...')
for i = 1:length(feature)
    fprintf('\n  Feature %i/%i: %s\n', i, length(feature), feature{i})
    
    [s,featureTitle] = phz_feature(PHZ,feature{i},'summary',keepVars,'region',region,'verbose',verbose);
    % (run phz_summary through phz_feature because fft feature needs to average
    %  over the summaryType by participant before doing the fft)
    
    if size(s.data,2) > 1
        error('Can only export features that return a single value per trial.')
    end
    
    % create table on first loop
    if i == 1
        if isempty(keepVars) || ( length(keepVars) == 1 && strcmp(keepVars{1},'all') )
            addVars = {'participant','group','condition','session','trials'};
        else
            addVars = cellstr(keepVars);
        end
        
        if length(keepVars) == 1 && strcmp(keepVars{1},'none')
            d = table({'all'}, 'VariableNames',{'trials'});
        else
            d = table(s.lib.tags.(addVars{1}),'VariableNames',addVars(1));
        end
        d.Properties.VariableUnits = {''};
        d.Properties.VariableDescriptions = {''};
        d.Properties.Description = [PHZ.study,' ',upper(PHZ.datatype),' data'];
        
        d.Properties.UserData.study = PHZ.study;
        d.Properties.UserData.datatype = PHZ.datatype;
        if ischar(PHZ.region)
            d.Properties.UserData.region = PHZ.region;
        else
            d.Properties.UserData.region = 'epoch';
        end
        
        if ismember('files',fieldnames(PHZ.lib))
            d.Properties.UserData.files = PHZ.lib.files;
        elseif ismember('create',fieldnames(PHZ.proc)) && ismember('datafile',fieldnames(PHZ.proc.create))
            d.Properties.UserData.files = PHZ.proc.create.datafile;
        end

        d.Properties.UserData.etc = PHZ.etc;
        d.Properties.UserData.history = PHZ.history;
        
        for j = 1:length(addVars) - 1
            if ~strcmp(s.lib.tags.(addVars{j+1}),'<collapsed>')
                d.(addVars{j+1}) = s.lib.tags.(addVars{j+1});
                d.Properties.VariableUnits{end} = '';
                d.Properties.VariableDescriptions{end} = '';
            end
        end
    end
    
    % add feature data to table
    s.proc.feature = strrep(s.proc.feature,'-','_');
    s.proc.feature = strrep(s.proc.feature,':','to');
    d.(s.proc.feature) = s.data;
    d.Properties.VariableUnits{end} = s.units;
    d.Properties.VariableDescriptions{end} = featureTitle;
    
end

% unstack
if ~isempty(unstackVars)
    d = phzUtil_unstack2(d,feature,unstackVars);
end

% finish up
checkForEmptyCells(d);
d = insertOtherInfo(d,infoname);
printOrSaveToFile(filename,d,force)
varargout{1} = d;
disp('  Done exporting PHZ features.')
end

function printOrSaveToFile(filename,d,force)
if ~isempty(filename)
    for i = 1:length(filename)
        fname = filename{i};
        if islogical(fname) && ~fname, continue, end
        fname = phzUtil_getUniqueSaveName(fname,force);
        if isempty(fname), continue, end
        [~,~,ext] = fileparts(fname);
        switch ext
            case {'.mat'},          save(fname,'d')
            case {'.csv','.txt'},   writetable(d,fname)
        end
        disp(['  Saved file ''',fname,'''.'])
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
        disp('1 - use the GROUP variable from the PHZ data')
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
    if ~isnumeric(d{:,i}), rm = [rm i]; end %#ok<AGROW>
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
