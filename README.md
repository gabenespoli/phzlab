# PHZLAB: A MATLAB toolbox for analysis of physiological data.

![PHZLAB Logo](img/phzlab_logo.png)

PHZLAB is a MATLAB Toolbox for analyzing physiological data, both
peripheral (e.g., SCL, EMG) and neural (e.g., ABR, FFR).

## Table of Contents

1. [How it works](#how-it-works)
2. [Tutorial](#tutorial)
    1. [Loading data](#tutorial-loading)
    2. [Preprocessing](#tutorial-preprocessing)
    3. [Combine many PHZ files into one](#tutorial-combining)
    4. [Plotting](#tutorial-plotting)
    5. [Exporting](#tutorial-exporting)
3. [Installation](#installation)
    1. [Git](#installation-git)
    2. [Manual download](#installation-download)
    3. [Add PHZLAB to the MATLAB path](#add-to-path)
4. [List of Functions](#functions)
    1. [File I/O](#functions-fileio)
    2. [Processing](#functions-processing)
    3. [Analysis](#functions-analysis)
    4. [Visualization and Export](#functions-visualization)
    5. [Specialty Functions](#functions-specialty)
5. [Acknowledgements](#acknowledgements)
6. [License](#license)

<a name="how-it-works"></a>

## How it works
PHZLAB is inspired by [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php), 
and borrows the idea of a having a single variable (a struct called PHZ)
to hold data and metadata for a given file or files. All functions operate
on this PHZ variable, keeping a log of processing (PHZ.history), as well
as the PHZLAB settings required to reproduce all processing (PHZ.proc).
There is no GUI (graphical user interface) for PHZLAB, only a set of
functions that can be called from the command window or incorporated into
your own scripts. Once processed, data can be exported for statistical
analysis, and publication-ready plots can be easily produced.

See the examples folder for template scripts that you can use.

<a name="tutorial"></a>

## Tutorial

<a name="tutorial-loading"></a>

### Loading data

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
read the sampling rate, datatype, and units. These can be overridden though:
```matlab
PHZ = phz_create( ...
    'filename',     'my_biopac_data.mat', ...
    'filetype',     'acq', ...
    'channel',      4, ...
    'datatype',     'EMG', ...
    'units',        'V');
```

Change the units to millivolts, and add a high-pass filter and a notch filter
to remove line noise. If these are Biopac data, you can use the special
Biopac transform function to account for this when converting the units:
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
around each start time to extract. All epochs must be the same length.
```matlab
% times is a vector of start times in samples
PHZ = phz_epoch(PHZ, times, [-1 5]);

% labels is a cell array of labels for each trial
PHZ = phz_labels(PHZ, labels);
```

Save this file to disk:
```matlab
phz_save(PHZ, 'phzfiles/datafile1.phz');
```

<a name="tutorial-preprocessing"></a>

### Preprocessing

Subtract the mean of a baseline period from each epoch.
```matlab
PHZ = phz_blsub(PHZ, [-1 0]);
```

Mark trials for rejection that contain values above a threshold.
```matlab
PHZ = phz_reject(PHZ, 0.05);
```

<a name="tutorial-combining"></a>

### Combine many PHZ files into one

PHZLAB can combine all .phz files in a given folder into a single PHZ variable.
This lets you apply processing functions to the whole dataset at once, and
means we can make plots that include all data very quickly.
```matlab
PHZ = phz_combine('phzfiles');
```

If there is too much data to put into a single file, PHZLAB will throw an error
and suggest that you do some preprocessing (including averaging, e.g., by using
`phz_summary`) before combining the files. This can be done right from the call
to `phz_combine`. Note that you won't be able to change this processing later
without re-combining the files with different settings:
```matlab
PHZ = phz_combine('phzfiles', ...
                  'blsub',    [-1 0], ...
                  'reject',   0.05, ...
                  'summary',  {'participant', 'group', 'trials'});
```

<a name="tutorial-preprocessing"></a>

### Plotting

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
phz_plot(PHZ, 'summary', {'group', 'trials'}, 'feature', 'mean')
```

See what it would look like with a different rejection threshold:
```matlab
phz_plot(PHZ, 'summary', {'group', 'trials'}, 'feature', 'mean', 'reject', 0.1)
```

<a name="tutorial-exporting"></a>

### Exporting

Use the same input argument structure as your call to phz_plot to write those
data to a csv file. Just add a filename argument.
```matlab
phz_writetable(PHZ, 'summary', {'group', 'trials'}, 'feature', 'mean', ...
               'filename', 'mydata.csv')
```

<a name="installation"></a>

## Installation

<a name="installation-git"></a>

### Using git

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

### Manual download

Use the download link in the upper-right corner of this
webpage (https://github.com/gabenespoli/phzlab). Unzip the file and put it
somewhere where you can easily add it to your MATLAB path.

<a name="add-to-path"></a>

### Add the folder to your MATLAB path

```matlab
addpath('~/Documents/MATLAB/phzlab')
```

<a name="functions"></a>

## Functions
The following is a list of functions included in PHZLAB that can be
included in your scripts. Please refer to the help section of each function
(type `help phz_create` in the command window, or open the file and look
at the first block of comments) for a more detailed description and
examples.

<a name="functions-fileio"></a>

### File I/O
- `phz_create`: Create a PHZ structure from a data file.
- `phz_combine`: Combine many PHZ structures into a single one.
- `phz_save`: Save a PHZ structure.
- `phz_load`: Load a PHZ structure.
- `phz_field`: Change the values of certain PHZ structure fields.

<a name="functions-processing"></a>

### Processing
- `phz_filter`: Butterworth filtering (requires Signal Processing Toolbox).
- `phz_epoch`: Split a single channel of data into trials.
- `phz_labels`: Add names to each trial of epoched data.
- `phz_rectify`: Full- or half-wave rectification.
- `phz_smooth`: Sliding window averaging (incl. RMS)
- `phz_transform`: Transform data (e.g., square root, etc.)
- `phz_reject`: Mark trials with values exceeding a threshold or SD.
- `phz_blsub`: Subtract mean of baseline region from each trial.
- `phz_norm`: Normalize across specified grouping variables.
- `phz_dicard`: Remove trials marked by reject, subset, and review.
- `phz_proc`: Apply many processing functions in one step.

<a name="functions-analysis"></a>

### Analysis
- `phz_subset`: Mark data only from specified grouping variables.
- `phz_region`: Keep only data from a certain time region.
- `phz_feature`: Convert data to the specified feature.
- `phz_summary`: Average across grouping variables.

<a name="functions-visualization"></a>

### Visualization and Export
- `phz_review`: Inspect individual trials.
- `phz_plot`: Visualize data as line or bar graphs.
- `phz_writetable`: Export features as a CSV file (e.g., for R).

<a name="functions-specialty"></a>

### Specialty Functions
- `phzABR_equalizeTrials`: Equalize the number of trials of each polarity.
- `phzABR_summary`: Add or subtract polarities.
- `phzABR_plot`: Summary plot for ABR data (coming soon).
- `phz_BTexport`: Export data to [Brainstem Toolbox](http://www.brainvolts.northwestern.edu/) (coming soon).
- `phzBiopac_transform`: Convert data by gain and desired units.
- `phzBiopac_readJournalMarkers`: Read marker times from Biopac AcqKnowledge journal text.
- `phzUtil_findAudioMarkers`: Search for audio onsets in a signal.

<a name="acknowledgements"></a>

## Acknowledgements

<a name="license"></a>

## License
This software is covered by the GNU General Public Licence v3.

