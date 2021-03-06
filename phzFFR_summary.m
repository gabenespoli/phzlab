%PHZFFR_SUMMARY  Combine polarities in an appropriate way for FFR data.
%   Polarities must be labeled with the 'trials' grouping variable (i.e.,
%   PHZ.trials) and must have exactly two unique categories. First the
%   number of trials in each category is equalized using
%   phzFFR_equalizeTrials, and then phz_summary is used to a) average
%   together each polarity (while maintaining the other grouping
%   variables), and then b) combine the resulting two waveforms using
%   the specified summary function (i.e., add, subtract, or mean).
%
% USAGE
%   PHZ = phzFFR_summary(PHZ, summaryFunction)
%   
% INPUT
%   PHZ               = [struct] PHZLAB data structure.
%
%   summaryFunction   = [string] Function to use to combine trials. Can
%                       be either 'add'/'efr', 'subtract'/'ffr', or 'mean'.
% NOTE
% How summaryFunction works with phz_summary:
%   The default method for summarizing trials is to average them together
%   ('mean'). Include an 'add' in KEEPVARS to sum the trials instead, or
%   a 'subtract' to subtract them. Note that for addition and subtraction
%   there must be exactly two trials for every unique combination of the
%   values of KEEPVARS. These must be used with at least one other
%   KEEPVARS. The default for phz_summary is 'mean', but there is no
%   default for phzFFR_summary; this parameter must be specified.

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

function PHZ = phzFFR_summary(PHZ, summaryFunction, verbose)

% defaults
if nargin < 3, verbose = true; end
grpVar = 'trials'; % For now this function can only act on the 'trials'
%   grouping variable. This was done to simplify the input args, since
%   this is such a special case anyway.

% make sure there are exactly two labels in the grpVar tags
if length(unique(PHZ.lib.tags.(grpVar))) ~= 2
    error('There must be exactly two labels in the specified grouping variable.')
end

% equalize number of trials
PHZ = phzFFR_equalizeTrials(PHZ, grpVar, verbose);

% summary by everything (i.e., create averages for each of the 2 labels)
PHZ = phz_summary(PHZ, 'all', verbose);

% combine the two averages using the summary function
PHZ = phz_summary(PHZ, grpVar, summaryFunction, verbose);

end
