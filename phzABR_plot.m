%PHZABR_PLOT  Special plotting function to inspect ABR responses.
%   Plots 5 signals and their associated spectra, for a total of 10 plots.
%   These signals are the stimulus, the regular trials, the inverted
%   trials, the EFR (adding the two polarities) and the FFR (subtracting
%   the two polarities. Usage is similar to phz_plot.

function phzABR_plot(PHZ, varargin)

% time domain plots always show whole epoch; if region arg is used, only
% the spectrum is restricted to this region

if length(PHZ.trials) ~= 2
    error('Must have exactly 2 trial types (usually regular and inverted)')
end

% defaults
verbose = true;
region = '';
plotSpec = {'k', 'b', 'b', 'g', 'r'};
linewidth = 1.5;
fontsize = 12;
if ismember('epoch', fieldnames(PHZ.proc))
    xl = PHZ.proc.epoch.extractWindow;
else
    xl = [];
end
yl = [-1 1] * 30;
ylf = [0 1]; % "f" for freq domain plots
xlf = [0 1000];
pretty = false;
dark = false;

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

        case {'plotspec'},              plotSpec = varargin{i+1};
        case {'linewidth','lineweight'},linewidth = varargin{i+1};
        case 'fontsize',                fontsize = varargin{i+1};
        case {'yl','ylim'},             yl = varargin{i+1};
        case {'xl','xlim'},             xl = varargin{i+1};
        case {'ylf'},                   ylf = varargin{i+1};
        case {'xlf'},                   xlf = varargin{i+1};
        case 'pretty',                  pretty = varargin{i+1};
        case 'dark',                    dark = varargin{i+1};
    end
end

% prepare for all plots
PHZ = phzABR_equalizeTrials(PHZ);
PHZ = phz_summary(PHZ, 'trials');
if dark, plotSpec = strrep(plotSpec, 'k', 'w'); end

% prepare for time-domain plots (don't restrict by region)
% subtract mean so everything is zero-centered
reg = PHZ.data(1,:) - mean(PHZ.data(1,:));
inv = PHZ.data(2,:) - mean(PHZ.data(1,:));

data = {PHZ.etc.stim, ...
        reg, ...
        inv, ...
        reg + inv, ...
        reg - inv};

ytitle = {'Stimulus', ...
          {char(PHZ.lib.tags.trials(1));
          [' (', num2str(PHZ.proc.summary.nTrials(1)),' trials)']}, ...
          {char(PHZ.lib.tags.trials(2));
          [' (', num2str(PHZ.proc.summary.nTrials(2)),' trials)']}, ...
          'EFR (adding)', ...
          'FFR (subtracting)'};

% prepare for spectral plots (restrict by region)
PHZ2 = phz_region(PHZ, region);

reg = PHZ2.data(1,:) - mean(PHZ2.data(1,:));
inv = PHZ2.data(2,:) - mean(PHZ2.data(1,:));

data2 = {PHZ.etc.stim, ...
         reg, ...
         inv, ...
         reg + inv, ...
         reg - inv};

% get spectrum title
if isempty(region)
    spectrumTitle = 'Spectrum';
elseif isnumeric(region)
    spectrumTitle = (['Spectrum of ', phzUtil_num2strRegion(region)]);
else
    spectrumTitle = (['Spectrum of ', region]);
end

%% draw plots
% create fullscreen figure
figure('units', 'normalized', 'outerposition', [0 0 1 1])

% time domain plots
plots = 1:2:10;
for i = 1:5
    subplot(5,2,plots(i))
    plot(PHZ.times, data{i}, plotSpec{i}, 'LineWidth', linewidth)
    ylabel(ytitle{i})
    if ~isempty(xl), xlim(xl), end
    if plots(i) == 1
        if dark
            title('Time Domain', 'color', [1 1 1] * 0.7)
        else
            title('Time Domain')
        end
    else
        ylim(yl)
    end
    if plots(i) == 9
        xlabel('Time (s)')
    end
    set(gca, 'fontsize', fontsize)
    if pretty, do_pretty, end
    if dark, do_dark, end
end

% frequency domain plots
plots = 2:2:10;
for i = 1:5
    subplot(5,2,plots(i))
    [fftdata, freqs, units, featureTitle] = ...
    phzFeature_fft(data2{i}, PHZ2.srate, PHZ2.units);
    plot(freqs, fftdata, plotSpec{i}, 'LineWidth', linewidth)
    ylabel([featureTitle, ' (', units, ')'])
    xlim(xlf)
    if plots(i) == 2
        if dark
            title(spectrumTitle, 'color', [1 1 1] * 0.7)
        else
            title(spectrumTitle)
        end
    end
    if plots(i) == 10
        xlabel('Frequency (Hz)')
    end
    if plots(i) ~= 2
        ylim(ylf)
    end
    set(gca, 'fontsize', fontsize)
    if pretty, do_pretty, end
    if dark, do_dark, end
end

if pretty, set(gcf,'color','w'), end
if dark, set(gcf,'color','k'), end
end

function do_pretty
set(gca,'box','off')
end

function do_dark
set(gca, ...
    'color', 'k', ...
    'xcolor', [1 1 1] * 0.7, ...
    'ycolor', [1 1 1] * 0.7)
            
end
