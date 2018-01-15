# PHZLAB: A MATLAB toolbox for analysis of physiological data.

PHZLAB is a MATLAB Toolbox for analyzing physiological data, both peripheral (e.g., SCL, EMG) and neural (e.g., ABR, FFR).

## How it works

PHZLAB is inspired by [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php), and borrows the idea of a having a single variable (a struct called PHZ) to hold data and metadata for a given file or files. All functions operate on this PHZ variable, keeping a log of processing (PHZ.history), as well as the PHZLAB settings required to reproduce all processing (PHZ.proc). There is no GUI (graphical user interface) for PHZLAB, only a set of functions that can be called from the command window or incorporated into your own scripts. Once processed, data can be exported for statistical analysis, and publication-ready plots can be easily produced.

Tutorial and example scripts coming soon.

## Functions

The following is a list of functions included in PHZLAB that can be from your script.

### File I/O
- `phz_create`:       Create a PHZ structure from a data file.
- `phz_combine`:      Combine many PHZ structures into a single one.
- `phz_save`:         Save a PHZ structure.
- `phz_load`:         Load a PHZ structure.
- `phz_field`:        Change the values of certain PHZ structure fields.

### Processing
- `phz_filter`:       Butterworth filtering (requires Signal Processing Toolbox).
- `phz_epoch`:        Split a single channel of data into trials.
- `phz_labels`:       Add names to each trial of epoched data.
- `phz_rectify`:      Full- or half-wave rectification.
- `phz_smooth`:       Sliding window averaging (incl. RMS)
- `phz_transform`:    Transform data (e.g., square root, etc.)
- `phz_reject`:       Mark trials with values exceeding a threshold or SD.
- `phz_blsub`:        Subtract mean of baseline region from each trial.
- `phz_norm`:         Normalize across specified grouping variables.
- `phz_dicard`:       Remove trials marked by reject, subset, and review.
- `phz_proc`:         Apply many processing functions in one step.

### Analysis
- `phz_subset`:       Mark data only from specified grouping variables.
- `phz_region`:       Keep only data from a certain time region.
- `phz_feature`:      Convert data to the specified feature.
- `phz_summary`:      Average across grouping variables.

### Visualization and Export
- `phz_review`:       Inspect individual trials.
- `phz_plot`:         Visualize data as line or bar graphs.
- `phz_writetable`:   Export features to a MATLAB table or csv file (e.g., for R).

### Specialty Functions
- `phzABR_equalizeTrials`: Equalize the number of trials of each polarity.
- `phzABR_summary`:   Special case accounting for different polarities.
- `phzABR_plot`:      Summary plot for ABR data (coming soon).
- `phz_BTexport`:     Export data to [Brainstem Toolbox](http://www.brainvolts.northwestern.edu/) (coming soon).
- `phzBiopac_readJournalMarkers`: Read marker times from Biopac AcqKnowledge journal text.
- `phzUtil_findAudioMarkers`: Search for audio onsets in a signal.

## Version
The current version is 1 beta.

## Licence
This software is covered by the GNU General Public Licence v3.
