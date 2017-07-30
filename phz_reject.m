%PHZ_REJECT  Automatically mark trials for rejection based on a threshold.
%
% USAGE    
%   PHZ = PHZ_REJECT(PHZ,threshold)
% 
% INPUT   
%   PHZ       = [struct] PHZLAB data structure.
% 
%   threshold = [numeric|string] Trials with any value exceeding this 
%               value of THRESHOLD will be rejected. THRESHOLD can be a 
%               string in order to reject by standard deviation. In this 
%               case the string must be a number followed by 'sd' (e.g., 
%               '0.05sd'). A trial will be rejected if any value exceeds 
%               a THRESHOLD number of SD's of all trials.
%
%               Use 'reset' to unmark all trials for rejection (but
%               keeping manual marks made with phz_plotTrials.
%
%               Use 'resetall' to unmark all trials for rejection
%               (including those manual marks made with phz_plotTrials.
%                       
% OUTPUT  
%   PHZ.proc.reject.threshold   = The value specified in THRESHOLD.
%   PHZ.proc.reject.units       = The units of the threshold value.
%   PHZ.proc.reject.ind         = Indices of rejected trials.
% 
% EXAMPLES
%   PHZ = phz_reject(PHZ,20)      >> Mark trials with a value > 20.
% 
%   PHZ = phz_reject(PHZ,'3sd')   >> Mark trials with a value > 3 standard
%                                 deviations from the mean of all trials.
% 
%   PHZ = phz_reject(PHZ,'reset') >> Unmark trials for rejection.

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

function PHZ = phz_reject(PHZ,threshold,verbose)

if nargout == 0 && nargin == 0, help phz_reject, return, end
if nargin > 1 && isempty(threshold), return, end
if nargin < 3, verbose = true; end

% check that no other processing has been done since phz_reject
names = fieldnames(PHZ.proc);
if ismember('reject', names) && ~strcmp(names{end}, 'reject')
    error(['Other processing has been done since threshold ',...
        'rejection. Cannot undo previous rejections.'])
end

% get threshold value and rejection type
if isnumeric(threshold)
    units = PHZ.units;

elseif ischar(threshold) 
    if strcmpi(threshold(end-1:end),'sd')
        units = 'SD';
        threshold = str2double(threshold(1:end-2));

    elseif strcmpi(threshold, 'resetall')
        PHZ.proc = rmfield(PHZ.proc, 'reject');
        PHZ = phz_history(PHZ, ['All trials marked for rejection ', ...
            'were unmarked (including manual rejections).'], verbose);
        return

    elseif strcmpi(threshold, 'reset')
        if ismember('reject', names)
            if ismember('manual', fieldnames(PHZ.proc.reject))
                PHZ.proc.reject = rmfield(PHZ.proc.reject, ...
                    {'threshold', 'units', 'ind'});
            else
                PHZ.proc = rmfield(PHZ.proc, 'reject');
            end
            PHZ = phz_history(PHZ, ['All trials marked for rejection ', ...
                'were unmarked (not including manual rejections).'], verbose);
        end
        return

    end

else
    error('Problem with THRESHOLD.')
end

historyThreshold = [num2str(threshold),' ',units];

% find trials with a value greater than the threshold
if strcmpi(units, 'SD')
    % get actual std value
    adjThreshold = std(PHZ.data(:)) * threshold;
    historyThreshold = [historyThreshold, ...
        ' (', num2str(adjThreshold), ' ', PHZ.units, ')'];

    ind = max(abs(PHZ.data), [], 2) > adjThreshold;

else
    ind = max(PHZ.data, [], 2) > threshold;

end

% check that ~reject all trials or ~reject no trials
if sum(ind) == size(PHZ.data,1)
    fprintf('! This threshold would reject all trials. Aborting phz_reject.m...\n')
    fprintf('  The min threshold to reject a trial in this dataset is %f.', ...
        min(max(abs(PHZ.data), [], 2)))
    return
end

if sum(ind) == 0
    fprintf('! This threshold would not reject any trials. Aborting phz_reject.m...\n')
    fprintf('  The max value in this dataset is %f.', ...
        max(abs(PHZ.data(:))))
    return
end

% add info to proc structure
PHZ.proc.reject.threshold = threshold;
PHZ.proc.reject.units = units;
PHZ.proc.reject.ind = ind;

% add to PHZ.history
PHZ = phz_history(PHZ,['Threshold of ', historyThreshold, ' rejected ', ...
    num2str(sum(PHZ.proc.reject.ind)),' / ', num2str(length(PHZ.proc.reject.ind)), ...
    ' trials (', num2str(round(phz_rejrate(PHZ,'%'),1)), '%).'], verbose);
    
end

function rejrate = phz_rejrate(PHZ,varargin)
%PHZ_REJRATE  Get the proportion of trials that were rejected.
%
% See also PHZ_REJECT.
%
% Written by Gabriel A. Nespoli 2016-04-05. Revised 2016-02-18.

% default
valType = 'proportion';

% user-defined
for i = 1:length(varargin)
    valType = varargin{i};
end

totalNumTrials = size(PHZ.data,1);
totalRejTrials = sum(PHZ.proc.reject.ind);

rejrate = totalRejTrials / totalNumTrials;

switch lower(valType)
    case {'p','proportion'}
    case {'%','percent'}, rejrate = rejrate * 100;
    otherwise, warning('Unrecognized valType. Returning proportion.')
end
end
