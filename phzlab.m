%PHZLAB  A MATLAB toolbox for analysis of physiological data.
% PHZ structures are created for each recording of data, and can be
%   filtered, epoched, and otherwise preprocessed. Multiple PHZ structures
%   can be combined into a single one, enabling powerful plotting
%   functionality. Data can then be exported into a table for statistical
%   analyses.
% 
% Version 0.9 (beta).
% 
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
% 
% FILE I/O
%   phz_create:      Create a PHZ structure from a data file.
%   phz_combine:     Combine many PHZ structures into a single one.
%   phz_save:        Save a PHZ structure.
%   phz_load:        Load a PHZ structure.
%   phz_field:       Change the values of certain PHZ structure fields.
% 
% PROCESSING
%   phz_transform:   Transform data (e.g., square root, etc.)
%   phz_filter:      Butterworth filtering.
%   phz_rectify:     Full- or half-wave rectification.
%   phz_smooth:      Sliding window averaging (incl. RMS)
%   phz_epoch:       Split a single channel of data into trials.
%   phz_trials:      Add names to each trial of epoched data.
%   phz_rej:         Remove trials with values exceeding a threshold or SD.
%   phz_blsub:       Subtract mean of baseline region from each trial.
%   phz_norm:        Normalize across specified grouping variables.
% 
% ANALYSIS
%   phz_subset:      Keep data only from specified grouping variables.
%   phz_region:      Keep only data from a certain time region.
%   phz_feature:     Convert data to the specified feature.
%   phz_summary:     Average across grouping variables.
% 
% EXPORTING
%   phz_plot:        Visualize data as line or bar graphs.
%   phz_writetable:  Export features to a MATLAB table or csv file.

function phzlab, help phzlab, end
