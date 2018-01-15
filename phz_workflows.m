function phz_workflows(datatype)
%PHZ_WORKFLOW  Display sample workflows for a specific type of data.
% 
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

if nargin == 0 && nargout == 0; help phz_workflow, return, end

if isstruct(datatype) && strcmp('datatype',fieldnames(datatype))
    datatype = datatype.datatype;
end
disp(' ')
switch lower(datatype)
    case {'scl','scr','gsr','gsl'}
        disp('phz_transform(PHZ,''log''): reduce skew and kurtosis of SCL data (Venables & Christie (1980).')
        
        disp('Tierney Lindsay et al. 2011: blc, norm')
        
        
    case {'emg','zyg','cor'}
        
        disp('SAMPLE EMG WORKFLOW')
        disp('-------------------')
        disp('1. Rectify: usually full-wave.')
        disp('2. Smooth: either sliding average, RMS, or lowpass 5-100 Hz.')
        disp('3. Reject: reject unusual data by threshold.')
        disp('4. Transform: square root transformation to minimize positive skew.')
        disp('5. Baseline-correct: ')
        disp('6. Normalize: minimize inter-participant variability in responsiveness.')
        
%         disp('opt 1a. rm mean, rectify, lowpass 5-100 Hz, then mean value.')
%         disp('opt 1b. rm mean, rectify, sliding window average, then mean value.')
%         disp('opt 2.  rm mean, sliding window RMS, then mean value.')
%         
%         disp(' ')
%         
%         disp('Likowski et al. 2012: rectify, filter [30 500 50], 125ms moving avg, rej 8µV baseline or 30µV target')
%         disp('Tierney Lindsay et al. 2011: rectify, smooth(?), blc, norm')
%         disp('so... rectify, filter, smooth, rej, blc, norm')
%         
%         disp(' ')
%         
%         disp('phz_filter:    HP 10-50; LP 400-500')
%         disp('phz_rect:      full or half wave rectification')
%         disp('phz_rej:       artifact rejection')
%         disp('phz_transform: square root transformation to minimize positive skew')
%         disp('phz_norm:      minimize inter-participant variability in responsiveness')
        
    
        
%         I can think of at least two reasons for the popularity of RMS methods of analysis: 1. if the signal values are normal random deviates, then the RMS approach can be shown to be an optimal method for estimating the standard deviation of the underlying normal distribution. 2. If the signal were a voltage applied across a resistor, the mean square method correctly predicts the power (heat) that will be dissipated in the resistor - which has an intuitive appeal as a measure of "strength of signal".
% A reason to be wary of the RMS method is that if the signal values are NOT normally distributed, particularly if outliers occur more often than predicted by the normal distribution (which, by the way, seems to be the case in many laboratory measurements), then the RMS method is liable to make significant estimation errors. Mean- of-the-absolute-value methods are not as sensitive to outliers, and are less likely to make big errors when the data is non-normal. Median-based methods are even more robust, but I have not seen them used in EMG analysis.
    
end

disp(' ')
end
