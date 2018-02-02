%PHZABR_EXPORTBT  Export ABR data in a format that can be imported into
%   Brainstem Toolbox (http://www.brainvolts.northwestern.edu/form/freeware.php)
%
% USAGE
%   phzABR_exportBT(PHZ, filename)
%   phzABR_exportBT(PHZ,'Param1','Value1',etc.)
%

function phzABR_exportBT(PHZ, filename, varargin)

if nargout == 0 && nargin == 0, help phzABR_exportToBT, return, end
PHZ = phz_check(PHZ);

% defaults
region = [];
force = 0;
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
        case {'rect','rectify'},        PHZ = phz_rectify(PHZ,varargin{i+1},verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,varargin{i+1},verbose);
        case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,varargin{i+1},verbose);
        case 'transform',               PHZ = phz_transform(PHZ,varargin{i+1},verbose);
        case {'blsub','blc'},           PHZ = phz_blsub(PHZ,varargin{i+1},verbose);
        case {'rej','reject'},          PHZ = phz_reject(PHZ,varargin{i+1},verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,varargin{i+1},verbose);
        
        case 'region',                  region = varargin{i+1};
        case {'force'},                 force = varargin{i+1};
    end
end

% data preprocessing
PHZ = phz_region(PHZ,region,verbose);
PHZ = phz_summary(PHZ, 'none'); % average across all trials

if ~isempty(filename)
    [pathstr, name, ext] = fileparts(filename);
    if ~strcmpi(ext, '.txt')
        disp('Changing file extension to .txt')
        filename = fullfile(pathstr, [name, '.txt']);
    end
    filename = phzUtil_getUniqueSaveName(filename, force);
end

if ~isempty(filename)
    fid = fopen(filename, 'w+');
    fprintf(fid, '%f\n', PHZ.data);
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