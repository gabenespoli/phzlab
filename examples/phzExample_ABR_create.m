%PHZEXAMPLE_ABR
%   Create PHZ files from Biopac AcqKnowledge files that have been saved
%   as .mat files. 
%
% USAGE
%   PHZ = ffr_process(filename, stimulus)
%
% INPUT
%   filename  = [string] Full filepath and filename to the .mat file that
%               was exported from Biopac AcqKnowledge.   
%
%   stimulus  = [vector] The audio stimulus that will be used for more
%               precise extraction of marker times from the audio channel,
%               and for auto-labelling trials with their polarity.
%
% OUTPUT
%   PHZ      = [struct] PHZLAB data structure.
%

function PHZ = phzExample_ABR_create(filename, stimulus)

%% create PHZ variable from file
% PHZLAB knows the format of Biopac AcqKnowledge files that have been
% saved as .mat files. With filetype = 'acq', PHZLAB will automatically
% obtain the sampling rate, datatype, and units. These can be overridden
% with parameter-value pairs.
PHZ = phz_create( ...
    'filename',     filename, ...
    'filetype',     'acq', ...
    'channel',      1, ...
    'datatype',     'ABR', ...
    'units',        'V');

%% Some pre-epoching preprocessing
% convert to microvolts (uV)
% gain on Biopac amplifier was 10000
PHZ = phzBiopac_transform(PHZ, 10000, 'u');

% filter 60Hz line noise
% we could filter after epoching, but we might get edge effects
PHZ = phz_filter(PHZ, [0 0 60]);

%% Add stimulus information
% time regions of interest
PHZ.region.baseline = [-0.04 0];
PHZ.region.target   = [0.06 0.17]; % steadystate
PHZ.region.target2  = [0.01 0.06]; % transition
PHZ.region.target3  = [0 0.01];    % onset

% add stimulus waveform
% should be a vector of the waveform played on each trial
% should be the same length as each epoch, so that the regions of
%   interest are the same for both
da = load(stimulus);
PHZ.etc.stim = da.stim;

%% Split data into epochs
% 1. First find marker times and get polarity labels
% use phz_create to extract audio channel from Biopac mat file
markerData = phz_create('filename', 'data/filename.mat', ...
                        'channel',  2);

% get marker times and polarity labels
[times, xcorrInfo] = phzUtil_findAudioMarkers( ...
    markerData.data, ...
    0.05, ...                    % threshold
    0.08 * markerData.srate, ... % timeBetween in samples
    'window',      [-0.04 0.213] * markerData.srate, ... % convert to samples
    'stimulus',    PHZ.etc.stim, ... % precise times and auto-label polarities
    'plotMarkers', false); % ABR has too many trials for reliable plotting here

% 2. Then split the file and label the trials
% split data into epochs
PHZ = phz_epoch(PHZ, ...
    [-0.04 0.213], ... % window around each marker to extract
    times, ...
    'timeUnits', 'samples');

% add trial (polarity) labels from xcorrInfo
PHZ = phz_labels(PHZ, xcorrInfo.labels);

% make sure the stim is the same size as the epoch
if size(PHZ.etc.stim,2) ~= size(PHZ.data,2)
    warning('PHZ.etc.stim is not the same length as a trial.')
end

end
