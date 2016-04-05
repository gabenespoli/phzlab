function phz_plot(PHZ,varargin)
%PHZ_PLOT  Plot data from PHZ and PHZS structures.
% 
% usage:    PHZ_PLOT(PHZ,'Param1','Value1',etc.)
% 
% inputs:   PHZ         = PHZLAB data structure
%           'smooth'    = For line plots, apply a moving point average.
%           'dispn'     = Display the number of trials or participants 
%                         included in each line or bar plotted. Enter 
%                         'participant', 'trials', 'both', or 'none'.
%           'legend'    = For line plots, specify the location of the
%                          legend. Enter 'nw' (default) for top-left, etc., 
%                         or '' (empty) to suppress the legend.
%           'linewidth' = For line plots, specify the width of the line in
%                         pixels. Default 2.
%           'fontsize'  = Specify the font size of titles. Default 14.
%           'xl'        = For line plots, Specify the x-axis limits in 
%                         seconds or Hertz for time and frequency plots 
%                         respectively.
%           'yl'        = Specify the y-axis limits of plots.
%           'sameyl'    = Force the positive and negative y-axis limit to 
%                         be the same. If data are roughly centered on 
%                         zero, this is applied automatically. Enter 1 
%                         (true) or 0 (false) to manually use this 
%                         functionality.
%   
%           The following functions can be called as parameter/value pairs,
%           and are executed in the same order as they appear in the
%           function call. See the help of each function for more details.
%               'subset'    = Calls phz_subset.
%               'rectify'   = Calls phz_rect.
%               'filter'    = Calls phz_filter.
%               'smooth'    = Calls phz_smooth.
%               'transform' = Calls phz_transform.
%               'blc'       = Calls phz_blc.
%               'rej'       = Calls phz_rej.
%               'norm'      = Calls phz_norm.
% 
%           The following functions can be called as parameter/value pairs,
%           and are always executed in the order listed here, after all of
%           the processing funtions. See the help of each function for more
%           details.
%               'region'    = Calls phz_region.
%               'summary'   = Calls phz_summary. The default summary is
%                             'all', which averages across all trials. A
%                             maximum of 2 summary variables can be
%                             specified; the first is plotted as separate
%                             lines/bars, and the second is plotted across
%                             separate plots.
% 
% outputs:  Use phz_changefield to edit the order in which lines and bars
%           are plotted, as well as their colour and line style.
% 
% Written by Gabriel A. Nespoli 2016-02-16. Revised 2016-04-04.
if nargout == 0 && nargin == 0, help phz_plot, return, end
PHZ = phz_check(PHZ);

% defaults
region = [];
feature = [];
keepVars = {'none'};

do_plotsmooth = false;
dispn = 'none';
legendLoc = 'nw';
linewidth = 2;
fontsize = 14;

yl = [];
xl = [];
sameyl = [];

verbose = true;

% user-defined
if any(strcmp(varargin(1:2:end),'verbose'))
    i = find(strcmp(varargin(1:2:end),'verbose')) * 2 - 1;
    verbose = varargin{i+1};
    varargin([i,i+1]) = [];
end

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'subset',                  PHZ = phz_subset(PHZ,varargin{i+1},verbose);
        case {'rect','rectify'},        PHZ = phz_rect(PHZ,varargin{i+1},verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,varargin{i+1},verbose);
        case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,varargin{i+1},verbose);
        case 'transform',               PHZ = phz_transform(PHZ,varargin{i+1},verbose);
        case {'blc','baselinecorrect'}, PHZ = phz_blc(PHZ,varargin{i+1},verbose);
        case {'rej','reject'},          PHZ = phz_rej(PHZ,varargin{i+1},verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,varargin{i+1},verbose);
        
        case 'region',                  region = varargin{i+1};
        case 'feature',                 feature = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
            
        case {'plotsmooth'},            do_plotsmooth = varargin{i+1};
        case {'dispn','n'},             dispn = varargin{i+1};    
        case {'legend','legendloc'},    legendLoc = varargin{i+1};            
        case {'linewidth','lineweight'},linewidth = varargin{i+1};
        case 'fontsize',                fontsize = varargin{i+1};
        case {'yl','ylim'},             yl = varargin{i+1};
        case {'xl','xlim'},             xl = varargin{i+1};
        case 'sameyl',                  sameyl = varargin{i+1};
    end
end

% process & prepare data to plot
if length(cellstr(keepVars)) > 2, error('Cannot plot more than 2 summary types.'), end
if ~isempty(feature) && ~strcmp(feature,'time'), PHZ = phz_region(PHZ,region,verbose); end
[PHZ,featureTitle] = phz_feature(PHZ,feature,'summary',keepVars,'verbose',verbose);
% (run phz_summary through phz_feature because fft feature needs to average
%  over the summaryType by participant before doing the fft)

if do_plotsmooth && size(PHZ.data,2) > 1, PHZ = phz_smooth(PHZ,'mean0.05'); end
if ismember('times',fieldnames(PHZ)),     x = PHZ.times;
elseif ismember('freqs',fieldnames(PHZ)), x = PHZ.freqs;
end

% prepare plot stuff
[lineOrder,~,lineSpec,plotOrder,plotTags] = getLabelsAndSpec(PHZ,dispn);
[rows,cols,pos,ytitleLoc,xtitleLoc] = getPlotDims(plotOrder);
if isempty(yl), yl = nan(length(plotOrder),2); do_yl = true; else do_yl = false; end
if isempty(xl), xl = nan(size(yl));            do_xl = true; else do_xl = false; end
ytitle = getytitle(PHZ,feature,legendLoc,do_plotsmooth,featureTitle);

% loop plots and plot lines/bars
% ------------------------------
figure('units','normalized','outerposition',pos)
for p = 1:length(plotOrder)
    subplot(rows,cols,p)
    
    % get indices of data for current plot
    if ismember('summary',fieldnames(PHZ)) && length(PHZ.summary.keepVars) > 1
        ind = find(plotTags == plotOrder(p));
    else ind = 1:size(PHZ.data,1); 
    end
        
    % loop lines/bars
    for i = 1:length(lineOrder)
        y = PHZ.data(ind(i),:);
        
        if size(PHZ.data,2) > 1 % line plots of time-series or fft data
            plot(x,y,lineSpec{i},...
                'DisplayName',char(lineOrder(i)),...
                'LineWidth',linewidth)
            if i == 1, hold on, end
            
        else % bar plots of feature values
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
    title(char(plotOrder(p)))
    if isempty(ytitleLoc) || ytitleLoc == p, ylabel(ytitle), end
    
    if ismember(PHZ.feature,{'fft','itfft','itpc'}) % FFT / PC plots
        if isempty(xtitleLoc) || xtitleLoc == p, xlabel('Frequency (Hz)'), end
        
    elseif ismember(PHZ.feature,{'','time'}) % time series plots
        if isempty(xtitleLoc) || xtitleLoc == p, xlabel('Time (s)'), end
        
    else % bar plots of feature values
        set(gca,'XTick',1:length(lineOrder),'XTickLabel',cellstr(lineOrder))    
        errorbar(gca,1:length(lineOrder),PHZ.data(ind),PHZ.summary.stdError(ind),'.k');
    end
    
    % record axes ranges
    if do_yl, yl(p,:) = ylim; end
    
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

if do_xl && size(PHZ.data,2) > 1
    xl = [x(1) x(end)];
end

% loop plots and apply formatting
% -------------------------------
for p = 1:length(plotOrder)
    subplot(rows,cols,p)
    
    % set y- and x-axis ranges
    ylim(yl)
    if size(PHZ.data,2) > 1, xlim(xl), end
    %{
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
                obj = patch(x,y,PHZ.spec.region{k},'EdgeColor','none',...
                    'DisplayName',PHZ.tags.region{k});
                alpha(obj,0.1) % make translucent
            end
        end
    end
    %}
    % add legend
    if size(PHZ.data,2) > 1 && ~isempty(legendLoc)
        legend('-DynamicLegend','Location',legendLoc)
    end
    
    % adjust font size
    set(gca,'FontSize',fontsize)
    
end

% Done phz_plot
end

function [lineOrder,lineTags,lineSpec,plotOrder,plotTags,plotSpec] = getLabelsAndSpec(PHZ,dispn)

% lines/bars
if ~ismember('summary',fieldnames(PHZ))
    lineOrder = cellstr(num2str((1:size(PHZ.data,1))));
    lineSpec = cell(size(lineOrder));
    for j = 1:length(lineOrder)
        lineSpec{j} = '';
    end
    lineTags = [];
elseif ismember(PHZ.summary.keepVars{1},{' ','none'}) || isempty(PHZ.summary.keepVars{1})
    lineOrder = {'All trials'};
    lineSpec = {''};
    lineTags = [];
else
    lineOrder = PHZ.(PHZ.summary.keepVars{1});
    lineSpec = PHZ.spec.(PHZ.summary.keepVars{1});
    lineTags = PHZ.tags.(PHZ.summary.keepVars{1});
end

% plots
if ~ismember('summary',fieldnames(PHZ))
    plotOrder = {''};
    plotSpec = {''};
    plotTags = [];
elseif length(PHZ.summary.keepVars) == 1
    if length(PHZ.participant) > 1 || isundefined(PHZ.participant)
        plotOrder = {'All participants'};
    else plotOrder = {['Participant ',char(PHZ.participant)]};
    end
    plotSpec = {''};
    plotTags = [];
else 
    plotOrder = PHZ.(PHZ.summary.keepVars{2});
    plotSpec = PHZ.spec.(PHZ.summary.keepVars{2});
    plotTags = PHZ.tags.(PHZ.summary.keepVars{2});
end

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
if ismember(PHZ.feature,{'acc','acc1','acc2','acc3','acc4','acc5',...
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
