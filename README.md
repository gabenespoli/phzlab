<a name="phzlab"></a>

# PHZLAB: A MATLAB toolbox for analyzing physiological data.

![PHZLAB Logo](img/phzlab_logo.png)

PHZLAB is a MATLAB Toolbox for analyzing physiological data, both
peripheral (e.g., EDA, EMG) and neural (i.e., ABR).

## Table of Contents

1. [How it works](#how-it-works)
2. [Tutorial](#tutorial)
    1. [Loading data](#tutorial-loading)
    2. [Processing](#tutorial-preprocessing)
    3. [Combining PHZ files](#tutorial-combining)
    4. [Plotting](#tutorial-plotting)
    5. [Exporting](#tutorial-exporting)
3. [List of Functions](#functions)
    1. [File I/O](#functions-fileio)
    2. [Processing](#functions-processing)
    3. [Analysis](#functions-analysis)
    4. [Visualization and Export](#functions-visualization)
    5. [Specialty Functions](#functions-specialty)
4. [Installation](#installation)
    1. [System Requirements](#installation-system-requirements)
    2. [Install with Git](#installation-git)
    3. [Install with manual download](#installation-download)
    4. [Add PHZLAB to the MATLAB path](#add-to-path)
5. [Acknowledgements](#acknowledgements)
6. [License](#license)

<a name="how-it-works"></a>

## 1. How it works
PHZLAB is inspired by [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php), 
and borrows the idea of a having a single variable (a struct called PHZ)
to hold data and metadata for a given file or files. All functions operate
on this `PHZ` variable, keeping a log of processing (`PHZ.history`), as well
as the PHZLAB settings required to reproduce all processing (`PHZ.proc`).
There is no GUI (graphical user interface) for PHZLAB, only a set of
functions that can be called from the command window or incorporated into
your own scripts. Once processed, data can be exported for statistical
analysis, and publication-ready plots can be easily produced.

The `PHZ` structure variable has the following fields:
```matlab
% general info fields
PHZ.study
PHZ.datatype

% grouping variables
PHZ.participant
PHZ.group
PHZ.condition
PHZ.session
PHZ.trials

% data fields
PHZ.region
PHZ.times
PHZ.data
PHZ.units
PHZ.srate
PHZ.resp

% 'system' fields
PHZ.proc
PHZ.lib
PHZ.etc
PHZ.history
```

The **general info** fields are strings, and only `PHZ.datatype` is used by
PHZLAB, to label plots. `PHZ.study` is mostly for posterity.

The **grouping variables** fields are categorical variables, and contain the
unique values from the corresponding categorical vectors in `PHZ.lib.tags`.
`PHZ.lib.tags` contains categorical vectors, the same length as the number of
trials, with labels for each grouping variable. The reason these tags are
'hidden' in the lib field is that when you type `PHZ` in the MATLAB command
window, you can quickly see what trial types and conditions are represented
in this dataset. For example, if there are 6 different trials in this dataset
from two different participants, maybe
`PHZ.lib.tags.participant = [1 1 1 2 2 2]`,
which means that `PHZ.participant = [1 2]`. These fields are automatically
created by PHZLAB (in `phz_check.m`). If you wish to manually edit some tags,
edit the vectors in `PHZ.lib.tags` and then run `phz_check`.

The **data** fields contain the actual data and some information pertaining
specifically to them. `PHZ.data` is the actual data, and is a trials (rows) by
time (columns) numeric matrix. The number of rows (trials) should always be the
same as the length of the `PHZ.lib.tags` fields. `PHZ.times` is a vector the same
length as the number of columns in `PHZ.data`, and contains the corresponding time
values for each sample. `PHZ.region` contains a bunch of 1-by-2 vectors of start
and end times for regions of interest. Defining these regions will allow you to
call them by name from PHZLAB's functions. `PHZ.units` is a string of the units
of the data, and is mainly used to label plots. `PHZ.srate` is the sampling rate
of the data, and is mainly used to calculate frequency-domain features.
`PHZ.resp` is a place where you can store behavioural responses for each trial,
as well as the accuracy and reaction time of those responses. This will allow
you to draw plots of these responses, or restrict your dataset based on these
values.

The **system** fields contain some "under the hood" stuff. `PHZ.proc` and
`PHZ.history` both contain a chronological account of what has been done to this
variable. `PHZ.history` is a cell array of strings, with time stamps and functions
that were called of everything that has happened. `PHZ.proc` is a struct that
contains only the processing functions that were applied, as well as the
settings that were used. `PHZ.lib` contains information about tags, plotting
specifications, and the filename on disk. `PHZ.lib.spec` has a field for each
of the grouping variables, that is a cell array the same length as the number
of unique values in that variable. These fields can be used to control the
colors and types of lines used in plots. See `help plot` for more information
on MATLAB's plot spec. `PHZ.etc` is for you to put whatever other information
you would like to keep with this file. PHZLAB doesn't do anything with this
field.

<a name="tutorial"></a>

## 2. Tutorial

The following is a very basic walk through of how PHZLAB is used. See the
[examples](examples) folder for template scripts that you can use.

<a name="tutorial-loading"></a>

### 2.i Loading data

Usually you will create an empty PHZ variable and manually add your data into
it.
```matlab
PHZ = phz_create('blank');
PHZ.data = data;
PHZ.srate = 1000;
PHZ.participant = 1;
PHZ.group = 'control';
PHZ.units = 'V';
```

If you recorded these data using Biopac AcqKnowledge and saved the .acq file
as a .mat file (using the 'Save as...' menu in AcqKnowledge), then you can
specify a specific channel from that file to load. PHZLAB will automatically
read the sampling rate, datatype, and units. You can override these values with
parameter-value pairs:
```matlab
PHZ = phz_create( ...
    'filename',     'my_biopac_data.mat', ...
    'filetype',     'acq', ...
    'channel',      1, ...
    'datatype',     'EMG', ...
    'units',        'V');
```

Change the units to millivolts. If these are Biopac data, you can use the
special Biopac transform function to account for the hardware gain setting on
the amplifier when converting the units:
```matlab
% manual calculation and changing units
PHZ = phz_transform(PHZ, 1000);
PHZ.units = 'mV';

% using Biopac gain (hardware gain value on amplifier was 50)
PHZ = phzBiopac_transform(PHZ, 50, 'm');
```

Filter the data with a 10-500 Hz bandpass and a 60 Hz notch filter:
```matlab
PHZ = phz_filter(PHZ, [10 500 60]);
```

Split a continuous data file into epochs and label them. This requires that you
already have the start time for each epoch. You must also specify the window
around each start time to extract. All epochs must be the same length. (Given
the diversity of ways of recording epoch times, PHZLAB does not have a "catch
all" way of extracting them, but it does have a couple of helper functions. See
`phzUtil_findAudioMarkers.m` and `phzBiopac_readJournalMarkers.m.`)
```matlab
% times is a vector of start times in samples
PHZ = phz_epoch(PHZ, times, [-1 5]);

% labels is a cell array of labels for each trial
PHZ = phz_labels(PHZ, labels);
```

Save this file to disk:
```matlab
phz_save(PHZ, 'folder/for/phzfiles/datafile1.phz');
```

<a name="tutorial-preprocessing"></a>

### 2.ii Processing

Subtract the mean of a baseline period from each epoch. You can manually enter
a time range, or, if you've set the appropriate `PHZ.region` field, you can use
that name instead:
```matlab
% manually enter time region
PHZ = phz_blsub(PHZ, [-1 0]);

% use the PHZ.region baseline field
PHZ.region.baseline = [-1 0];
PHZ = phz_blsub(PHZ, 'baseline');

% if no region is given, the region called 'baseline' is used
PHZ = phz_blsub(PHZ);
```

Mark trials for rejection that contain values above a threshold.
```matlab
PHZ = phz_reject(PHZ, 0.05);
```

<a name="tutorial-combining"></a>

### 2.iii Combining PHZ files

PHZLAB can combine all .phz files in a given folder into a single PHZ variable.
This lets you apply processing functions to the whole dataset at once, and
allows you to easily make plots that include all data.
```matlab
PHZ = phz_combine('folder/for/phzfiles');
```

If there is too much data to put into a single file, PHZLAB will throw an error
and suggest that you do some preprocessing (including averaging, e.g., by using
`phz_summary`) before combining the files. This can be done from the call to
`phz_combine`. You won't be able to change this processing later without
re-combining the files with different settings:
```matlab
PHZ = phz_combine('folder/for/phzfiles', ...
                  'blsub',    [-1 0], ...
                  'reject',   0.05, ...
                  'summary',  {'participant', 'group', 'trials'});
```

<a name="tutorial-preprocessing"></a>

### 2.iv Plotting

Plot the average waveform of all trials:
```matlab
phz_plot(PHZ)
```

Plot only the control group:
```matlab
phz_plot(PHZ, 'subset', {'group', 'control'})
```

Plot only trials with a reaction time less than 10.
```matlab
phz_plot(PHZ, 'subset', PHZ.resp.q1_rt < 10);
```

Plot a separate line for each group:
```matlab
phz_plot(PHZ, 'summary', 'group')
```

Draw a different plot for each trial type, where each plot has a different line
for each group:
```matlab
phz_plot(PHZ, 'summary', {'group', 'trials'})
```

Draw a bar plot of the mean of each epoch instead of the time series data
(includes standard error bars):
```matlab
phz_plot(PHZ, ...
         'summary', {'group', 'trials'}, ...
         'feature', 'mean')
```

Take the mean from a specific time region:
```matlab
% enter the region manually
phz_plot(PHZ, ...
         'summary', {'group', 'trials'}, ...
         'feature', 'mean', ...
         'region',  [0 4])

% use the region fields
PHZ.region.target = [0 4];
phz_plot(PHZ, ...
         'summary', {'group', 'trials'}, ...
         'feature', 'mean', ...
         'region',  'target')
```

See what it would look like with a different rejection threshold:
```matlab
phz_plot(PHZ, ...
         'summary', {'group', 'trials'}, ...
         'feature', 'mean', ...
         'region',  [0 4], ...
         'reject',  0.1)
```

<a name="tutorial-exporting"></a>

### 2.v Exporting

Use the same input argument structure as your call to phz_plot to write those
data to a csv file. Just add a filename argument.
```matlab
phz_writetable(PHZ, ...
               'summary',  {'group', 'trials'}, ...
               'feature',  'mean', ...
               'region',   [0 4], ...
               'filename', 'mydata.csv')
```

<a name="functions"></a>

## 3. Functions
The following is a list of functions included in PHZLAB that can be
included in your scripts. Please refer to the help section of each function
(type `help phz_create` in the command window, or open the file and look
at the first block of comments) for a more detailed description and
examples.

<a name="functions-fileio"></a>

### 3.i File I/O
- `phz_create`: Create a PHZ structure from a data file.
- `phz_combine`: Combine many PHZ structures into a single one.
- `phz_save`: Save a PHZ structure.
- `phz_load`: Load a PHZ structure.
- `phz_field`: Change the values of certain PHZ structure fields.

<a name="functions-processing"></a>

### 3.ii Processing
- `phz_filter`: Butterworth filtering (requires Signal Processing Toolbox).
- `phz_epoch`: Split a single channel of data into trials.
- `phz_labels`: Add names to each trial of epoched data.
- `phz_rectify`: Full- or half-wave rectification.
- `phz_smooth`: Sliding window averaging (incl. RMS)
- `phz_transform`: Transform data (e.g., square root, etc.)
- `phz_reject`: Mark trials with values exceeding a threshold or SD.
- `phz_blsub`: Subtract mean of baseline region from each trial.
- `phz_norm`: Normalize across specified grouping variables.
- `phz_discard`: Remove trials marked by reject, subset, and review.
- `phz_proc`: Apply many processing functions in one step.

<a name="functions-analysis"></a>

### 3.iii Analysis
- `phz_subset`: Mark data only from specified grouping variables.
- `phz_region`: Keep only data from a certain time region.
- `phz_feature`: Convert data to the specified feature.
- `phz_summary`: Average across grouping variables.

<a name="functions-visualization"></a>

### 3.iv Visualization and Export
- `phz_review`: Inspect individual trials.
- `phz_plot`: Visualize data as line or bar graphs.
- `phz_writetable`: Export features as a CSV file (e.g., for R).

<a name="functions-specialty"></a>

### 3.v Specialty Functions
- `phzABR_equalizeTrials`: Equalize the number of trials of each polarity.
- `phzABR_summary`: Add or subtract polarities.
- `phzABR_plot`: Summary plot for ABR data.
- `phz_BTexport`: Export data to [Brainstem Toolbox](http://www.brainvolts.northwestern.edu/).
- `phzBiopac_transform`: Convert data by gain and desired units.
- `phzBiopac_readJournalMarkers`: Read marker times from Biopac AcqKnowledge journal text.
- `phzUtil_findAudioMarkers`: Search for audio onsets in a signal.

<a name="installation"></a>

## 4. Installation

<a name="installation-system-requirements"></a>

### 4.i System Requirements

PHZLAB requires MATLAB to run. Since PHZLAB uses the table and categorical
variable types, it will not run in MATLAB versions prior to R2013b, or in
Octave.

Some PHZLAB functions depend on MATLAB Toolboxes. Details about the dependencies
can be found in the help section of the functions themselves.

- `phzBiopac_readJournalMarkers` requires the **Statistics and Machine Learning
Toolbox**.

- `phz_filter` requires the **Signal Processing Toolbox**.

<a name="installation-git"></a>

### 4.ii Install using git

From a terminal, move to the directory where you want to put
PHZLAB (likely the default MATLAB folder) and clone the git repository there.

```bash
cd ~/Documents/MATLAB
git clone https://github.com/gabenespoli/phzlab
```

This makes it easy to update PHZLAB:

```bash
cd ~/Documents/MATLAB/phzlab
git pull
```

<a name="installation-download"></a>

### 4.iii Install with manual download

Use the download link in the upper-right corner of this
webpage (https://github.com/gabenespoli/phzlab). Unzip the file and put it
somewhere where you can easily add it to your MATLAB path.

<a name="add-to-path"></a>

### 4.iv Add the folder to your MATLAB path

```matlab
addpath('~/Documents/MATLAB/phzlab')
```

<a name="acknowledgements"></a>

## 5. Acknowledgements

I would like to thank the [SMART Lab](http://www.smartlaboratory.org/)
(especially [Frank Russo](http://smartlaboratory.org/portfolio/frankrusso/),
[Ella Dubinsky](http://smartlaboratory.org/portfolio/ella-dubinsky/),
and [Fran Copelli](http://smartlaboratory.org/portfolio/fran-copelli/)),
[Alex Andrews](http://www.tenkettles.com/), and
[Carson Pun](https://www.ryerson.ca/psychology/about-us/our-people/administrative-staff/carson-pun/)
for their invaluable thoughts, suggestions, inspiration, and feedback on the
many versions of PHZLAB that it took to get here.

This toolbox contains an adapted version of [sigstar](https://github.com/raacampbell/sigstar).

<a name="license"></a>

## 6. License

This software is covered by the GNU General Public Licence v3.

