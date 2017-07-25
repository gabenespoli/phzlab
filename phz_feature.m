%PHZ_FEATURE  Convert each trial to the specified feature.
%
% USAGE
%   PHZ = phz_feature(PHZ,feature)
%   PHZ = phz_feature(PHZ,feature,'Param1',Value1,etc.)
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
%                   the time domain before calculating.
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
%   'itfft'       = Intertrial FFT. Whereas the 'fft' feature averages
%                   trials before caluclating the FFT, 'itfft' calculates
%                   the FFT on each trial before averaging trials together.
%
%   'itpc'        = Intertrial phase coherence.
% 
%   'src','srclag'= Stimulus-response correlation or lag. Returns the
%                   r-value or the time in seconds of the maximum
%                   cross-correlation between each epoch and a stimulus
%                   waveform. The stimulus waveform must be provided in
%                   PHZ.misc.stim and must be the same length as a single
%                   trial. SRC is usually used for FFR data. Note that SRC 
%                   will operate on each row of PHZ.data. If you are 
%                   dealing with FFR responses, you probably want to
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
%   Note: For all features except 'acc' and 'rt', data are returned for
%         non-rejected trials. For 'acc' and 'rt', all trials are included
%         regardless of whether or not they are rejected.
%
% OUTPUT
%   PHZ.data            = The data of the extracted feature for each trial.
%   PHZ.proc.feature    = The value specified in FEATURE.
%
% EXAMPLES
%   PHZ = phz_feature(PHZ,'mean')

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

function [PHZ,featureTitle] = phz_feature(PHZ,feature,varargin)

if nargout == 0 && nargin == 0, help phz_feature, return, end

% defaults
region = [];
keepVars = [];
verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch varargin{i}
        case 'region',               region = varargin{i+1};
        case {'summary','keepvars'}, keepVars = varargin{i+1};
        case 'verbose',              verbose = varargin{i+1};
    end
end
if isempty(keepVars), keepVars = ''; end

% parse feature input
[PHZ,feature,val] = parseFeature(PHZ,feature);

% restrict to region
if isempty(region) && isstruct(PHZ.region), % PHZ.region = 'whole epoch';
else PHZ = phz_region(PHZ,region,verbose);
end

% calculate feature
%   each case MUST set a featureTitle, and will usually adjust
%       PHZ.data and PHZ.units.
switch lower(feature)
    
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
        PHZ = phz_rej(PHZ,0,0); % restore all metadata
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
        PHZ = phz_rej(PHZ,0,0); % restore all metadata
        if strcmp(feature,'rt'), feature = 'rt1'; end
        PHZ.data = PHZ.resp.(['q',feature(3),'_rt']);
        
    case 'itfft'
        % get fft of each trial
        [PHZ.data,PHZ.freqs,PHZ.units,featureTitle] = phzFeature_fft(PHZ.data,PHZ.srate,PHZ.units);
        PHZ = rmfield(PHZ,'times');
        featureTitle = ['Intertrial ',featureTitle];
        
    case 'fft'
        % summarize in time domain (adding 'participant' to summary if it isn't already)
        if any(ismember({'participant','all','none'},keepVars))
            PHZ = phz_summary(PHZ,keepVars);
        else
            PHZ = phz_summary(PHZ,[{'participant'} keepVars]);
        end
        
        % get fft of each summary
        [PHZ.data,PHZ.freqs,PHZ.units,featureTitle] = phzFeature_fft(PHZ.data,PHZ.srate,PHZ.units);
        PHZ = rmfield(PHZ,'times');
        
    case 'itpc'
        featureTitle = 'Intertrial Phase Coherence';
        % Method adapted from Tierney & Kraus, 2013, Journal of Neuroscience.
        
        if ~ismember('summary', fieldnames(PHZ.proc)) && ~ismember('summary', fieldnames(PHZ.proc.pre))
            
            % summarize (adding 'participant' to summary if it isn't already)
            if any(ismember({'participant','all','none'}, keepVars))
                PHZ = phz_summary(PHZ,keepVars);
            else
                PHZ = phz_summary(PHZ, [{'participant'} keepVars]);
            end
            
            PHZ = phzFeature_itpc(PHZ, keepVars);
            
        else
            
            % if PHZS has already been summary'd, phzFeature_itpc will have to
            %   load each file again to calculate it
            newData = [];
            trialsPerFile = size(PHZ.data,1) / length(PHZ.meta.files);
            
            for i = 1:length(PHZ.meta.files)
                disp(['Calculating ITPC for file ',...
                    num2str(i),'/',num2str(length(PHZ.meta.files)),...
                    ': ''',PHZ.meta.files{i},''''])
                TMP = phz_load(PHZ.meta.files{i});
                TMP = phz_proc(TMP,PHZ.proc.pre(i));
                TMP = phzFeature_itpc(TMP,PHZ.proc.pre(i).summary.keepVars);
                
                j = 1 + (i-1) * trialsPerFile;
                newData(j:j+trialsPerFile-1,:) = TMP.data;
            end
            PHZ.data = newData;
            PHZ.freqs = TMP.freqs;
            PHZ = rmfield(PHZ,'times');
        end
        
%     case 'itrc', featureTitle = 'Intertrial Phase Consistency';
        % Method adapted from Tierney & Kraus, 2013, Journal of Neuroscience.
        
        % if PHZS has already been summary'd, phzFeature_itrc will have to
        %   load each file again to calculate it
        
        % calls phz_summary, which calls phzFeature_itrc


    case 'src'
        featureTitle = 'Stimulus-Response Correlation';
        PHZ.units = '';
        PHZ.data = phzFeature_src(PHZ.data,PHZ.misc.stim,PHZ.srate,val);
        
        % note: SRC will operate on each row of PHZ.data (i.e. each trial).
        %   If you are dealing with FFR responses, you don't want each
        %   trial to actually be a single trial, but rather the averaged
        %   response of many trials from a single participant or condition.
        %   This comment also applies to 'srclag'.
        
    case 'srclag'
        featureTitle = 'Stimulus-Response Lag';
        PHZ.units = 's';
        [~,PHZ.data] = phzFeature_src(PHZ.data,PHZ.misc.stim,PHZ.srate,val);
        
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

if isempty(region) && isstruct(PHZ.region), PHZ.region = 'whole epoch'; end

% adjust PHZ and PHZ.proc fields
if size(PHZ.data,2) == 1
    if ismember('times',fieldnames(PHZ)), PHZ = rmfield(PHZ,'times'); end
    if ismember('freqs',fieldnames(PHZ)), PHZ = rmfield(PHZ,'freqs'); end
end

if ismember('rej',fieldnames(PHZ.proc))
    PHZ.proc.rej.data = []; end

if ismember('blc',fieldnames(PHZ.proc))
    PHZ.proc.blc.values = []; end

if ismember('norm',fieldnames(PHZ.proc))
    PHZ.proc.norm.mean = []; PHZ.proc.norm.stDev = []; end

if ~strcmp(PHZ.proc.feature,'time')
    PHZ = phz_history(PHZ,['Extracted feature ''',feature,'''.'],verbose); end

% apply summary
PHZ = phz_summary(PHZ,keepVars,verbose);

% binmean for spectral features
if ~isempty(val) && isnumeric(val)
    featureTitle = [featureTitle,' at ',num2str(val(1)),' Hz'];
    PHZ = phzUtil_binmean(PHZ,val(1),val(2));
    PHZ.freqs = val(1);
end

end

function [PHZ,feature,val] = parseFeature(PHZ,feature)
if isempty(feature), feature = 'time'; end
if ~ischar(feature), error('FEATURE should be a string.'), end
PHZ.proc.feature = feature;

% split feature and val
val = [];
if length(feature) >= 3 && strcmp(feature(1:3),'fft')
    if length(feature) > 3, val = feature(4:end); end
    feature = 'fft';
    
elseif length(feature) >= 5 && strcmp(feature(1:5),'itfft')
    if length(feature) > 5, val = feature(6:end); end
    feature = 'itfft';
    
elseif length(feature) >= 4 && strcmp(feature(1:4),'itpc')
    if length(feature) > 4, val = feature(5:end); end
    feature = 'itpc';
    
elseif length(feature) >= 4 && strcmp(feature(1:4),'itrc')
    if length(feature) > 4, val = feature(5:end); end
    feature = 'itrc';

elseif length(feature) == 3 && strcmp(feature,'snr')
    val = 'target-baseline';
    
elseif length(feature) >= 4 && strcmp(feature(1:4),'snr-')
    if length(feature) > 4, val = feature(5:end); end
    feature = 'snr';
end

% convert val(s) to numeric ([freq binWidth]) or cell ({baseline target})
if ~isempty(val)
    ind = strfind(val,'-');
    if ind, val = {val(1:ind - 1) val(ind + 1:end)};
    else val = {val '0'}; % default if no bin width specified
    end
    
    % convert to numeric if possible
    try val = cellfun(@eval,val);
    catch
    end
    
end
end

