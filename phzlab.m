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
% X phz_changefield: Change the fields of a PHZ structure.
% 
% PROCESSING
% X phz_filter:      Butterworth filtering.
% X phz_epoch:       Split a single channel of data into trials.
% X phz_trials:      Add names to each trial of epoched data.
%   phz_rect:        Full- or half-wave rectification.
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
% Version 0.7.7 Written by Gabriel A. Nespoli 2016-04-04.

% to do:
% - phz_gather: keep rej/blc/norm/etc info, but not data
% - epoching
% - phz_changefield (do proc first?)
% - phz_create from already-epoched csv's? import from csv
% - changefield spec causes problems with ordinal?
% - phz_changfield should warn if some info is wrong
% - hide tags/norm/rect/etc. in misc, call it proc? function phz_proc to 
%   display processing? move times & srate to misc too?

% medium to do:
% - change phz_rect to phz_rectify
% - phz_plot: fix dispn
% - itpc, itrc, src (require PHZ.misc.stim?)
% - more ffr features: itpc, itrc, src, snr, playaudio, saveaudio
% - phz_plot: fix region patches - because of running phz_region, the data
%       for the whole epoch is gone
% - plot ytitle always show numeric region, like blc label
% - equal number of trials in each average?
% - PHZ.region.(region) can be a PHZ.trials-by-2 array, if there is a
%       different time region for each trial
% - phz_feature: find rate for heart rate
% - phz_audio: default plays audio, param/val to save
% - auto label FFT peaks in plot

% future to do:
% - toolbox dependencies: rms, hanning, butter/cheby/bessel, filtfilt
% - phz_subset: 'exclude' flag
% - add PHZ.spec.regionLabels so that people can rename the baseline/target
%       regions and call on these regions with these names
% - phz_feature: ability to control the kind of FFT
% - phz_trials: ability to do any number of trial types and to
%   name each of the trial types
% - phz_writetable: prompt for input folder or PHZS file, then prompt for
%       folder and filename to save as .mat or .csv
% - deal with blc for spectra. for phz_plot should the default behaviour be
%   to blc in time domain and then fft? or to blc in freq domain?
% - adding or subtracting averages of different trials?
% - scroll through individual trials, reject manually

% Change Log
% ----------

% v0.7.5
% phz_rej: ability to reject by standard deviation
% phz_summary & phz_check: have summary fill rej and blc fields with
%   '<collapsed>', adjust phz_check to account for this
% phz_save & phz_load: default is .phz file extension
% phz_changefield: function added.
% phz_transform: function added.
% phz_norm: function added.
% phz_rect: function removed (functionality replaced by phz_transform).
% phz_create: added the ability to create from AcqKnowledge files that have
%   been saved as .mat files.
% removed phz_rect from phz_plot and phz_writetable. phz_rect is now
%   considered a preprocessing function and should be used on its own or
%   through phz_gather.
% phz_trials: changed function name of phz_alternatetrials
% phzUtil_findAudioMarkers: function added.
% phz_blc: removed restriction that blc be done before rej

% v0.7.7
% - swap grouping vars and order, add tags field. 'visible' grouping
%   variable values are now just the unique values of the trial tags.
% - phz_writetable: option to stack to one case per row ("one participant
%       per row")

help phzlab

end