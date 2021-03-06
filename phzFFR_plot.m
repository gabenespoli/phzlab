%PHZFFR_PLOT  Special plotting function to inspect FFR responses.
%   Plots 5 signals and their associated spectra, for a total of 10 plots.
%   These signals are the stimulus, the regular trials, the inverted
%   trials, the envelope FFR (adding the two polarities) and the 
%   spectral FFR (subtracting the two polarities. Usage and options
%   are similar to phz_plot.
%
% Usage:
%   phzFFR_plot(PHZ, 'Param', Value, etc.)
%   phzFFR_plot(PHZ, preset, 'Param', Value, etc.)
%
% Input:
%   PHZ           = PHZLAB data structure of FFR data. Should have the
%                   PHZ.lib.stim field with the stimulus waveform.
%
%   preset        = [string] Use this preset from PHZ.lib.abrplots.
%                   See help phz_plot for details.
%
%   'region'      = [string] Calls phz_region when making the spectral
%                   plots, but not the time-domain plots. Default is the
%                   whole epoch.
%
%   'ylt', 'xlt'  = [numeric 1x2] Axis limits for the time domain plots
%                   on the left-hand side. 
%   
%   'ylf', 'xlf'  = [numeric 1x2] Axis limits for the spectral plots
%                   on the right-hand side.
%   
%   'linewidth'   = [numeric] Specify the width of the plotted lines in
%                   pixels. Default 1.5.
%
%   'fontsize'    = [numeric] Specify the font size of titles. Default 14.
%   
%   'plotspec'    = [cell 1x5] Specify the colour and line type for the 5
%                   plots. See `help plot` for a list of possibilities.
%                   Default {'k', 'b', 'b', 'g', 'r'}, which makes the
%                   stimulus black, the regular and inverted trials blue,
%                   the envelope FFR (adding) green, and the spectral
%                   response (subtracting) red.
%
%   'pretty'      = [true|false] Makes the background white and removes the  
%                   top x-axis and right y-axis, making plots look more
%                   "presentation-ready". Default false.
%
%   'title'       = [string] Add a title to the top center of the figure.
%                   Default empty ('') for no title.
%
%   'close'       = [0|1] Enter 1 to close the plot window after drawing
%                   it. This is useful when making (and saving) many plots 
%                   with a script.
% 
%   'filename'    = [string] Enter a filename to save the created figure
%                   to disk as a file. The filetype is determined from the
%                   file extension. Supports png, pdf, and eps output. if 
%                   no extension is given, .png is used.
%
%   'save'        = [empty|1|0] Leave this option empty ([]) to be implied
%                   with filename; i.e., save if a filename given,
%                   otherwise don't save. Enter 1 or 0 to force 
%
%   These are executed in the order that they appear in the function call. 
%   See the help of each function for more details.
%   'subset'    = Calls phz_subset.
%   'rectify'   = Calls phz_rect.
%   'filter'    = Calls phz_filter.
%   'smooth'    = Calls phz_smooth.
%   'transform' = Calls phz_transform.
%   'blsub'     = Calls phz_blsub.
%   'reject'    = Calls phz_reject.
%   'norm'      = Calls phz_norm.

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

function phzFFR_plot(PHZ, varargin)

if length(PHZ.trials) ~= 2
    error('Must have exactly 2 trial types (usually regular and inverted)')
end

% phzlab defaults
verbose = true;
region = '';
plotSpec = {'k', 'b', 'b', 'g', 'r'};
linewidth = 1.5;
fontsize = 14;
if ismember('epoch', fieldnames(PHZ.proc))
    xlt = PHZ.proc.epoch.extractWindow;
else
    xlt = [];
end
ylt = [-1 1] * 30;
ylf = [0 1]; % "f" for freq domain plots
xlf = [0 1000];
pretty = false;
dark = false;
titletext = '';
do_close = false;
filename = '';
do_save = [];

% user presets
if mod(length(varargin), 2) % if varargin is odd
    preset = varargin{1};
    varargin(1) = [];
    disp('even')
else
    preset = 'default';
end
if ismember('abrplots', fieldnames(PHZ.lib)) && ...
    ismember(preset, fieldnames(PHZ.lib.abrplots))

    preset = phzUtil_struct2pairs(PHZ.lib.abrplots.(preset));
    varargin = [preset varargin];

elseif ~strcmpi(preset, 'default')
    error(['Either the preset doesn''t exist in PHZ.lib.abrplots', ...
          ' or there are an invalid number of arguments.'])
end

% user-defined
if any(strcmp(varargin(1:2:end),'verbose'))
    i = find(strcmp(varargin(1:2:end),'verbose')) * 2 - 1;
    verbose = varargin{i+1};
    varargin([i,i+1]) = [];
end

for i = 1:2:length(varargin)
    val = varargin{i+1};
    switch lower(varargin{i})
        case 'subset',                  PHZ = phz_subset(PHZ,val,verbose);
        case {'rect','rectify'},        PHZ = phz_rectify(PHZ,val,verbose);
        case {'filter','filt'},         PHZ = phz_filter(PHZ,val,verbose);
        case {'smooth','smoothing'},    PHZ = phz_smooth(PHZ,val,verbose);
        case 'transform',               PHZ = phz_transform(PHZ,val,verbose);
        case {'blsub','blc'},           PHZ = phz_blsub(PHZ,val,verbose);
        case {'rej','reject'},          PHZ = phz_reject(PHZ,val,verbose);
        case {'norm','normtype'},       PHZ = phz_norm(PHZ,val,verbose);
        case 'region',                  region = val;
        case {'plotspec'},              plotSpec = val;
        case {'linewidth','lineweight'},linewidth = val;
        case 'fontsize',                fontsize = val;
        case {'yl','ylim','ylt','yll'}, ylt = val;
        case {'xl','xlim','xlt','xll'}, xlt = val;
        case {'ylf','ylr'},             ylf = val;
        case {'xlf','xlr'},             xlf = val;
        case 'pretty',                  pretty = val;
        case 'dark',                    dark = val;
        case {'title','titletext'},     titletext = val;
        case {'close'},                 do_close = val;
        case {'filename','file'},       filename = val;
        case {'save'},                  do_save = val;
        otherwise, warning(['Unknown parameter ', varargin{i}])
    end
end

% prepare for all plots
PHZ = phzFFR_equalizeTrials(PHZ);
PHZ = phz_summary(PHZ, 'trials');
if dark, plotSpec = strrep(plotSpec, 'k', 'w'); end

% prepare for time-domain plots (don't restrict by region)
% subtract mean so everything is zero-centered
reg = PHZ.data(1,:) - mean(PHZ.data(1,:));
inv = PHZ.data(2,:) - mean(PHZ.data(1,:));

data = {PHZ.lib.stim, ...
        reg, ...
        inv, ...
        reg + inv, ...
        reg - inv};

ytitle = {'Stimulus', ...
          {char(PHZ.lib.tags.trials(1));
          [' (', num2str(PHZ.proc.summary.nTrials(1)),' trials)']}, ...
          {char(PHZ.lib.tags.trials(2));
          [' (', num2str(PHZ.proc.summary.nTrials(2)),' trials)']}, ...
          {'Envelope FFR'; '(adding)'}, ...
          {'Spectral FFR'; '(subtracting)'}};

% prepare for spectral plots (restrict by region)
PHZ2 = phz_region(PHZ, region);
fftopts = {'units', PHZ2.units};
if ismember('fft', fieldnames(PHZ.lib))
    fftopts = [fftopts, phzUtil_struct2pairs(PHZ.lib.fft)];
end

reg = PHZ2.data(1,:) - mean(PHZ2.data(1,:));
inv = PHZ2.data(2,:) - mean(PHZ2.data(1,:));

data2 = {PHZ.lib.stim, ...
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
    if ~isempty(xlt), xlim(xlt), end
    if plots(i) == 1
        if dark
            title('Time Domain', 'color', [1 1 1] * 0.7)
        else
            title('Time Domain')
        end
    else
        ylim(ylt)
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
    [fftdata, freqs, featureTitle, units] = ...
        phzUtil_fft(data2{i}, PHZ2.srate, fftopts{:});
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
if ~isempty(titletext)
    ax=axes('Units',    'Normal', ...
            'Position', [.075 .075 .85 .89], ...
            'Visible',  'off');
    set(get(ax, 'Title'), ...
        'Visible',  'on', ...
        'fontsize', fontsize + 2)
    title(titletext);
end

% backwards compatibility: if do_save is a str, make that the filename
if ischar(do_save) && isempty(filename)
    filename = do_save;
    do_save = true;
end

% default do_save bahaviour: only save if filename specified
if isempty(do_save)
    if isempty(filename)
        do_save = false;
    else
        do_save = true;
    end
end

if do_save
    % if do_save specified as true, but no filename specified, prompt for
    %   filename
    if isempty(filename)
        [name, pathstr] = uiputfile( ...
           {'*.png';'*.eps';'*.pdf';'*.fig'}, ...
            'Save as');
        filename = fullfile(pathstr, name);
    end

    phzUtil_savefig(gcf, filename),
end

if do_close, close(gcf), end

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
