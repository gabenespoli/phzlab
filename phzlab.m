function phzlab
%PHZLAB  A MATLAB toolbox for analysis of physiological data.
% 
% PHZ structures must first be created from epoched data. The fields of
%   the PHZ structure should be filled manually or with a script. The main
%   functions are listed below:
% 
% FILE I/O: Create and load PHZ and PHZS structures.
%   phz_create:     Create a PHZ structure.
%   phz_gather:     Create a PHZS structure from many PHZ structures.
%   phz_save:       Save a PHZ or PHZS structure.
%   phz_load:       Load a PHZ or PHZS structure.
% 
% PROCESSING: Process data in PHZ.data. blc and rej are reversible. When
%             calling these from exporting functions, this is the order in
%             which they are applied.
%   phz_subset:     Keep only specified participant/group/session/trials.
%   phz_rect:       Full- or half-wave rectification.
%   phz_blc:        Subtract mean of baseline region from each trial.
%   phz_rej:        Remove trials with values exceeding a threshold.
%   phz_region:     Keep only data from a certain time region.
%   phz_feature:    Convert data to the specified feature.
%   phz_summary:    Average across participant/group/session/trials.
% 
% EXPORTING: Export functions can be used in conjunction with processing 
%            functions to export processed data without changing
%            PHZ/PHZS files.
%   phz_plot:       Visualize data.
%   phz_writetable: Calculate features and create a MATLAB table or
%                   a .csv file including grouping labels.
% 
% Version 0.7.5 Written by Gabriel A. Nespoli 2016-03-23.

% upcoming features:
% ---------------------------------------------
% - display nTrials and nParticipants in plots
% - highlight regions in plots
% - more ffr features: itpc, itrc, src, snr, playaudio, saveaudio
% - "one participant per row" in writetable
% - epoching
% - streamlined import from biopac
% ---------------------------------------------

% to do:
% - phz_plot: fix dispn
% - phz_plot: fix region patches - because of running phz_region, the data
%       for the whole epoch is gone
% - itpc, itrc, src (require PHZ.misc.stim?)
% - equal number of trials in each average?

% medium to do:
% - phz_writetable: option to stack to one case per row ("one participant
%       per row")
% - PHZ.regions.(region) can be a PHZ.trials-by-2 array, if there is a
%       different time region for each trial
% - make phz_create_loop
% - add difference between PHZ.regions and PHZ.region
% - phz_feature: find rate for heart rate
% - phz_audio: default plays audio, param/val to save
% - auto label FFT peaks in plot
% - normalization, check wiki, sqrt transformations for scl? put your own
%   transformation?

% future to do:
% - toolbox dependencies: rms, hanning
% - phz_subset: 'exclude' flag
% - add PHZ.spec.regionLabels so that people can rename the baseline/target
%       regions and call on these regions with these names
% - phz_feature: ability to control the kind of FFT
% - phz_alternatetrials: ability to do any number of trial types
% - phz_writetable: prompt for input folder or PHZS file, then prompt for
%       folder and filename to save as .mat or .csv
% - phz_reject: reject reaction times above a threshold
% - deal with blc for spectra. for phz_plot should the default behavoiur be
%   to blc in time domain and then fft? or to blc in freq domain?
% - adding or subtracting averages of different trials?

% Change Log
% ----------

% v0.7.5
% phz_rej: ability to reject by standard deviation
% phz_summary & phz_check: have summary fill rej and blc fields with
%   '<collapsed>', adjust phz_check to account for this

help phzlab

end