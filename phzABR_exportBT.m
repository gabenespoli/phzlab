%PHZABR_EXPORTBT  Export ABR data in a format that can be imported into
%   Brainstem Toolbox (http://www.brainvolts.northwestern.edu/form/freeware.php)
%
% USAGE
%   phzABR_exportBT(PHZ, filename)
%   phzABR_exportBT(PHZ,'Param1','Value1',etc.)
%
% INPUT
%   PHZ         = [struct] PHZLAB data structure.
%
%   filename    = [string] Filename to save the data as text. Extension
%                 should be .txt.
%
%   'stimulus   = [true|false] Export the waveform in PHZ.etc.stim
%                   instead. Default false.
%
%   'force'     = [0|1|2] See phzUtil_getUniqueSaveName.m.
%
%   These are executed in the order that they appear in the function call. 
%   See the help of each function for more details.
%   'subset'    = Calls phz_subset.
%   'rectify'   = Calls phz_rect.
%   'filter'    = Calls phz_filter.
%   'smooth'    = Calls phz_smooth.
%   'transform' = Calls phz_transform.
%   'blsub'     = Calls phz_blsub.
%   'rej'       = Calls phz_reject.
%   'norm'      = Calls phz_norm.
% 
%   These are always executed in the order listed here, after the above
%   processing funtions. See the help of each function for more details.
%   'region'    = Calls phz_region.
% 
%   'summary'   = ['add'|'sub'] Calls phzABR_summary.m.
%

function PHZ = phzABR_exportBT(PHZ, filename, varargin)

if nargout == 0 && nargin == 0, help phzABR_exportToBT, return, end
PHZ = phz_check(PHZ);

% defaults
verbose = true;
force = 0;
stimulus = false;
region = [];
summaryFunction = 'add';

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
        case {'rect','rectify'},        PHZ = phz_rectify(PHZ,varargin{i+1},verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,varargin{i+1},verbose);
        case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,varargin{i+1},verbose);
        case 'transform',               PHZ = phz_transform(PHZ,varargin{i+1},verbose);
        case {'blsub','blc'},           PHZ = phz_blsub(PHZ,varargin{i+1},verbose);
        case {'rej','reject'},          PHZ = phz_reject(PHZ,varargin{i+1},verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,varargin{i+1},verbose);
        
        case 'region',                  region = varargin{i+1};
        case {'force'},                 force = varargin{i+1};
        case {'summaryfunction','summary'}, summaryFunction = varargin{i+1};
        case {'stimulus','stim'},       stimulus = varargin{i+1};
    end
end

if stimulus
    data = PHZ.etc.stim;

else
    % data preprocessing
    PHZ = phz_region(PHZ, region, verbose);
    PHZ = phzABR_summary(PHZ, summaryFunction, verbose);
    if size(PHZ.data, 1) > 1
        PHZ = phz_summary(PHZ, 'none'); % average across all trials
    end
    data = PHZ.data;
end

% get filename
if ~isempty(filename)
    [pathstr, name, ext] = fileparts(filename);
    if ~strcmpi(ext, '.txt')
        disp('Changing file extension to .txt')
        filename = fullfile(pathstr, [name, '.txt']);
    end
    filename = phzUtil_getUniqueSaveName(filename, force);
    if isempty(filename), return, end
end

% save to disk
if ~isempty(filename)
    fid = fopen(filename, 'w+');
    fprintf(fid, '%f\n', data);
    fclose(fid);
    fprintf('\n')
    fprintf(['  Now you can use the following command to create an ', ...
            'avg file \n', ...
            '  using the bt_txt2avg function from Brainstem Toolbox.\n', ...
            '  Note that it is Windows-only.\n'])
    fprintf('   bt_txt2avg(''%s'', %i, %g, %g)\n', ...
            filename, PHZ.srate, PHZ.times(1)*1000, PHZ.times(end)*1000)
else
    disp('No valid filename was specified.')
end

end
