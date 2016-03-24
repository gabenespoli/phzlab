function phz_plot(PHZ,varargin)
%PHZ_PLOT  Plot data from PHZ and PHZS structures.
% 
% PHZ_PLOT(PHZ,'Param1','Value1',...) plots the values in PHZ.data.
%   PHZ_PLOT will plot a line graph or a bar graph with standard error bars 
%   depending on the kind of data or feature specified.
% 
%   Processing options: These parameter names will call the function with 
%     the same name, using the specified value as input. See the help of 
%     each function for a more detailed explanation of what they do and 
%     how to use them.
%   'subset'    = Only plot a subset of the data in PHZ.
%   'rect'      = Full- or half-wave rectification of PHZ.data.
%   'blc'       = Subtract the mean of a baseline region from PHZ.data.
%   'rej'       = Reject trials with values above a threshold.
%   'region'    = Restrict feature extraction or plotting to a region.
%   'feature'   = Plot a feature (e.g., mean, max, fft, etc.).
%   'summary'   = Plot data by grouping variables (e.g., group, etc.).
%                 Default is 'none' (average all trials together). A
%                 maximum of 2 summary types are allowed for plotting; the
%                 first type will be plotted as separate lines/bars, and
%                 the second will be plotted across different plots.
% 
%   Plotting options: These parameter names modify how the plot looks.
%   'smooth'    = For line plots, apply a moving point average.
%   'dispn'     = Display the number of trials or participants included
%                 in each line or bar plotted. Enter 'participant',
%                 'trials', 'both', or 'none' (default).
%   'legend'    = For line plots, specify the location of the legend.
%                 Enter 'nw' (default) for top-left, etc., or ''
%                 (empty) to suppress the legend.
%   'linewidth' = For line plots, specify the width of the line in
%                 pixels. Default 2.
%   'fontsize'  = Specify the size of the font in plots. Default 14.
% 
%   'xl'        = For line plots, Specify the x-axis limits in seconds
%                 or Hertz for time and frequency plots respectively.
%   'yl'        = Specify the y-axis limits of plots.
%   'sameyl'    = Force the positive and negative y-axis limit to be
%                 the same. If data are roughly centered on zero, this
%                 is applied automatically. Enter 1 (true) or 0 (false)
%                 to manually use this functionality.
%
%   'participant_order', 'group_order', 'session_order', 'trials_order',
%       and 'region_order' specify the plot order and overrides the value
%       in PHZ.spec.
% 
%   'participant_spec', 'group_spec', 'session_spec', 'trials_spec',
%       and 'region_spec' specify the colour of the corresponding value in
%       '*_order'.
%
% See also PHZ_SUBSET, PHZ_RECT, PHZ_BLC, PHZ_REJ, PHZ_REGION, PHZ_FEATURE,
%   PHZ_SUMMARY
%
% Written by Gabriel A. Nespoli 2016-02-16. Revised 2016-03-22.

if nargout == 0 && nargin == 0, help phz_plot, return, end

% defaults
subset = {};
rect = '';
blc = [];
rej = [];
region = '';
feature = '';
keepVars = {'none'};

do_smoothing = false;
dispn = 'none'; % '(empty)','none','participant','trials','both'
legendLoc = 'nw';
linewidth = 2;
fontsize = 14;

yl = [];
xl = [];
sameyl = [];

spec.participant_order = {};
spec.participant_spec = {};
spec.group_order = {};
spec.group_spec = {};
spec.session_order = {};
spec.session_spec = {};
spec.trials_order = {};
spec.trials_spec = {};
spec.region_order = {};
spec.region_spec = {};

verbose = true;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'subset',                                  subset = varargin{i+1};
        case {'rect','rectify'},                        rect = varargin{i+1};
        case {'blc','baselinecorrect'},                 blc = varargin{i+1};
        case {'rej','reject'},                          rej = varargin{i+1};
        case 'region',                                  region = varargin{i+1};
        case 'feature',                                 feature = varargin{i+1};
        case {'summary','keepvars'},                    keepVars = varargin{i+1};
            
        case {'smooth','smoothing'},                    do_smoothing = varargin{i+1};
        case {'dispn','n'},                             dispn = varargin{i+1};    
        case {'legend','legendloc'},                    legendLoc = varargin{i+1};            
        case {'linewidth','lineweight'},                linewidth = varargin{i+1};
        case 'fontsize',                                fontsize = varargin{i+1};
            
        case {'yl','ylim'},                             yl = varargin{i+1};
        case {'xl','xlim'},                             xl = varargin{i+1};
        case 'sameyl',                                  sameyl = varargin{i+1};
            
        case {'participant_order','participantorder'},  spec.participant_order = varargin{i+1};
        case {'participant_spec','participantspec'},    spec.participant_spec = varargin{i+1};
        case {'group_order','grouporder'},              spec.group_order = varargin{i+1};
        case {'group_spec','groupspec'},                spec.group_spec = varargin{i+1};
        case {'session_order','sessionorder'},          spec.session_order = varargin{i+1};
        case {'session_spec','sessionspec'},            spec.session_spec = varargin{i+1};
        case {'trials_order','trialsorder'},            spec.trials_order = varargin{i+1};
        case {'trials_spec','trialsspec'},              spec.trials_spec = varargin{i+1};
        case {'region_order','regionorder'},            spec.region_order = varargin{i+1};
        case {'regionregion_spec','spec'},              spec.region_spec = varargin{i+1};
            
        case 'verbose',                                 verbose = varargin{i+1};
            
        otherwise, warning(['Parameter ''',varargin{i},''' is not ',...
                'recognized and will be ignored.'])
    end
end

if length(cellstr(keepVars)) > 2, error('Cannot plot more than 2 summary types.'), end

% data preprocessing
PHZ = phz_check(PHZ);
PHZ = phz_subset(PHZ,subset);
PHZ = phz_rect(PHZ,rect,verbose);
PHZ = phz_blc(PHZ,blc,verbose);
PHZ = phz_rej(PHZ,rej,verbose);
if ~isempty(feature) && ~strcmp(feature,'time'), PHZ = phz_region(PHZ,region,verbose); end
[PHZ,featureTitle] = phz_feature(PHZ,feature,'summary',keepVars,'verbose',verbose);
% (run phz_summary through phz_feature because fft feature needs to average
%  over the summaryType by participant before doing the fft)

% prepare to plot
[spec,lineOrder,lineLabels,lineSpec,plotOrder,plotLabels] = getLabelsAndSpec(PHZ,spec,dispn);
% linePlotTypes = {'','time','fft','itfft','itpc'};
[rows,cols,pos,ytitleLoc,xtitleLoc] = getPlotDims(plotLabels);
if isempty(yl), yl = nan(length(plotLabels),2); do_yl = true; else do_yl = false; end
if isempty(xl), xl = nan(size(yl));    do_xl = true; else do_xl = false; end
ytitle = getytitle(PHZ,feature,legendLoc,do_smoothing,featureTitle);

% loop plots and plot lines/bars
% ------------------------------
figure('units','normalized','outerposition',pos)
for j = 1:length(plotOrder)
    
    % loop lines/bars
    for i = 1:length(lineOrder)
        subplot(rows,cols,j)
        
        % reset stdError containers
        if i == 1
            stdErrorLocs = nan(length(lineOrder),size(PHZ.data,2));
            stdError = nan(length(lineOrder),1);
        end
        
        % get indices of current data
        switch length(PHZ.summary.keepVars)
            case 1
                if ismember(PHZ.summary.keepVars{1},{' ','none'}) || isempty(PHZ.summary.keepVars{1})
                    ind = 1;
                else ind = find(PHZ.(PHZ.summary.keepVars{1}) == lineOrder{i});
                end
                
            case 2
                ind = intersect(find(PHZ.(PHZ.summary.keepVars{1}) == lineOrder{i}),...
                    find(PHZ.(PHZ.summary.keepVars{2}) == plotOrder{j}));
        end
        
        y = PHZ.data(ind,:);
        stdErrorLocs(i,:) = y;
        stdError(i,:) = PHZ.summary.stdError(ind);
        
%         lineLabel = lineOrder{i};
        
%         if ismember(feature,linePlotTypes)
        if size(PHZ.data,2) > 1
            
            % line plots of time-series or fft data
            if ismember('times',fieldnames(PHZ)),     x = PHZ.times;
            elseif ismember('freqs',fieldnames(PHZ)), x = PHZ.freqs;
            end
            
            if do_smoothing % x-axis limits become shorter with smoothing
                [y,ind] = phzUtil_smooth(y);
                x = x(ind);
            end
            plot(x,y,lineSpec{i},...
                'DisplayName',lineLabels{i,j},...
                'LineWidth',linewidth)
            if i == 1, hold on, end
            
        else
            
            % bar plots of feature values
            h = bar(i,y);
            if i == 1, hold on, end
            if ~isempty(lineSpec{i})
                set(h,'FaceColor',lineSpec{i}(1))
                if length(lineSpec{i}) > 2
                    if strcmp(lineSpec{i}(2:3),'--')
                        currentColor = get(h,'FaceColor') + 0.7;
                        currentColor(currentColor > 1) = 1;
                        set(h,'FaceColor',currentColor)
                    end
                end
            end
        end
    end
    
    % label plot, add errorbars
    title(plotLabels{j})
    if isempty(ytitleLoc) || ytitleLoc == j, ylabel(ytitle), end
    
    if ismember(feature,{'fft','itfft','itpc'}) % FFT / PC plots
        if isempty(xtitleLoc) || xtitleLoc == j, xlabel('Frequency (Hz)'), end
        
    elseif ismember(feature,{'','time'}) % time series plots
        if isempty(xtitleLoc) || xtitleLoc == j, xlabel('Time (s)'), end
        
    else
        % bar plots of feature values
        set(gca,'XTick',1:length(lineOrder),...
            'XTickLabel',lineLabels(:,j))
        errorbar(1:length(lineOrder),...
            stdErrorLocs,...
            stdError,'.k');    
    end
    
    % record axes ranges
    if do_yl, yl(j,:) = ylim; end
%     if do_xl, xl(j,:) = xlim; end
    
    hold off
end

% get min/max axes ranges
if do_yl
    yl = [min(yl(:,1)) max(yl(:,2))];
    
    % if data are centered on zero, set +ve and -ve limit to same
    if isempty(sameyl)
        if yl(1) / yl(2) < -0.5 && yl(1) / yl(2) > -2, sameyl = true;
        else sameyl = false;
        end
    end
    if sameyl, yl = [-(max(abs(yl))) (max(abs(yl)))]; end
end

% if do_xl && ismember(feature,linePlotTypes)
if do_xl && size(PHZ.data,2) > 1
    xl = [x(1) x(end)];
end

% loop plots and apply formatting
% -------------------------------
for j = 1:length(plotLabels)
    subplot(rows,cols,j)
    
    % set y- and x-axis ranges
    ylim(yl)
%     if ismember(feature,linePlotTypes)
    if size(PHZ.data,2) > 1
        xlim(xl)
    end
    
    % create coloured regions to indicate ROIs
    if ~isempty(region) && (isempty(feature) || strcmp(feature,'time'))
        if ~iscell(region), region = {region}; end
        
        % loop display regions
        for k = 1:length(region)
            
            % convert regions to endpoints
            if ischar(region{k})
                try region{k} = PHZ.region.(region{k});
                catch, region{k} = str2num(region{k});
                end
            end
            if isnumeric(region{k}) && length(region{k}) == 2
                x = [region{k}(1),...
                    region{k}(1),...
                    region{k}(2),...
                    region{k}(2)];
                y = [yl(1) yl(2) yl(2) yl(1)];
                obj = patch(x,y,spec.region_spec{k},'EdgeColor','none',...
                    'DisplayName',spec.region_order{k});
                alpha(obj,0.1) % make translucent
            end
        end
    end
    
    % add legend
%     if ismember(feature,linePlotTypes) && ~isempty(legendLoc)
    if size(PHZ.data,2) > 1 && ~isempty(legendLoc)
        legend('-DynamicLegend','Location',legendLoc)
    end
    
    % adjust font size
    set(gca,'FontSize',fontsize)
    
end

% Done phz_plot
end

function [spec,lineOrder,lineLabels,lineSpec,plotOrder,plotLabels,plotSpec] = getLabelsAndSpec(PHZ,spec,dispn)

% get order and spec
for i = {'participant','group','session','trials','region'}
    for j = {'order','spec'}
        if isempty(spec.([i{1},'_',j{1}]))
            spec.([i{1},'_',j{1}]) = PHZ.spec.([i{1},'_',j{1}]);
        else % verify spec
            switch j
                case 'order'
                    if ~all(ismember(spec.([i{1},'_',j{1}]),PHZ.spec.([i{1},'_',j{1}])))
                        error(['User-defined spec ''',i{1},'_',j{1},''' does not have the correct labels.'])
                    end
                case 'spec'
                    if length(spec.([i{1},'_',j{1}])) ~= length(PHZ.spec.([i{1},'_',j{1}]))
                        error(['User-defined spec ''',i{1},'_',j{1},''' does not have the correct number of specs.'])
                    end
            end
        end
    end
end

% lines/bars
if ismember(PHZ.summary.keepVars{1},{' ','none'}) || isempty(PHZ.summary.keepVars{1})
    lineOrder = {'All trials'};
    lineSpec = {''};
else
    lineOrder = PHZ.spec.([PHZ.summary.keepVars{1},'_order']);
    if ~isempty(spec.([PHZ.summary.keepVars{1},'_spec']))
        lineSpec = spec.([PHZ.summary.keepVars{1},'_spec']);
    else lineSpec = repmat({''},1,length(PHZ.spec.([PHZ.summary.keepVars{1},'_order'])));
    end
end

% plots
if length(PHZ.summary.keepVars) == 1
    if length(PHZ.participant) > 1 || isundefined(PHZ.participant)
        plotOrder = {'All participants'};
    else plotOrder = {['Participant ',char(PHZ.participant)]};
    end
    plotSpec = {''};
else 
    plotOrder = PHZ.spec.([PHZ.summary.keepVars{2},'_order']);
    if ~isempty(spec.([PHZ.summary.keepVars{2},'_spec']))
        plotSpec = spec.([PHZ.summary.keepVars{2},'_spec']);
    else plotSpec = repmat({''},1,length(PHZ.spec.([PHZ.summary.keepVars{2},'_order'])));
    end
end

% duplicate labels as need to make it the same size as d
if ~isempty(lineOrder)
    if ~iscolumn(lineOrder)
        if isrow(lineOrder), lineOrder = lineOrder'; end
    end
end
lineLabels = repmat(lineOrder,1,length(plotOrder));
plotLabels = plotOrder;

% add n's
if ~ismember(dispn,{'none',''})
    switch dispn
        case {'participant','participants'}, np = 1; nt = 0;
        case {'trials','trial'},             np = 0; nt = 1;
        case {'both','all'},                 np = 1; nt = 1;
    end
    
    % add n's to labels for lines/bars
    switch PHZ.summary.keepVars{1}
        case 'all'
            if nt
                lineLabels{1} = [lineLabels{1},' (',num2str(PHZ.summary.nTrials),')'];
            end
            
        case 'trials'
            if nt
                for i = 1:numel(PHZ.summary.nTrials)
                    lineLabels{i} = [lineLabels{i},' (',num2str(PHZ.summary.nTrials(i)),')'];
                end
            end
            
        case 'group'
            if np
                for i = 1:numel(PHZ.summary.nParticipant)
                    lineLabels{i} = [lineLabels{i},' (',num2str(PHZ.summary.nParticipant(i)),')'];
                end
            end
    end
    
    % add n's to labels for plots
    if length(PHZ.summary.keepVars) > 1
        switch PHZ.summary.keepVars{2}
            case 'trials'
                if nt
                    for i = 1:length(plotLabels)
%                         theseLabels = PHZ.summary.nTrials(PH
                        plotLabels{i} = [plotLabels{i},' (',num2str(sum(PHZ.summary.nTrials(PHZ.trials == plotLabels{i}))),')'];
                    end
                end
                
            case 'group'
                if np
                    for i = 1:length(plotLabels)
                        plotLabels{i} = [plotLabels{i},' (',num2str(PHZ.summary.nParticipant(i)),')'];
                    end
                end
        end
        
    else
        if np && ~strcmp(PHZ.summary.keepVars{1},'group')
            plotLabels{1} = [plotLabels{1},' (~',num2str(max(PHZ.summary.nParticipant)),')'];
        end
    end
end

end

function [rows,cols,pos,ytitleLoc,xtitleLoc] = getPlotDims(plotLabels)
ytitleLoc = [];
xtitleLoc = [];
switch length(plotLabels)
    % pos is [left bottom width height]
    case 1,                   rows = 1; cols = 1; pos = [0.25 0.4 0.5 0.6];
    case 2,                   rows = 2; cols = 1; pos = [0.25 0 0.5 1];
    case 3,                   rows = 3; cols = 1; pos = [0.25 0 0.5 1];
    case 4,                   rows = 2; cols = 2; pos = [0 0 1 1];
    case {5,6},               rows = 3; cols = 2; pos = [0 0 1 1];
    case {7,8,9},             rows = 3; cols = 3; pos = [0 0 1 1];
    case {10,11,12},          rows = 4; cols = 3; pos = [0 0 1 1];
    case {13,14,15,16},       rows = 4; cols = 4; pos = [0 0 1 1];
    case {17,18,19,20},       rows = 5; cols = 4; pos = [0 0 1 1]; ytitleLoc = 9;  xtitleLoc = 18;
    case {21,22,23,24,25},    rows = 5; cols = 5; pos = [0 0 1 1]; ytitleLoc = 11; xtitleLoc = 23;
    case {26,27,28,29,30},    rows = 6; cols = 5; pos = [0 0 1 1]; ytitleLoc = 11; xtitleLoc = 28;
    case {31,32,33,34,35,36}, rows = 6; cols = 6; pos = [0 0 1 1]; ytitleLoc = 13; xtitleLoc = 32;
    otherwise, error('Too many plots.')
end
end

function ytitle = getytitle(PHZ,feature,legendLoc,smoothing,featureTitle)

% main titles
% -----------

% feature title and datatype
if ismember(feature,{'acc','acc1','acc2','acc3','acc4','acc5',...
        'rt', 'rt1', 'rt2', 'rt3', 'rt4', 'rt5'})
    ytitle = {featureTitle};
    skipDSPtitles = true;
    
else ytitle = {[upper(PHZ.datatype),' ',...
        featureTitle]};
    skipDSPtitles = false;
end

% units
if ~isempty(PHZ.units)
    ytitle = {[ytitle{1},' (',PHZ.units,')']};
end

% dsp-related titles
% ------------------
if skipDSPtitles, return, end % skip dsp titles for acc and rt

% smoothing
if smoothing && isempty(feature), ytitle = {[ytitle{1} ' (smoothed)']}; end

% region name and baseline-correction
if ~isempty(feature) || (isempty(feature) && isempty(legendLoc))
    if ~isempty(PHZ.region) && ~isstruct(PHZ.region)
        ytitle = [ytitle; {['region: ',PHZ.region]}];
%         if isnumeric(PHZ.region), ytitle = [ytitle; {['region ',phzUtil_num2strRegion(PHZ.region)]}];
%         elseif ischar(PHZ.region),ytitle = [ytitle; {[PHZ.region,' region']}];
%         end
    end
    
    if ismember('blc',fieldnames(PHZ))
        ytitle = [ytitle; {['baseline-correction: ',phzUtil_num2strRegion(PHZ.blc.region)]}];
    end

elseif ismember('blc',fieldnames(PHZ))
    ytitle = [ytitle; {'baseline-corrected'}];
end
end
