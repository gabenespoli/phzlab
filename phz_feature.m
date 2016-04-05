function [PHZ,featureTitle] = phz_feature(PHZ,feature,varargin)
%PHZ_FEATURE  Calculate the specified feature on each trial.
% 
% usage:    PHZ = phz_feature(PHZ,FEATURE)
%           PHZ = phz_feature(PHZ,FEATURE,'Param1,'Value1',etc.)
% 
% inputs:   PHZ       = PHZLAB data structure.
%           FEATURE   = String specifying the desired feature. Possible
%                       features are listed below.
%           'region'  = Calls phz_region to restrict the time or frequency 
%                       region used for feature extration.
%           'summary' = Summarizes the resulting features by averaging 
%                       across grouping variables. For FFT, this averaging 
%                       is done before calulating the FFT; different 
%                       participants are kept separate for this averaging. 
%                       See phz_summary for more details.
% 
%           Time-domain features:
%           'mean'        = Average value.
%           'max','min'   = Maximum or minimum value.
%           'maxi','mini' = Time (latency) of the max or min (in seconds).
%           'rms'         = Root-mean-square of the specified region(s).
%           'slope'       = The max slope of tangents to each point of the 
%                           data after data are smoothed with a moving 
%                           point average.
%           'slopei'      = Time of maximum slope.
%           'area'        = Area under the curve.
%           ''            = (blank) returns time-series data.
% 
%           Frequency-domain features:
%           'fft'         = Amplitude spectrum. Trials are averaged 
%                           together in the time domain before calculating.
%           'fft100'      = Entering 'fft' followed by a number will
%                           calculate the value of the FFT at that 
%                           frequency (e.g., 'fft100' returns the value of
%                           the 100 Hz bin).
%           'fft100-1'    = Additionally specifies the number of bins on 
%                           either side of the specified bin to include in 
%                           an average (e.g., 'fft100-1' returns the 
%                           average of 3 bins centered on 100 Hz).
%           'itfft'       = Intertrial FFT. Whereas the 'fft' feature 
%                           averages trials before caluclating the FFT,
%                           'itfft' calculates the FFT on each trial before 
%                           averaging trials together.
%           'itpc'        = Intertrial phase coherence.
%           'itrc'        = Intertrial response consistency (FFR feature).
%
%           Behavioural features:
%           'acc','acc2',... = Accuracy value in PHZ.resp.q1_acc, q2, etc.
%           'rt','rt2',...   = Reaction time in PHZ.resp.q1_rt, q2, etc.
% 
%           Note: For all features except 'acc' and 'rt', data are 
%                 returned for non-rejected trials. For 'acc' and 'rt', 
%                 all trials are included regardless of whether or not 
%                 they are rejected.
%
% outputs:  PHZ.data    = The data of the extracted feature for each trial.
%           PHZ.feature = The value specified in FEATURE.
% 
% examples:
%   PHZ = phz_feature(PHZ,'mean')
% 
% Written by Gabriel A. Nespoli 2016-02-15. Revised 2016-04-04.
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

% prepare
[PHZ,feature,val] = parseFeature(PHZ,feature);
if isempty(region) && isstruct(PHZ.region), PHZ.region = 'whole epoch';
else PHZ = phz_region(PHZ,region,verbose);
end

% make container table and get time-series data or features
% ---------------------------------------------------------
switch lower(feature)
    
    case {'time'}
        featureTitle = '';
        
    case {'itfft'}
        featureTitle = 'Intertrial FFT';
        PHZ = phzUtil_getfft(PHZ,'verbose',verbose);
        
    case 'fft' % first summaryType (getdata), then getfft (& binmean)
        featureTitle = 'FFT';
        
        % summarize data first
        if any(ismember({'participant','all','none'},keepVars))
            PHZ = phz_summary(PHZ,keepVars);
        else % add 'participant' to summaryType if not already
            PHZ = phz_summary(PHZ,[{'participant'} keepVars]);
        end
        
        % get fft
        PHZ = phzUtil_getfft(PHZ,'verbose',verbose);
        
    case 'itpc'
        % if PHZS has already been summary'd, phzUtil_itpc will have to
        %   load each file again to calculate it
        
    case 'itrc'
        % if PHZS has already been summary'd, phzUtil_itrc will have to
        %   load each file again to calculate it
        
    otherwise % features
        
        % if resp data, include all trials
        if ismember(feature,{'acc','acc1','acc2','acc3','acc4','acc5',...
                'rt', 'rt1', 'rt2', 'rt3', 'rt4', 'rt5'})
            PHZ = phz_rej(PHZ,0,0); % restore all metadata
        end
        
        % calculate feature
        switch lower(feature)
            case {'mean'}, featureTitle = 'Mean';                        PHZ.data  = mean(PHZ.data,2);
            case {'max'}, featureTitle = 'Max';                          PHZ.data  = max(PHZ.data,[],2);
            case {'min'}, featureTitle = 'Min';                          PHZ.data  = min(PHZ.data,[],2);
            case {'maxi','maxlatency'}, featureTitle = 'Max Latency'; [~,PHZ.data] = max(PHZ.data,[],2);
            case {'mini','minlatency'}, featureTitle = 'Min Latency'; [~,PHZ.data] = min(PHZ.data,[],2);
            case {'rms'}, featureTitle = 'RMS';                          PHZ.data  = rms(PHZ.data,2);
            case {'area'}, featureTitle = 'Area Under Curve';            PHZ.data  = trapz(PHZ.data,2);   
            case {'slope','slopei','slopelatency'} % find maximum slope
                PHZ.data = phzUtil_smooth(PHZ.data);
                temp = nan(size(PHZ.data,1),2);
                for i = 1:size(PHZ.data,1)
                    [temp(i,1),temp(i,2)] = max(gradient(PHZ.data(i,:)));
                end
                switch feature
                    case 'slope', featureTitle = 'Max Slope';                           temp(:,2) = [];
                    case {'slopei','slopelatency'}, featureTitle = 'Max Slope Latency'; temp(:,1) = [];
                end
                PHZ.data = temp; 
            case {'acc','acc1','acc2','acc3','acc4','acc5'}
                featureTitle = 'Accuracy';
                if strcmp(feature,'acc'), feature = 'acc1'; end
                PHZ.data = PHZ.resp.(['q',feature(4),'_acc']);
                if all(ismember(PHZ.data,[0 1]))
                    PHZ.data = PHZ.data * 100;
                    PHZ.units = '%';
                else PHZ.units = '';
                end
            case {'rt', 'rt1', 'rt2', 'rt3', 'rt4', 'rt5'}
                featureTitle = 'Reaction Time';
                if strcmp(feature,'rt'), feature = 'rt1'; end
                PHZ.data = PHZ.resp.(['q',feature(3),'_rt']);
                PHZ.units = 's';
            otherwise, error('Unknown feature.')
        end
        
        % convert from indices to times if feature is latency
        switch feature
            case {'maxi','mini','latency','maxlatency','minlatency','slopelatency'}
                PHZ.data = PHZ.times(PHZ.data)';
                PHZ.units = 's';
            case {'auc','area'}
                PHZ.units = [PHZ.units,'^2'];
        end
        
        % cleanup PHZ
        if ismember('times',fieldnames(PHZ)), indField = 'times';
        elseif ismember('freqs',fieldnames(PHZ)), indField = 'freqs';
        end
        PHZ = rmfield(PHZ,indField);
        
end

% if isempty(PHZ.region), PHZ.region = 'epoch'; end
if ~strcmp(PHZ.feature,'time')
    PHZ = phzUtil_history(PHZ,['Extracted feature ''',feature,'''.'],verbose);
end

% apply summary
PHZ = phz_summary(PHZ,keepVars,verbose);

% binmean
if ~isempty(val)
    featureTitle = [featureTitle,' at ',num2str(val(1)),' Hz'];
    PHZ = phzUtil_binmean(PHZ,val(1),val(2));
end

end

function [PHZ,feature,val] = parseFeature(PHZ,feature)
if isempty(feature), feature = 'time'; end
if ~ischar(feature), error('FEATURE should be a string.'), end
PHZ.feature = feature;

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
end

% convert val(s) to numeric ([freq binWidth]
if ~isempty(val)
    ind = strfind(val,'-');
    if ind, val = [str2double(val(1:ind - 1)) str2double(val(ind + 1:end))];
    else val = [str2double(val) 0];
    end
end
end