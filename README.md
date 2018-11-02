<a name="phzlab"></a>

# PHZLAB: A MATLAB toolbox for analyzing physiological data.

![PHZLAB Logo](img/phzlab_logo.png)

PHZLAB is a MATLAB Toolbox for analyzing physiological data, both peripheral
(e.g., EDA, EMG) and neural (i.e., ABR). Really, it is good for any
multiple-trial time-series data. It has been designed with the following goals
in mind:

- make it easy and fast to try different analyses
- easy presentation-ready figures and stats-ready data frames
- be simple enough to act as an introduction to MATLAB
- be hackable enough so as not to be a hindrance, while still adding value

## Documentation

See the [wiki](https://github.com/gabenespoli/phzlab/wiki) for a [quickstart](https://github.com/gabenespoli/phzlab/wiki/Quickstart) guide, example pipeline scripts, and other reference guides.

## Installation

### System Requirements

PHZLAB requires MATLAB to run. Since PHZLAB uses the table and categorical
variable types, it will only run on MATLAB versions R2014a and later. Also for
this reason, it won't run in Octave.

Some PHZLAB functions depend on MATLAB Toolboxes. Details about the
dependencies can be found in the help section of the functions themselves.

- `phzBiopac_readJournalMarkers` requires the **Statistics and Machine Learning
  Toolbox**.

- `phz_filter` requires the **Signal Processing Toolbox**.

### Download

**Manual download.** Use the download link in the upper-right corner of this
webpage (https://github.com/gabenespoli/phzlab). Unzip the file and put it
somewhere where you can easily add it to your MATLAB path.

**Install using git.** From a terminal, move to the directory where you want to
put PHZLAB (likely the default MATLAB folder) and clone the git repository
there. You may need to install git first (e.g., on a Mac you'll need the XCode
Command Line Tools, which you can obtain by running `xcode-select install` in a
terminal).

```bash
cd ~/Documents/MATLAB
git clone https://github.com/gabenespoli/phzlab
```

This makes it easy to update PHZLAB:

```bash
cd ~/Documents/MATLAB/phzlab
git pull
```

### Add the folder to your MATLAB path

Use the MATLAB menu to add the phzlab folder to your path, or type the following in the command window or your scripts:

```matlab
addpath('~/Documents/MATLAB/phzlab')
```

## Acknowledgements

I would like to thank the [SMART Lab](http://www.smartlaboratory.org/)
(especially [Frank Russo](http://smartlaboratory.org/portfolio/frankrusso/),
[Ella Dubinsky](http://smartlaboratory.org/portfolio/ella-dubinsky/), and [Fran
Copelli](http://smartlaboratory.org/portfolio/fran-copelli/)), [Alex
Andrews](http://www.tenkettles.com/), and [Carson
Pun](https://www.ryerson.ca/psychology/about-us/our-people/administrative-staff/carson-pun/)
for their invaluable thoughts, suggestions, inspiration, and feedback.

PHZLAB contains an adapted version of
[sigstar](https://github.com/raacampbell/sigstar).

## License

This software is covered by the GNU General Public Licence v3.

