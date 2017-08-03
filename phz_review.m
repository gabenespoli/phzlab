%PHZ_REVIEW  Plot single trials and manually mark for rejection.
%   Keyboard controls are used to navigate between plots and 
%   mark them for rejection.
%
% USAGE
%   PHZ = phz_review(PHZ)
%   PHZ = phz_review(PHZ, startTrial)
%
% INPUT
%   PHZ = [struct] PHZLAB data structure.
%
%   startTrial = [numeric|'reset'] If numeric, this is the trial
%       number to start at. Default is to start at the first 
%       unviewed trial (the number of times each trial has been
%       viewed is stored in PHZ.proc.review.views).
%
%       If it is the string 'reset', all manual rejection marks 
%       are discarded. Note that trials marked with threshold 
%       rejection (i.e., with phz_reject) will not be discarded.
%
% KEYBOARD CONTROLS
%   escape/q = Quit phz_review The plot window is closed.
%
%   right/down/j/l/n = Cycle trials forward.
%
%   left/up/h/k/p = Cycle trials backward.
%
%   g = Jump to a specific trial. Enter trial number in the
%       command window.
%
%   G (shift-g) = Jump to a random trial. This can be useful for
%       spot-checking the dataset.
%
%   space/r = Toggle rejection mark for the current trial.
%
%   t = Toggle the display of the rejection threshold. If the y-axis
%       scale is set for all trials, the y-axis scale will be adjusted
%       to include this threshold. If the y-axis scale is set for the 
%       current trial, it will not.
%
%   i = Toggle display of trial info. i.e., this will display the
%       values of the grouping variables participant, group, 
%       condition, session, and trials for the current trial.
%
%   y = Toggle y-axis scale. Default is to have the same scale
%       for all trials (i.e., the range of the y-axis matches the
%       range of the entire data set). Alternate is to scale the
%       plot to the range of the current trial.
%
%   s = Toggle smoothing. Default is no smoothing. Alternate is 
%       to call phz_smooth with its default parameters. This can
%       be changed using S (shift-s; see below).
%
%   S (shift-s) = Enter new smoothing parameters. This will bring
%       focus to the command window and prompt for a smoothing type
%       (i.e., the `win` parameter in phz_smooth).
%
%   +/= and -/_ = Increase and decrease font size of plot titles.
%
%   f = Enter specific font size in command window.
%
% OUTPUT
%   PHZ.proc.review.keep = [logical] Trials that have been
%       manually marked for rejection. 1 = keep, 0 = reject.
%
%   PHZ.proc.review.views = [numeric] Number of times each trial
%       has been viewed.
%
% EXAMPLES
%   PHZ = phz_review(PHZ) >> plot the first unviewed trial
%   PHZ = phz_review(PHZ,50) >> plot trial #50

% Copyright (C) 2017 Gabriel A. Nespoli, gabenespoli@gmail.com
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

function PHZ = phz_review(PHZ, startTrial, verbose)

if nargout == 0 && nargin == 0, help phz_review, return, end
if nargout == 0
    warning('No output argument is specified. Rejection marks won''t be saved.')
end

if nargin < 2, startTrial = []; end
if nargin < 3, verbose = true; end

if ischar(startTrial) && strcmpi(startTrial, 'reset')
    if ismember('review', fieldnames(PHZ.proc))
        PHZ.proc = rmfield(PHZ.proc, 'review');
        PHZ = phz_history(PHZ, 'Manual rejection marks were discarded.', verbose);
    else
        fprintf('There are no manual rejection marks to discard.\n')
    end

elseif ~isnumeric(startTrial)
    error('startTrial must be numeric, ''reset'', or ''resetall''.')

end

% create manual rejection marks if none exists
if ~ismember('review', fieldnames(PHZ.proc))
    PHZ.proc.review.keep = true(size(PHZ.data,1),1);
    PHZ.proc.review.views = zeros(size(PHZ.data,1),1);
end

% defaults
if isempty(startTrial) % find first unviewed trial
    currentTrial = find(PHZ.proc.review.views == 0, 1);
else
    currentTrial = startTrial;
end
yScaleAll = true;
smooth = false;
smoothWin = 'mean0.05';
fontsize = 12;
showTags = false;
rejectionThreshold = [];

% prepare for while loop
PHZ_plot = PHZ; % make copy so we can change smoothing
keepGoing = true;

while keepGoing

    % plot trial data
    h = figure;
    plot(PHZ_plot.times, PHZ_plot.data(currentTrial,:));
    if ~isempty(rejectionThreshold)
        lineHandle = line([PHZ_plot.times(1) PHZ_plot.times(end)], ...
            [rejectionThreshold rejectionThreshold]);
        set(lineHandle, 'Color', 'r', 'LineWidth', 1)
    end

    % make titles and axis labels
    plotTitle = ['Trial #', num2str(currentTrial)];
    if showTags
        plotTitle = [plotTitle; {getTrialTagTitle(PHZ.meta.tags, currentTrial)}];
    end
    plotTitle = [plotTitle; {getKeepStatusStr(PHZ, currentTrial)}];

    ytitle = [PHZ.datatype, ' (', PHZ.units, ')'];
    ytitle2 = '';
    if yScaleAll
        ylim(getYL(PHZ_plot.data, rejectionThreshold))
        ytitle2 = [ytitle2, ' [scale: all]'];
    else
        ylim(getYL(PHZ_plot.data(currentTrial,:), []))
        ytitle2 = [ytitle2, ' [scale: current]'];
    end
    if smooth
        ytitle2 = [ytitle2, ' [smoothing: ',PHZ_plot.proc.smooth,']'];
    end

    % apply axis titles
    ylabel({ytitle; ytitle2})
    xlabel('Time (s)')
    title(plotTitle)
    set(gca, 'Fontsize', fontsize)

    % wait for valid user input
    key = [];
    while isempty(key)
        [~,~,key] = ginput(1);
    end

    % carry out user command
    switch key
        case {32, 114} % spacebar, r
            PHZ.proc.review.keep = keepStatusToggle(PHZ.proc.review.keep, currentTrial);

        case 116 % t
            if isempty(rejectionThreshold)
                if ismember('reject', fieldnames(PHZ.proc))
                    if strcmpi(PHZ.proc.reject.units, 'SD')
                        rejectionThreshold = std(PHZ.data(:)) * PHZ.proc.reject.threshold;
                    else
                        rejectionThreshold = PHZ.proc.reject.threshold;
                    end
                end
            else
                rejectionThreshold = [];
            end

        case {29, 31, 106, 108, 110} % right, down, j, l, n
            PHZ = addView(PHZ, currentTrial);
            currentTrial = currentTrial + 1;
            if currentTrial > size(PHZ.data,1), currentTrial = 1; end

        case {28, 30, 104, 107, 112} % left, up, h, k, p
            PHZ = addView(PHZ, currentTrial);
            currentTrial = currentTrial - 1;
            if currentTrial < 1, currentTrial = size(PHZ.data,1); end

        case 103 % g
            PHZ = addView(PHZ, currentTrial);
            goto = input(['Enter trial number (1-', num2str(size(PHZ.data,1)), '): ']);
            if ~isempty(goto)
                if goto < 1 || goto > size(PHZ.data,1)
                    fprintf('Trial number out of range. Displaying trial #%i.', currentTrial)
                else
                    currentTrial = goto;
                end
            end 

        case 71 % G (capital g)
            PHZ = addView(PHZ, currentTrial);
            currentTrial = randi(size(PHZ.data,1));

        case 121 % y
            if yScaleAll
                yScaleAll = false;
            else
                yScaleAll = true;
            end

        case 115 % s
            if smooth
                PHZ_plot = PHZ;
                smooth = false;
            else
                PHZ_plot = phz_smooth(PHZ, smoothWin, false);
                smooth = true;
            end

        case 83 % S (capital s)
            tempWin = input('Enter a new smoothing parameter: ', 's');
            if ~isempty(tempWin)
                try
                    PHZ_plot = phz_smooth(PHZ, tempWin, false);
                    smoothWin = tempWin;
                    smooth = true;
                catch
                    fprintf('Invalid smoothing parameter. Smoothing was not changed.\n')
                end
            end
            
        case 105 % i
            if showTags
                showTags = false;
            else
                showTags = true;
            end

        case 102 % f
            fontsize = input(['Enter new font size (current = ', ...
                num2str(fontsize), '): ']);

        case {43, 61} % +, =
            fontsize = fontsize + 2;
            fprintf('Increasing font size to %i.\n', fontsize)

        case {45, 95} % -, _
            if fontsize > 2
                fontsize = fontsize - 2;
                fprintf('Decreasing font size to %i.\n', fontsize)
            else
                fprintf('Cannot decrease font size below %i.\n', fontsize)
            end

        case {27, 113} % escape, q
            keepGoing = false;
            
        otherwise
            fprintf('Invalid input. Use ''q'' to quit.\n')

    end
    close(h)
end
end

function str = getKeepStatusStr(PHZ, currentTrial)
names = fieldnames(PHZ.proc);

str = 'review: ';
if PHZ.proc.review.keep(currentTrial)
    str = [str, '\color{blue}[INCLUDED]\color{black}'];
else
    str = [str, '\color{red}[REJECTED]\color{black}'];
end

if ismember('reject', names)
    if PHZ.proc.reject.keep(currentTrial)
        str = [str, ' reject: \color{blue}[INCLUDED]\color{black}'];
    else
        str = [str, ' reject: \color{red}[REJECTED]\color{black}'];
    end
end

ind = find(contains(names,'subset'));
if ~isempty(ind)
    subsetKeepStatus = true;
    for i = 1:length(ind)
        if PHZ.proc.(names{ind(i)}).keep(currentTrial) == false
            subsetKeepStatus = false;
            break
        end
    end
    if subsetKeepStatus
        str = [str, ' subset(s): \color{blue}[INCLUDED]\color{black}'];
    else
        str = [str, ' subset(s): \color{red}[REJECTED]\color{black}'];
    end
end
end

function trialTagTitle = getTrialTagTitle(tags, currentTrial)
trialTagTitle = '';
for labels = {'participant','group','condition','session','trials'}
    label = labels{1};
    trialTagTitle = [trialTagTitle, label, '=', ...
        char(tags.(label)(currentTrial)), '  ']; %#ok<*AGROW>
end
end

function keepStatus = keepStatusToggle(keepStatus, currentTrial)
if keepStatus(currentTrial)
    keepStatus(currentTrial) = false;
else
    keepStatus(currentTrial) = true;
end
end

function PHZ = addView(PHZ, currentTrial)
PHZ.proc.review.views(currentTrial) = PHZ.proc.review.views(currentTrial) + 1;
end

function yl = getYL(data, rejectionThreshold)
ymin = min(data(:));
ymax = max(data(:));
if rejectionThreshold 
    if rejectionThreshold > max(data(:))
        ymax = rejectionThreshold;
    end
    if rejectionThreshold < min(data(:))
        ymin = rejectionThreshold;
    end
end
yl = [ymin ymax];
end
