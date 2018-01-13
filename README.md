# PHZLAB: A MATLAB toolbox for analysis of physiological data.
PHZ structures are created for each recording of data, and can be filtered, epoched, and otherwise preprocessed. Multiple PHZ structures can be combined into a single one, enabling powerful plotting functionality. Data can then be exported into a table for statistical analyses.

## Functions

### File I/O
- phz_create:       Create a PHZ structure from a data file.
- phz_combine:       Combine many PHZ structures into a single one.
- phz_save:         Save a PHZ structure.
- phz_load:         Load a PHZ structure.
- phz_field:        Change the values of certain PHZ structure fields.

### Processing
- phz_filter:       Butterworth filtering (requires Signal Processing Toolbox).
- phz_epoch:        Split a single channel of data into trials.
- phz_triallabels:  Add names to each trial of epoched data.
- phz_rectify:      Full- or half-wave rectification.
- phz_smooth:       Sliding window averaging (incl. RMS)
- phz_transform:    Transform data (e.g., square root, etc.)
- phz_rej:          Remove trials with values exceeding a threshold or SD.
- phz_blsub:        Subtract mean of baseline region from each trial.
- phz_norm:         Normalize across specified grouping variables.
- phz_proc:         Apply many processing functions in one step.

### Analysis
- phz_subset:       Keep data only from specified grouping variables.
- phz_region:       Keep only data from a certain time region.
- phz_feature:      Convert data to the specified feature.
- phz_summary:      Average across grouping variables.

### Exporting
- phz_plot:         Visualize data as line or bar graphs.
- phz_writetable:   Export features to a MATLAB table or csv file.

## Version
The current version is 0.9 beta.

## Licence
This software is covered by the GNU General Public Licence v3.
