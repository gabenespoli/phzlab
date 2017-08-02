%PHZ_PLOTTRIALS  Plot single trials and manually mark for rejection.
%
% USAGE
%   PHZ = phz_plotTrials(PHZ)
%   PHZ = phz_plotTrials(PHZ, startTrial, smoothing)
%
% INPUT
%   PHZ = [struct] PHZLAB data structure.
%
%   startTrial = [numeric|'reset'] If numeric, this is the trial
%       number to start at. Default is to start at the first 
%       unviewed trial (the number of times each trial has been
%       viewed is stored in PHZ.proc.reject.views).
%
%       If it is the string 'reset', all manual rejection marks 
%       are discarded. Note that trials marked with threshold 
%       rejection (i.e., with phz_reject) will be kept.
%
%       If it is the string 'resetall', all rejection marks will
%       be discarded, i.e. manual marks and threshold marks.
%
%   smoothing = [boolean|string] This will be used as input to 
%       the phz_smoothing function. 
%
% OUTPUT
%   PHZ.proc.rej.manual = [logical vector] Trials that have been
%       manually marked for rejection.
%   PHZ.proc.rej.views = [numeric] Number of times each trial
%       has been viewed.
%
% EXAMPLES
%   PHZ = phz_plotTrials(PHZ,50,true)   >> plot trial #50 using
%                                          the default smoothing
%
%   PHZ = phz_plotTrials(PHZ,[],'rms')  >> plot trial #1 using
%                                          RMS smoothing

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

function PHZ = phz_plotTrials(PHZ, startTrial, smoothing, verbose)

if nargout == 0 && nargin == 0, help phz_plotTrials, return, end
if nargout == 0
    warning('No output argument is specified. Rejection marks won''t be saved.')
end

if nargin < 2, startTrial = []; end
if nargin < 3, smoothing = false; end
if nargin < 4, verbose = true; end

if ischar(startTrial) 
    switch lower(startTrial)
        case 'reset'
            if ismember('reject', fieldnames(PHZ.proc)) && ...
                ismember('manual', fieldnames(PHZ.proc.reject))
                PHZ.proc.reject = rmfield(PHZ.proc.reject, 'manual')
                PHZ = phz_history(PHZ, 'All manual rejection marks were discarded.', verbose);
            else
                fprintf('There are no manual rejection marks to discard.\n')
            end

        case 'resetall'
            if ismember('reject', fieldnames(PHZ.proc)) 
                if ~strcmp(names{end}, 'reject')
                    error(['Other processing has been done since threshold ',...
                        'rejection. Cannot discard previous rejection marks.'])
                else
                    PHZ.proc.reject = rmfield(PHZ.proc.reject, {'threshold', 'units', 'ind'});
                end
            else
                fprintf('There are no rejection marks to discard.\n')
            end

        otherwise
            fprintf('Unknown string input to phz_plotTrials.\n')
    end
    return

elseif ~isnumeric(startTrial)
    error('startTrial must be numeric, ''reset'', or ''resetall''.')
end

% create manual rejection marks if none exists
if ~ismember('reject', fieldnames(PHZ.proc)) || ...
    ~ismember('manual', fieldnames(PHZ.proc.reject))
    PHZ.proc.reject.manual = false(size(PHZ.data,1),1);
    PHZ.proc.reject.views = zeros(size(PHZ.data,1),1);
end

% default start at first unviewed trial
if isempty(startTrial)
    currentTrial = min(find(PHZ.proc.reject.views == 0));
else
    currentTrial = startTrial;
end

% prepare for while loop
yl = [min(PHZ.data(:)) max(PHZ.data(:))];
yScaleAll = true;
keepGoing = true;

while keepGoing == true
    h = figure;
    plot(PHZ.times, PHZ.data(currentTrial,:));
    if yScaleAll, ylim(yl), end
    ylabel([PHZ.datatype, ' (', PHZ.units, ')']);
    xlabel('Time (s)');
    title({getPlotTitle(PHZ.proc.reject.manual, currentTrial);
        getTrialTagTitle(PHZ.meta.tags, currentTrial)});

    [~,~,key] = ginput(1);
    switch key
        case {32, 114} % spacebar, r
            PHZ = addView(PHZ, currentTrial);
            PHZ.proc.reject.manual = rejToggle(PHZ.proc.reject.manual, currentTrial);

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
            goto = input(['Enter trial number (1-', ...
                num2str(size(PHZ.data,1)), '): ']);
            if goto < 1 || goto > size(PHZ.data,1)
                fprintf('Trial number out of range. Displaying trial #%i.', currentTrial)
            else
                currentTrial = goto;
            end

        case 121 % y
            if yScaleAll
                yScaleAll = false;
            else
                yScaleAll = true;
            end
            
        case {27, 113} % escape, q
            keepGoing = false;
            
    end
    close(h)
end
end

function plotTitle = getPlotTitle(rej, currentTrial)
if rej(currentTrial)
    rejStatus =  '\color{red}[REJECTED]';
else
    rejStatus = '\color{blue}[INCLUDED]';
end
plotTitle = ['Trial #', num2str(currentTrial), ' ', rejStatus, '\color{black}'];

end

function trialTagTitle = getTrialTagTitle(tags, currentTrial)
trialTagTitle = '';
for labels = {'participant','group','condition','session','trials'}
    label = labels{1};
    trialTagTitle = [trialTagTitle, label, '=', ...
        char(tags.(label)(currentTrial)), '  '];
    end
end

function rej = rejToggle(rej,i)
if rej(i)
    rej(i) = false;
else
    rej(i) = true;
end
end

function PHZ = addView(PHZ, currentTrial)
PHZ.proc.reject.views(currentTrial) = PHZ.proc.reject.views(currentTrial) + 1;
end
