# PHZLAB Example Scripts

This folder contains example scripts that call PHZLAB functions, for
different kinds of analyses. They are not intended to be used as-is,
but rather to serve as a template to be customized for your
particular analysis.

## phzExample_loop.m

This script can be used to loop through raw data files and save them as
PHZ files. Then, using phz_combine.m, these PHZ files can be combined
into a single PHZ file, so that analyses and plotting can be done using
the entire data set at once. If the data set is particularly large (as
is the case with ABR data), some preprocessing and trial averaging must
be done before files can be combined. See phz_combine.m and
phzExample_ABR_combine.m for more information.

## phzExample_ABR_create.m

A sample script for processing ABR data using PHZLAB. It can be used
on its own to process a single file, or called from another script
that is looping many files. This function does not label metadata such
as participant, group, session, and condition. If a stimulus waveform 
is given it will attempt to auto-label trials with the appropriate
polarity. Otherwise, these fields should be set manually or in your
looping script.

Recording setup:
This script is based on using data that was recorded using the Biopac
system and AcqKnowledge software. The ABR was recorded onto channel 1,
and the audio stimulus was recorded onto channel 2 via the analog
inputs on the Biopac MP150. For epoching, this stimulus recording is
used to determine the locations of each epoch. PHZLAB provides a
function (phzUtil_findAudioMarkers.m) for this purpose using a
threshold method. If the stimulus waveform is also provided, PHZLAB
can adjust the marker times to be more precise using a cross-
correlation. This also allows PHZLAB to automatically label each epoch
as 'regular' or 'inverted'.
