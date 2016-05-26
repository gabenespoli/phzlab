%PHZ_PROC  Use many processing functions with a single function call.
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
% 
% Written by Gabriel A. Nespoli 2016-04-11. Revised 2016-05-24.

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

varargin = convertStructsToParamValuePairs(varargin);

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'subset',                  PHZ = phz_subset(PHZ,varargin{i+1},verbose);
        case {'rect','rectify'},        PHZ = phz_rectify(PHZ,varargin{i+1},verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,varargin{i+1},verbose);
        case 'smooth',                  PHZ = phz_smooth(PHZ,varargin{i+1},verbose);
        case 'transform',               PHZ = phz_transform(PHZ,varargin{i+1},verbose);
        case {'blsub','blc'},           PHZ = phz_blsub(PHZ,varargin{i+1},verbose);
        case {'rej','reject'},          PHZ = phz_rej(PHZ,varargin{i+1},verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,varargin{i+1},verbose);
        
        case 'region',                  region = varargin{i+1};
        case 'feature',                 feature = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
    end
end

if ~isempty(feature) && ~strcmp(feature,'time'), PHZ = phz_region(PHZ,region,verbose); end
PHZ = phz_feature(PHZ,feature,'summary',keepVars,'verbose',verbose);

end

function opts = convertStructsToParamValuePairs(opts)























end