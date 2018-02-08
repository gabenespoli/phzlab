%PHZ_PLOT  Plot data from PHZ and PHZS structures.
% 
% USAGE    
%   PHZ_PLOT(PHZ,'Param1',Value1,etc.)
% 
% INPUT   
%   PHZ           = [struct] PHZLAB data structure.
% 
%   'smooth'      = [1|0] For line plots, apply a moving point average.
% 
%   'dispn'       = [1|0] Display the number of trials or participants
%                   included in each line or bar plotted. Enter 
%                   'participant', 'trials', 'both', or 'none'.
% 
%   'legend'      = [string] For line plots, specify the location of the 
%                   legend Enter 'nw' (default) for top-left, etc., 
%                   or '' (empty) to suppress the legend.
% 
%   'linewidth'   = [numeric] For line plots, specify the width of the 
%                   line in pixels. Default 2.
% 
%   'fontsize'    = [numeric] Specify the font size of titles. Default 14.
% 
%   'xl'          = [numeric] For line plots, Specify the x-axis limits in 
%                   seconds or Hertz for time and frequency plots 
%                   respectively. Enter as a vector of length 2
%                   (i.e., [lowerLimit upperLimit]).
% 
%   'yl'          = [numeric] Specify the y-axis limits of plots.
% 
%   'sameyl'      = [1|0] Force the positive and negative y-axis limit to 
%                   be the same. If data are roughly centered on zero, this
%                   is applied automatically. Enter 1 (true) or 0 (false)
%                   to manually use this functionality.
% 
%   'pretty'      = [0|1] Makes the background white and removes the top 
%                   x-axis and right y-axis, making plots look more
%                   "presentation-ready". Default 0.
% 
%   'dark'        = [0|1] Makes the plot background black instead of white.
%                   Useful at night. Default 0.
%
%   'simpleYTitle'= [0|1] Enter 1 to suppress inclusion of processing info
%                   in the y-axis title. Default 0 (include this info).
% 
%   'title'       = [1|0] Enter 0 to suppress the plot title. Default 1.
%
%   'plotall'     = [0|1] Enter 1 to overlay all raw data points on bar
%                   plots. Default 0.
% 
%   'close'       = [0|1] Enter 1 to close the plot window after drawing
%                   it. This is useful when making (and saving) many plots 
%                   with a script.
% 
%   'save'        = [string] Enter a filename to save the created figure
%                   to disk as a file. The filetype is determined from the
%                   file extension. Supports png, pdf, and eps output. if 
%                   no extension is given, .png is used.
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
%   'feature'   = Calls phz_feature and makes bar plots instead of line
%                 plots (excepting FFT and ITPC).
% 
%   'summary'   = Calls phz_summary. The default summary is 'all', which 
%                 averages across all trials. A maximum of 2 summary 
%                 variables can be specified; the first is plotted as 
%                 separate lines/bars, and the second is plotted across
%                 separate plots.
%
%   'abrsummary' = Calls phzABR_summary. If specified, this is called
%                 before phz_summary.
% 
% OUTPUT 
%   A new figure is created and the specified plot is displayed.
% 
%   If 'filename' is specified, an image file of the plot is saved.
% 
%   Use phz_field to edit the order in which lines and bars are
%   plotted, as well as their colour and line style.

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

function phz_plot(PHZ,varargin)

if nargout == 0 && nargin == 0, help phz_plot, return, end
PHZ = phz_check(PHZ);

% defaults
region = [];
feature = [];
keepVars = {'none'};
summaryFunction = '';

do_plotsmooth = false;
dispn = 'none';
legendLoc = 'nw';
linewidth = 2;
fontsize = 14;

yl = [];
xl = [];
sameyl = [];
pretty = false;
dark = false;
simpleytitle = false;
do_title = true;
do_close = false;
plotall = false;

filename = '';

verbose = true;

sigstarVars = [];

% user-defined
if any(strcmp(varargin(1:2:end),'verbose'))
    i = find(strcmp(varargin(1:2:end),'verbose')) * 2 - 1;
    verbose = varargin{i+1};
    varargin([i,i+1]) = [];
end

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'subset',                  PHZ = phz_subset(PHZ,varargin{i+1},verbose);
        case {'rect','rectify'},        PHZ = phz_rectify(PHZ,varargin{i+1},verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,varargin{i+1},verbose);
        case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,varargin{i+1},verbose);
        case 'transform',               PHZ = phz_transform(PHZ,varargin{i+1},verbose);
        case {'blsub','blc'},           PHZ = phz_blsub(PHZ,varargin{i+1},verbose);
        case {'rej','reject'},          PHZ = phz_reject(PHZ,varargin{i+1},verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,varargin{i+1},verbose);
        
        case 'region',                  region = varargin{i+1};
        case 'feature',                 feature = varargin{i+1};
        case {'summary','keepvars'},    keepVars = varargin{i+1};
        case {'abrsummary','summaryfunction'}, summaryFunction = varargin{i+1};
            
        case {'plotsmooth'},            do_plotsmooth = varargin{i+1};
        case {'dispn','n'},             dispn = varargin{i+1};    
        case {'legend','legendloc'},    legendLoc = varargin{i+1};            
        case {'linewidth','lineweight'},linewidth = varargin{i+1};
        case 'fontsize',                fontsize = varargin{i+1};
        case {'yl','ylim'},             yl = varargin{i+1};
        case {'xl','xlim'},             xl = varargin{i+1};
        case 'sameyl',                  sameyl = varargin{i+1};
        case 'pretty',                  pretty = varargin{i+1};
        case 'dark',                    dark = varargin{i+1};
        case 'simpleytitle',            simpleytitle = varargin{i+1};
        case {'do_title','title'},      do_title = varargin{i+1};
        case {'plotall','all'},         plotall = varargin{i+1};
        case {'filename','save','file'},filename = varargin{i+1};
        case {'close'},                 do_close = varargin{i+1};
            
        case 'sigstar',                 sigstarVars = varargin{i+1};
    end
end

% process & prepare data to plot
if length(cellstr(keepVars)) > 2, error('Cannot plot more than 2 summary types.'), end
if ~isempty(feature) && ~strcmp(feature,'time'), PHZ = phz_region(PHZ,region,verbose); end
if ~isempty(summaryFunction), PHZ = phzABR_summary(PHZ,summaryFunction,verbose); end
[PHZ,featureTitle,preSummaryData] = phz_feature(PHZ,feature,'summary',keepVars,'verbose',verbose);
% (run phz_summary through phz_feature because fft feature needs to average
%  over the summaryType by participant before doing the fft)

if do_plotsmooth && size(PHZ.data,2) > 1, PHZ = phz_smooth(PHZ,'mean0.05'); end
if ismember('times',fieldnames(PHZ)),     x = PHZ.times;
elseif ismember('freqs',fieldnames(PHZ)), x = PHZ.freqs;
end

% prepare plot stuff
[lineOrder,~,lineSpec,plotOrder,plotTags,~] = getLabelsAndSpec(PHZ,dispn);
[rows,cols,pos,ytitleLoc,xtitleLoc] = getPlotDims(plotOrder);
if isempty(yl), yl = nan(length(plotOrder),2); do_yl = true; else, do_yl = false; end
if isempty(xl), xl = nan(size(yl));            do_xl = true; else, do_xl = false; end
ytitle = getytitle(PHZ,feature,legendLoc,do_plotsmooth,featureTitle,simpleytitle);

% loop plots and plot lines/bars
% ------------------------------
figure('units','normalized','outerposition',pos,...
    'name',inputname(1),'numbertitle','off');
for p = 1:length(plotOrder)
    subplot(rows,cols,p)

    % get indices of data for current plot
    if ismember('summary',fieldnames(PHZ.proc)) && length(PHZ.proc.summary.keepVars) > 1
        ind = find(plotTags == plotOrder(p));
    else
        ind = 1:size(PHZ.data,1);
    end

    % loop lines/bars
    for i = 1:length(lineOrder)
        y = PHZ.data(ind(i),:);
        yall = preSummaryData{i};

        if size(PHZ.data,2) > 1 % line plots of time-series or fft data
            h = plot(x,y,...
                'DisplayName',char(lineOrder(i)),...
                'LineWidth',linewidth);
            if i == 1, hold on, end

            if ~isempty(lineSpec{i})
                if ischar(lineSpec{i})
                    set(h,'Color',lineSpec{i}(1))
                    if length(lineSpec{i}) > 1
                        set(h,'LineStyle',lineSpec{i}(2:end)), end
                elseif isnumeric(lineSpec{i}), set(h,'Color',lineSpec{i})
                end
            end

        else % bar plots of feature values

            h = bar(i,y);
            if i == 1, hold on, end
            if plotall, hall = scatter(repmat(i,size(yall)),yall); end

            % change color if specified
            if ~isempty(lineSpec{i})

                % color
                if ~isempty(lineSpec{i})
                    if ischar(lineSpec{i})
                        set(h,'FaceColor',lineSpec{i}(1))
                        if plotall, set(hall,'MarkerFaceColor',lineSpec{i}(1),'MarkerEdgeColor',lineSpec{i}(1)), end
                    elseif isnumeric(lineSpec{i})
                        set(h,'FaceColor',lineSpec{i})
                        if plotall, set(hall,'MarkerFaceColor',lineSpec{i},'MarkerEdgeColor',lineSpec{i}(1)), end
                    end
                end

                % use linespec to change brightness of color
                if length(lineSpec{i}) > 1 && strcmp(lineSpec{i}(2), ':')
                        currentColor = get(h,'FaceColor') + 0.2;
                        currentColor(currentColor > 1) = 1;
                        set(h,'FaceColor',currentColor)
                        if plotall, set(hall,'MarkerFaceColor',currentColor,'MarkerEdgeColor',currentColor), end

                elseif length(lineSpec{i}) > 2 && strcmp(lineSpec{i}(2:3),'-.')
                        currentColor = get(h,'FaceColor') + 0.4;
                        currentColor(currentColor > 1) = 1;
                        set(h,'FaceColor',currentColor)
                        if plotall, set(hall,'MarkerFaceColor',currentColor,'MarkerEdgeColor',currentColor), end

                elseif length(lineSpec{i}) > 2 && strcmp(lineSpec{i}(2:3),'--')
                        currentColor = get(h,'FaceColor') + 0.6;
                        currentColor(currentColor > 1) = 1;
                        set(h,'FaceColor',currentColor)
                        if plotall, set(hall,'MarkerFaceColor',currentColor,'MarkerEdgeColor',currentColor), end

                elseif length(lineSpec{i}) > 1 && strcmp(lineSpec{i}(2), '-')
                        currentColor = get(h,'FaceColor') + 0.8;
                        currentColor(currentColor > 1) = 1;
                        set(h,'FaceColor',currentColor)
                        if plotall, set(hall,'MarkerFaceColor',currentColor,'MarkerEdgeColor',currentColor), end

                end
            end
        end
    end

    % label plot, add errorbars
    if do_title, title(char(plotOrder(p))), end
    if isempty(ytitleLoc) || ytitleLoc == p, ylabel(ytitle), end

    if ismember(PHZ.proc.feature,{'fft','itfft','itpc'}) % FFT / PC plots
        if isempty(xtitleLoc) || xtitleLoc == p, xlabel('Frequency (Hz)'), end

        % custom FFT x-axis limits via PHZ.lib.spec.fftlim
        if ismember('fftlim',fieldnames(PHZ.lib.spec))
            if isnumeric(PHZ.lib.spec.fftlim) && isvector(PHZ.lib.spec.fftlim) && length(PHZ.lib.spec.fftlim) == 2
                do_xl = false;
                xl = PHZ.lib.spec.fftlim;
            else
                warning('Problem with PHZ.lib.spec.fftlim. Using defaults.')
            end
        end

    elseif ismember(PHZ.proc.feature,{'','time'}) % time series plots
        if isempty(xtitleLoc) || xtitleLoc == p, xlabel('Time (s)'), end

    elseif ~isempty(PHZ.proc.summary.stdError) % bar plots of feature values
        set(gca,'XTick',1:length(lineOrder),'XTickLabel',cellstr(lineOrder))    
        errorbar(gca,1:length(lineOrder),PHZ.data(ind),PHZ.proc.summary.stdError(ind),'.k');
    end

    % ---- sigstar (beta)
    if ~isempty(sigstarVars)
        if isstruct(sigstarVars)
            if ismember(plotOrder(p), fieldnames(sigstarVars))
                sigstarVarsCurrent = sigstarVars.(char(plotOrder(p)));
            end
        else
            sigstarVarsCurrent = sigstarVars;
        end
        if ~isempty(sigstarVarsCurrent)
            try
                phzUtil_sigstar(sigstarVarsCurrent{:})
            catch
                fprintf('  Aborting using sigstar for some reason...\n')
            end
        end
    end
    % ----

    % record axes ranges
    if do_yl, yl(p,:) = ylim; end %#ok<AGROW>

    hold off
end

% get min/max axes ranges
if do_yl
    yl = [min(yl(:,1)) max(yl(:,2))];

    % if data are centered on zero, set +ve and -ve limit to same
    if isempty(sameyl)
        if yl(1) / yl(2) < -0.5 && yl(1) / yl(2) > -2, sameyl = true;
        else
            sameyl = false;
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
                obj = patch(x,y,PHZ.lib.spec.region{k},'EdgeColor','none',...
                    'DisplayName',PHZ.lib.tags.region{k});
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
    if pretty, set(gca,'box','off'), end
    if dark, set(gca,'color','k'), end

end

if pretty, set(gcf,'color','w'), end

if ~isempty(filename), phzUtil_savefig(gcf, filename), end

if do_close, close(gcf), end

% Done phz_plot
end

function [lineOrder,lineTags,lineSpec,plotOrder,plotTags,plotSpec] = getLabelsAndSpec(PHZ,dispn)

% get most recent summary proc field name
names = fieldnames(PHZ.proc);
ind = startsWith(names, 'summary');
ind = max(find(ind, length(ind), 'first'));
if ~isempty(ind)
    isSummary = true;
    procName = names{ind};
else
    isSummary = false;
    procName = '';
end

% lines/bars
if ~isSummary
    lineOrder = cellstr(num2str((1:size(PHZ.data,1))));
    lineSpec = cell(size(lineOrder));
    for j = 1:length(lineOrder)
        lineSpec{j} = '';
    end
    lineTags = [];
elseif ismember(PHZ.proc.(procName).keepVars{1},{' ','none'}) || isempty(PHZ.proc.(procName).keepVars{1})
    lineOrder = {'All trials'};
    lineSpec = {''};
    lineTags = [];
else
    lineOrder = PHZ.(PHZ.proc.(procName).keepVars{1});
    lineSpec = PHZ.lib.spec.(PHZ.proc.(procName).keepVars{1});
    lineTags = PHZ.lib.tags.(PHZ.proc.(procName).keepVars{1});
end

% plots
if ~isSummary
    plotOrder = {''};
    plotSpec = {''};
    plotTags = [];
elseif length(PHZ.proc.(procName).keepVars) == 1
    if length(PHZ.participant) > 1 || isundefined(PHZ.participant)
        plotOrder = {'All participants'};
    else
        plotOrder = {['Participant ',char(PHZ.participant)]};
    end
    plotSpec = {''};
    plotTags = [];
else 
    plotOrder = PHZ.(PHZ.proc.(procName).keepVars{2});
    plotSpec = PHZ.lib.spec.(PHZ.proc.(procName).keepVars{2});
    plotTags = PHZ.lib.tags.(PHZ.proc.(procName).keepVars{2});
end

% add n's
if ~ismember(dispn,{'none',''})
    switch dispn
        case {'participant','participants'}, np = 1; nt = 0;
        case {'trials','trial'},             np = 0; nt = 1;
        case {'both','all'},                 np = 1; nt = 1;
    end
    
    % add n's to labels for lines/bars
    switch PHZ.proc.(procName).keepVars{1}
        case 'all'
            if nt
                lineLabels{1} = [lineLabels{1},' (',num2str(PHZ.proc.(procName).nTrials),')'];
            end
            
        case 'trials'
            if nt
                for i = 1:numel(PHZ.proc.(procName).nTrials)
                    lineLabels{i} = [lineLabels{i},' (',num2str(PHZ.proc.(procName).nTrials(i)),')'];
                end
            end
            
        case 'group'
            if np
                for i = 1:numel(PHZ.proc.(procName).nParticipant)
                    lineLabels{i} = [lineLabels{i},' (',num2str(PHZ.proc.(procName).nParticipant(i)),')'];
                end
            end
    end
    
    % add n's to labels for plots
    if length(PHZ.proc.(procName).keepVars) > 1
        switch PHZ.proc.(procName).keepVars{2}
            case 'trials'
                if nt
                    for i = 1:length(plotLabels)
%                         theseLabels = PHZ.proc.(procName).nTrials(PH
                        plotLabels{i} = [plotLabels{i},' (',num2str(sum(PHZ.proc.(procName).nTrials(PHZ.trials == plotLabels{i}))),')'];
                    end
                end
                
            case 'group'
                if np
                    for i = 1:length(plotLabels)
                        plotLabels{i} = [plotLabels{i},' (',num2str(PHZ.proc.(procName).nParticipant(i)),')'];
                    end
                end
        end
        
    else
        if np && ~strcmp(PHZ.proc.(procName).keepVars{1},'group')
            plotLabels{1} = [plotLabels{1},' (~',num2str(max(PHZ.proc.(procName).nParticipant)),')'];
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

function ytitle = getytitle(PHZ,feature,legendLoc,do_plotsmooth,featureTitle,simpleytitle)

% main titles
if ismember(PHZ.proc.feature,{ ...
    'acc','acc1','acc2','acc3','acc4','acc5', ...
    'rt', 'rt1', 'rt2', 'rt3', 'rt4', 'rt5'})
    ytitle = {featureTitle};
    skipDSPtitles = true;
else
    ytitle = {[PHZ.datatype,' ',featureTitle]};
    skipDSPtitles = false;
end

if ~isempty(PHZ.units)
    ytitle = {[ytitle{1},' (',PHZ.units,')']}; end

% dsp-related titles
if skipDSPtitles || simpleytitle % skip dsp titles for acc and rt
    return, end

if do_plotsmooth && isempty(feature)
    ytitle = {[ytitle{1} ' (smoothed)']}; end

% line 2
line2 = '';
if ismember('blsub', fieldnames(PHZ.proc))
    baselineStr = ['baseline [', ...
        num2str(PHZ.proc.blsub.region(1)),   ' ', ...
        num2str(PHZ.proc.blsub.region(end)), ']'];
    line2 = [line2, baselineStr];
end    

if ~isempty(PHZ.region) && ~isstruct(PHZ.region) && ~strcmp(PHZ.region,'whole epoch')
    if ~isempty(line2), line2 = [line2, '; ']; end % spacer if incl bl
    line2 = [line2, PHZ.region];
end

% search for non-mean summary functions
names = fieldnames(PHZ.proc);
inds = find(startsWith(names, 'summary'));
for i = 1:length(inds)
    ind = inds(i);
    switch PHZ.proc.(names{ind}).summaryFunction
        case {'add', '+'}
            summaryFunction = '+';
            appendSumFunc = true;
        case {'subtract', 'sub', '-'}
            summaryFunction = '-';
            appendSumFunc = true;
        otherwise
            appendSumFunc = false;
    end
    if appendSumFunc
        line2 = [line2, ' ', summaryFunction, PHZ.proc.(names{ind}).loseVars{1}]; %#ok<AGROW>
    end
end

if ~isempty(line2), ytitle{2} = line2; end % add 2nd line titles if any
ytitle{end+1} = ' '; % spacer to prevent overlapping with y ticks

end
