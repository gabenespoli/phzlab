%PHZ_FEATURE  Convert each trial to the specified feature.
%
% USAGE
%   PHZ = phz_feature(PHZ,feature)
%   PHZ = phz_feature(PHZ,feature,'Param1',Value1,etc.)
%   [PHZ, featureTitle, preSummaryData] = phz_feature(PHZ,...)
%
% INPUT
%   PHZ       = PHZLAB data structure.
%
%   feature   = [string] Specifies the desired feature. Possible
%               features are listed below.
%
%   'region'  = Calls phz_region.m to restrict the time or frequency
%               region used for feature extration.
%
%   'summary' = Summarizes the resulting features by averaging
%               across grouping variables. For FFT, this averaging
%               is done before calulating the FFT; different
%               participants are kept separate for this averaging.
%               See phz_summary for more details.
%
%   'discard' = [1|0] Calls phz_discard.m to discard trials that were
%               marked for rejection before calculating the feature.
%               Enter 1 to discard or 0 to keep all trials regardless
%               of trials marked for discarding (i.e., from phz_reject,
%               phz_review, or phz_subset). Default 1.
%
%   Time-domain features:
%   'mean'        = Average value.
%
%   'max','min'   = Maximum or minimum value.
%
%   'maxi','mini' = Time (latency) of the max or min (in seconds).
%
%   'rms'         = Root-mean-square of the specified region(s).
%
%   'slope'       = The max slope of tangents to each point of the
%                   data after they are smoothed with a moving point
%                   average.
%
%   'slopei'      = Time of maximum slope.
%
%   'area'        = Area under the curve.
%
%   ''            = (blank) returns time-series data.
%
%   Frequency-domain features:
%   'fft'         = Amplitude spectrum. Trials are averaged together in
%                   the time domain before calculating (kind of like an
%                   "evoked" average).
%
%   'fft100'      = Entering 'fft' followed by a number will calculate
%                   the value of the FFT at that frequency (e.g.,
%                   'fft100' returns the value of the 100 Hz bin).
%
%   'fft100-1'    = Additionally specifies the number of bins on
%                   either side of the specified bin to include in
%                   an average (e.g., 'fft100-1' returns the average
%                   of 3 bins centered on 100 Hz).
%
%   'fft100:200'  = Using a colon will return the average over the range of
%                   frequiencies.
%
%   'itfft'       = Intertrial FFT. Whereas the 'fft' feature averages
%                   trials before caluclating the FFT, 'itfft' calculates
%                   the FFT on each trial before averaging trials together.
%                   (kind of like an "induced" average).
%
%   'itpc'        = Intertrial phase coherence.
% 
%   'src','srclag'= Stimulus-response correlation or lag. Returns the
%                   r-value or the time in seconds of the maximum
%                   cross-correlation between each epoch and a stimulus
%                   waveform. The stimulus waveform must be provided in
%                   PHZ.lib.stim and must be the same length as a single
%                   trial. SRC is usually used for ABR data. Note that SRC 
%                   will operate on each row of PHZ.data. If you are 
%                   dealing with ABR responses, you probably want to
%                   average across trials first (e.g., with phz_summary)
%                   before calculating src.
% 
%   'snr'         = Signal-to-Noise Ratio. By default, SNR divides the RMS
%                   of the target region by the RMS of the baseline region
%                   (as specified in PHZ.region). Enter in the form 
%                   'snr-target-baseline' to change regions.
%
%   Behavioural features:
%   'acc','acc2',...  = Accuracy value in PHZ.resp.q1_acc, q2, etc.
%
%   'rt','rt2',...    = Reaction time in PHZ.resp.q1_rt, q2, etc.
%
% OUTPUT
%   PHZ.data            = The data of the extracted feature for each trial.
%   PHZ.proc.feature    = The value specified in FEATURE.
%   featureTitle        = A string describing the feature. Used for plots.
%   preSummaryData      = Optional output from phz_summary.
%
% EXAMPLES
%   PHZ = phz_feature(PHZ,'mean')

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

function [PHZ, featureTitle, preSummaryData] = phz_feature(PHZ, feature, varargin)

if nargout == 0 && nargin == 0, help phz_feature, return, end

% defaults
region = [];
keepVars = [];
do_discard = true;
verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch varargin{i}
        case 'region',               region = varargin{i+1};
        case {'summary','keepvars'}, keepVars = varargin{i+1};
        case 'discard',              do_discard = varargin{i+1};
        case 'verbose',              verbose = varargin{i+1};
    end
end
if isempty(keepVars), keepVars = ''; end

% parse feature input
if isempty(feature), feature = 'time'; end
[PHZ,featureStr,val] = parseFeature(PHZ,feature);

if do_discard
    PHZ = phz_discard(PHZ, verbose);
end

% restrict to region
if ( isempty(region) && isstruct(PHZ.region) ) || ... % PHZ.region = 'whole epoch';
        ( ismember(featureStr, {'snr'}) )
else
    PHZ = phz_region(PHZ,region,verbose);
end

% calculate feature
%   each case MUST set a featureTitle, and will usually adjust
%       PHZ.data and PHZ.units.
switch lower(featureStr)

    case 'time'
        featureTitle = '';

    case 'mean'
        featureTitle = 'Mean';
        PHZ.data  = mean(PHZ.data,2);

    case 'max'
        featureTitle = 'Max';
        PHZ.data  = max(PHZ.data,[],2);

    case 'min'
        featureTitle = 'Min';
        PHZ.data  = min(PHZ.data,[],2);

    case 'maxi'
        featureTitle = 'Max Latency';
        [~,ind] = max(PHZ.data,[],2);
        PHZ.data = PHZ.times(ind)';
        PHZ.units = 's';

    case 'mini'
        featureTitle = 'Min Latency';
        [~,ind] = min(PHZ.data,[],2);
        PHZ.data = PHZ.times(ind)';
        PHZ.units = 's';

    case 'slope'
        featureTitle = 'Max Slope';
        PHZ = phz_smooth(PHZ,'mean0.05');
        maxSlope = nan(size(PHZ.data,1),1);
        for i = 1:size(PHZ.data,1), maxSlope(i) = max(gradient(PHZ.data(i,:))); end
        PHZ.data = maxSlope;
        PHZ.units = '';

    case 'slopei'
        featureTitle = 'Max Slope Latency';
        PHZ = phz_smooth(PHZ,'mean0.05');
        ind = nan(size(PHZ.data,1),1);
        for i = 1:size(PHZ.data,1), [~,ind(i)] = max(gradient(PHZ.data(i,:))); end
        PHZ.data = PHZ.times(ind)';
        PHZ.units = 's';

    case {'rms'}
        featureTitle = 'RMS';
        PHZ.data  = rms(PHZ.data,2);

    case {'area'}
        featureTitle = 'Area Under Curve';
        PHZ.data  = trapz(PHZ.data,2);
        PHZ.units = [PHZ.units,'^2'];

    case {'acc','acc1','acc2','acc3','acc4','acc5'}
        featureTitle = 'Accuracy';
        if strcmp(feature,'acc'), feature = 'acc1'; end
        PHZ.data = PHZ.resp.(['q',feature(4),'_acc']);
        if all(ismember(PHZ.data,[0 1]))
            PHZ.data = PHZ.data * 100;
            PHZ.units = '%';
        else
            PHZ.units = '';
        end

    case {'rt', 'rt1', 'rt2', 'rt3', 'rt4', 'rt5'}
        featureTitle = 'Reaction Time';
        PHZ.units = 's';
        if strcmp(feature,'rt'), feature = 'rt1'; end
        PHZ.data = PHZ.resp.(['q',feature(3),'_rt']);

    case 'itfft'
        % get fft of each trial
        [PHZ,featureTitle] = phzFeature_fft(PHZ);
        featureTitle = ['Intertrial ',featureTitle];

    case 'fft'
        % summarize in time domain (adding 'participant' to summary if it isn't already)
        if any(ismember({'participant','all','none'},keepVars))
            PHZ = phz_summary(PHZ,keepVars);
        elseif length(PHZ.participant) > 1
            PHZ = phz_summary(PHZ,[{'participant'} keepVars]);
        end

        % get fft of each summary
        [PHZ,featureTitle] = phzFeature_fft(PHZ);

    case 'itpc'
        featureTitle = 'Intertrial Phase Coherence';

        % Method adapted from Tierney & Kraus, 2013, Journal of Neuroscience.

        % get complex fft
        PHZ = phzFeature_fft(PHZ, 'spectrum', 'complex');

        % transform each vector to a unit vector (magnitude of 1)
        PHZ.data = PHZ.data ./ abs(PHZ.data);
        PHZ.data(isnan(PHZ.data)) = 0;

        % summarize (adding 'participant' to summary if it isn't already)
        if any(ismember({'participant','all','none'}, keepVars))
            PHZ = phz_summary(PHZ,keepVars);
        else
            PHZ = phz_summary(PHZ, [{'participant'} keepVars]);
        end

        % average trials
        PHZ = phz_summary(PHZ,keepVars);

        % magnitude of resultant vector is the measure of phase coherence
        PHZ.data = abs(PHZ.data);

%     case 'itrc', featureTitle = 'Intertrial Phase Consistency';
        % Method adapted from Tierney & Kraus, 2013, Journal of Neuroscience.
        
        % if PHZS has already been summary'd, phzFeature_itrc will have to
        %   load each file again to calculate it
        
        % calls phz_summary, which calls phzFeature_itrc

    case 'src'
        if ~ismember('stim', fieldnames(PHZ.lib))
            error('Cannot find stim field in PHZ.lib.')
        end
        featureTitle = 'Stimulus-Response Correlation';
        PHZ.units = '';
        PHZ.data = phzFeature_src(PHZ.data,PHZ.lib.stim,PHZ.srate,val);

        % note: SRC will operate on each row of PHZ.data (i.e. each trial).
        %   If you are dealing with ABR responses, you don't want each
        %   trial to actually be a single trial, but rather the averaged
        %   response of many trials from a single participant or condition.
        %   This comment also applies to 'srclag'.

    case 'srclag'
        if ~ismember('stim', fieldnames(PHZ.lib))
            error('Cannot find stim field in PHZ.lib.')
        end
        featureTitle = 'Stimulus-Response Lag';
        PHZ.units = 's';
        [~,PHZ.data] = phzFeature_src(PHZ.data,PHZ.lib.stim,PHZ.srate,val);

        % note: See comment above in the 'src' section.

    case 'snr'
        featureTitle = 'Signal-to-Noise Ratio';
        PHZ.units = 'SNR';

        % method taken from Skoe & Kraus (2010) Ear & Hearing
        tg = phz_region(PHZ,val{1},false);              bl = phz_region(PHZ,val{2},false);
        tg = phz_transform(tg,'^2',false);              bl = phz_transform(bl,'^2',false);
        tg = phz_feature(tg,'mean','verbose',false);    bl = phz_feature(bl,'mean','verbose',false);
        tg = phz_transform(tg,'sqrt',false);            bl = phz_transform(bl,'sqrt',false);

        PHZ.data = tg.data ./ bl.data;
        PHZ.region = [val{1},' / ',val{2}]; % this has to be done last

    otherwise, error([feature,' is an unknown feature.'])
end

% this must be done after the feature extraction in case preprocessing
%   needs to be undone and redone (e.g., for acc or rt)
PHZ.proc.feature = feature;

if isempty(region) && isstruct(PHZ.region), PHZ.region = 'whole epoch'; end

% adjust PHZ and PHZ.proc fields
if size(PHZ.data,2) == 1
    if ismember('times',fieldnames(PHZ)), PHZ = rmfield(PHZ,'times'); end
    if ismember('freqs',fieldnames(PHZ)), PHZ = rmfield(PHZ,'freqs'); end
end

if ismember('rej',fieldnames(PHZ.proc)) % phzlab version < 1
    PHZ.proc.rej.data = []; end

if ismember('blc',fieldnames(PHZ.proc)) % phzlab version < 1
    PHZ.proc.blc.values = []; end

if ismember('blsub',fieldnames(PHZ.proc)) % phzlab version > 1
    PHZ.proc.blsub.values = []; end

if ismember('norm',fieldnames(PHZ.proc))
    PHZ.proc.norm.mean = []; PHZ.proc.norm.stDev = []; end

if ~strcmp(PHZ.proc.feature,'time')
    PHZ = phz_history(PHZ,['Extracted feature ''',feature,'''.'],verbose); end

% apply summary
[PHZ, preSummaryData] = phz_summary(PHZ,keepVars,verbose);

% binmean for spectral features
if ~isempty(val) && length(val) == 3
    method = val{3};
    val = cellfun(@eval,val(1:2));

    if strcmp(method, '-') % bin width
        featureTitle = [featureTitle,' at ',num2str(val(1)),...
        ' Hz +/- ', num2str(val(2)), ' bins'];
        PHZ = phzUtil_binmean(PHZ,val(1),val(2));
        PHZ.freqs = val(1);

    elseif strcmp(method, ':') % range
        featureTitle = [featureTitle,' from ',num2str(val(1)),...
                        ' to ',num2str(val(2)),' Hz'];
        ind = phzUtil_getind(PHZ.freqs, val);
        PHZ.data = mean(PHZ.data(:,ind(1):ind(2)),2);
        PHZ.freqs = val;
    end
end

end

function [PHZ,featureStr,val] = parseFeature(PHZ,feature)
if ~ischar(feature), error('FEATURE should be a string.'), end

% split feature and val
val = [];
if length(feature) >= 3 && strcmp(feature(1:3),'fft')
    if length(feature) > 3, val = feature(4:end); end
    featureStr = 'fft';

elseif length(feature) >= 5 && strcmp(feature(1:5),'itfft')
    if length(feature) > 5, val = feature(6:end); end
    featureStr = 'itfft';

elseif length(feature) >= 4 && strcmp(feature(1:4),'itpc')
    if length(feature) > 4, val = feature(5:end); end
    featureStr = 'itpc';

elseif length(feature) >= 4 && strcmp(feature(1:4),'itrc')
    if length(feature) > 4, val = feature(5:end); end
    featureStr = 'itrc';

elseif length(feature) == 3 && strcmp(feature,'snr')
    val = 'target-baseline';
    featureStr = feature;

elseif length(feature) >= 4 && strcmp(feature(1:4),'snr-')
    if length(feature) > 4, val = feature(5:end); end
    featureStr = 'snr';

else
    featureStr = feature;

end

% convert val(s) to numeric ([freq binWidth]) or cell ({baseline target})
if ~isempty(val)
    indHyphen = strfind(val,'-');
    indColon = strfind(val,':');
    if ~isempty(indHyphen) && ~isempty(indColon)
        error('Cannot specify both a bin width with ''-'' and a range with '':''.')
    elseif ~isempty(indHyphen)
        method = '-';
        ind = indHyphen;
    elseif ~isempty(indColon)
        method = ':';
        ind = indColon;
    elseif ~strcmp(featureStr, 'snr')
        val = {val '0' ':'}; % default one bin, bin width of 0
    end

    % set value of val
    if ~isempty(indHyphen) || ~isempty(indColon)
        val = {val(1:ind - 1), val(ind + 1:end)};
        if ~strcmp(featureStr, 'snr')
            val{3} = method;
        end
    else
    end

end
end

