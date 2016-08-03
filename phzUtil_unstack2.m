%PHZUTIL_UNSTACK2  Calls unstack.m twice in succession in order to be able
%   to unstack 2 variables. Requires the Stats Toolbox (for unstack.m).
%   See the help for unstack for more details.
%
% USAGE
%   wide = unstack2(tall,dataVar,indVars)
%
% INPUT
%   tall      = [table]
%
%   dataVar   = [string|cell of strings]
%
%   indVar    = [string|cell of strings]
%
% OUTPUT
%   wide      = [table]
% 

function d = phzUtil_unstack2(d,dataVars,unstackVars)

unstackVars = cellstr(unstackVars);
if length(unstackVars) > 2, error('Can''t have more than 2 indVars.'), end

origVars = d.Properties.VariableNames;

d = unstack(d,dataVars,unstackVars{1});

if length(unstackVars) == 2
    dataVars = d.Properties.VariableNames;
    rm = ismember(dataVars,origVars);
    dataVars(rm) = [];
    d = unstack(d,dataVars,unstackVars{2});
end
end