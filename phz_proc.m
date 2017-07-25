%PHZ_PROC  Use many processing functions with a single function call.
%   Input can be parameter/value pairs, or a structure variable, i.e.,
%   the PHZ.proc field.
% 
% USAGE
%   phz_proc(PHZ,'Param1',Value1,etc.)
% 
% INPUT
%   PHZ         = PHZLAB data structure.
% 
%   These are executed in the order that they appear in the function call. 
%   See the help of each function for more details.
% 
%   'subset'    = Calls phz_subset.
%   'rectify'   = Calls phz_rect.
%   'filter'    = Calls phz_filter.
%   'smooth'    = Calls phz_smooth.
%   'transform' = Calls phz_transform.
%   'blc'       = Calls phz_blc.
%   'rej'       = Calls phz_rej.
%   'norm'      = Calls phz_norm.
% 
%   These are always executed after the above processing functions, and in 
%   the order listed here. See the help of each function for more details.
% 
%   'region'    = Calls phz_region.
%   'feature'   = Calls phz_feature and makes bar plots instead of line
%                 plots (excepting FFT and ITPC).
%   'summary'   = Calls phz_summary. The default summary is 'all', which 
%                 averages across all trials. A maximum of 2 summary 
%                 variables can be specified; the first is plotted as 
%                 separate lines/bars, and the second is plotted across
%                 separate plots.
% 
% OUTPUT
%   PHZ   = Processed PHZLAB data structure.

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

function PHZ = phz_proc(PHZ,varargin)

if nargin == 0 && nargout == 0, help phz_proc, return, end

% defaults
region = [];
feature = [];
keepVars = [];

verbose = true;

% user-defined
if any(strcmp(varargin(1:2:end),'verbose'))
    i = find(strcmp(varargin(1:2:end),'verbose')) * 2 - 1;
    verbose = varargin{i+1};
    varargin([i,i+1]) = [];
end

opts = varargin;
opts = convertStructsToParamValuePairs(opts);

for i = 1:2:length(opts)
    switch lower(opts{i})
        case 'subset',                  PHZ = phz_subset(PHZ,opts{i+1},verbose);
        case {'rect','rectify'},        PHZ = phz_rectify(PHZ,opts{i+1},verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,opts{i+1},'verbose',verbose);
        case 'smooth',                  PHZ = phz_smooth(PHZ,opts{i+1},verbose);
        case 'transform',               PHZ = phz_transform(PHZ,opts{i+1},verbose);
        case {'blsub','blc'},           PHZ = phz_blsub(PHZ,opts{i+1},verbose);
        case {'rej','reject'},          PHZ = phz_rej(PHZ,opts{i+1},verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,opts{i+1},verbose);
        
        case 'region',                  region = opts{i+1};
        case 'feature',                 feature = opts{i+1};
        case {'summary','keepvars'},    keepVars = opts{i+1};
    end
end

if ~isempty(feature) && ~strcmp(feature,'time')
    PHZ = phz_region(PHZ,region,verbose);
end

PHZ = phz_feature(PHZ,feature,'summary',keepVars,'verbose',verbose);

end

function optsOut = convertStructsToParamValuePairs(optsIn)
optsOut = {};
for i = 1:length(optsIn)
    if isstruct(optsIn{i})
        procs = fieldnames(optsIn{i});
        for j = 1:length(procs)
            switch procs{j}
                % case 'subset', optsOut = appendToCell(optsOut, {'blsub', optsIn{i}.blsub.region});
                case 'rectify'      optsOut = appendToCell(optsOut, {'rectify', optsIn{i}.rectify});
                case 'filter',      optsOut = appendToCell(optsOut, {'filter', [optsIn{i}.filter.hipass optsIn{i}.filter.lopass optsIn{i}.notch]});
                case 'smooth',      optsOut = appendToCell(optsOut, {'smooth', optsIn{i}.smooth});
                case 'transform',   optsOut = appendToCell(optsOut, {'transform', optsIn{i}.transform.transform});
                case 'blsub',       optsOut = appendToCell(optsOut, {'blsub', optsIn{i}.blsub.region});
                case 'rej',         optsOut = appendToCell(optsOut, {'rej', optsIn{i}.rej.threshold});
                case 'norm',        optsOut = appendToCell(optsOut, {'norm', optsIn{i}.norm.type});
            end
            
        end

    else
        optsOut = appendToCell(optsOut, optsIn{i});

    end
end
end

function cellOut = appendToCell(cellIn,cellToAppend)
if ~iscell(cellToAppend), cellToAppend = {cellToAppend}; end
if ~iscell(cellIn),       cellIn = {cellIn}; end
cellOut = [cellIn, cellToAppend];
end
