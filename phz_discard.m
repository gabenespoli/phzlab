%PHZ_DISCARD  Actually remove trials that are marked for rejection.
%   Trials can be marked using phz_reject, phz_review, and 
%   phz_subset. This function is primarily used by phz_summary,
%   phz_feature, phz_plot, and phz_writetable.
%
% USAGE
%   PHZ = phz_discard(PHZ)
%
% INPUT
%   PHZ = [struct] PHZLAB data structure.
%   
%   At least one of the following fields should be populated using
%   the appropriate function:
%       PHZ.proc.reject.keep
%       PHZ.proc.review.keep
%       PHZ.proc.subset.keep
%
% OUTPUT
%   PHZ.data  = Data with marked trials removed.
%
%   PHZ.lib.tags.* = The trial tags (i.e., participant, group,
%               condition, session, trials) also have the 
%               corresponding rows removed.
%
%   PHZ.resp.* = The behavioural responses also have the 
%               corresponding rows removed.

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

function [PHZ, keep] = phz_discard(PHZ, verbose)

if nargin == 0 && nargout == 0, help phz_discard, return, end
if nargin < 2, verbose = true; end
keep = true(size(PHZ.data,1), 1); % keep all trials initially

% find all proc fields that have discard marks
names = fieldnames(PHZ.proc);
ind = find(contains(names,{'reject', 'review', 'subset'}));

if isempty(ind)
    return
end

% combine all 'keep' vectors with logical AND
% all of the 'keep' fields have 1 = keep and 0 = discard
% i.e., if at least one of the vectors has a 0 for a trial,
%   then it will be discarded
for i = 1:length(ind)
    name = names{ind(i)};
    if ~PHZ.proc.(name).discarded
        keep = keep & PHZ.proc.(name).keep;
        PHZ.proc.(name).discarded = true;
    end
end

if all(keep)
    return
end

procs = strjoin(names(ind),' ');

% actually reject the trials
PHZ.data = PHZ.data(keep, :);

for fields = {'participant','group','condition','session','trials'}
    field = fields{1};
    if ~strcmp('<collapsed>', PHZ.lib.tags.(field))
        PHZ.lib.tags.(field) = PHZ.lib.tags.(field)(keep);
    end

    % if we've lost a whole category, remove it from PHZ.lib.spec
    cats = PHZ.(field);
    newcats = unique(PHZ.lib.tags.(field));
    ind = ismember(cats, newcats); % ind of cats to keep
    PHZ.lib.spec.(field) = PHZ.lib.spec.(field)(ind);
end

qnum = {'q1','q2','q3','q4','q5'};
suffix = {'', '_acc', '_rt'};
for i = 1:length(qnum)
    for j = 1:length(suffix)
        field = [qnum{i}, suffix{j}];
        if ~isempty(PHZ.resp.(field))
            PHZ.resp.(field) = PHZ.resp.(field)(keep);
        end
    end
end

PHZ.proc.discard.procs = procs;
PHZ.proc.discard.keep = keep;

historyStr = ['Discarded ', ...
              num2str(sum(PHZ.proc.discard.keep==0)), ...
              ' of ', ...
              num2str(length(PHZ.proc.discard.keep)), ...
              ' trials by ''', ...
              procs,'''.'];
PHZ = phz_history(PHZ, historyStr, verbose);

end
