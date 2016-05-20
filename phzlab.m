function phzlab
%PHZLAB  A MATLAB toolbox for analysis of physiological data.
% PHZ structures are created for each recording of data, and can be
%   filtered, epoched, and otherwise preprocessed. Multiple PHZ structures
%   can be gathered into a single one, enabling powerful plotting
%   functionality. Data can then be exported into a table for statistical
%   analyses.
% 
% * = These functions are reversible.
% X = These functions are not available yet.
% 
% FILE I/O
%   phz_create:      Create a PHZ structure from a data file.
%   phz_gather:      Gather many PHZ structures into a single one.
%   phz_save:        Save a PHZ structure.
%   phz_load:        Load a PHZ structure.
%   phz_field:       Change the fields of a PHZ structure.
% 
% PROCESSING
% X phz_filter:      Butterworth filtering.
% X phz_epoch:       Split a single channel of data into trials.
% X phz_trials:      Add names to each trial of epoched data.
%   phz_rectify:     Full- or half-wave rectification.
%   phz_smooth:      Sliding window averaging (incl. RMS)
%   phz_transform:   Transform data (e.g., square root, etc.)
% * phz_rej:         Remove trials with values exceeding a threshold.
% * phz_blc:         Subtract mean of baseline region from each trial.
% * phz_norm:        Normalize across specified grouping variables.
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
% 
% Version 0.8.4 dev Written by Gabriel A. Nespoli 2016-04-06.

help phzlab

end