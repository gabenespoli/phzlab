%PHZ_TRANSFORM  Apply a transformation to the data.
%
% USAGE
%   PHZ = phz_transform(PHZ,transform)
%   PHZ = phz_transform(PHZ,transform,units)
% 
% INPUT
%   PHZ       = PHZLAB data structure.
% 
%   transform = [string|numeric] Type of transformation to apply to the 
%               data. See below for a list of possible transformations.
% 
%       'sqrt'    = Take square root of every data point.
%                   Data cannot be negative.
%       '^2'      = Square every data point.
%       'log'     = Natural logarithm.
%       'log10'   = Base 10 logarithm.
%       'log2'    = Base 2 logarithm.
%       [numeric] = Multiply each data point by this number.
% 
%   units     = Optionally specifies new units for PHZ.units. Enter empty
%               ([] or '') to erase the current units, or a boolean false
%               to leave them as they are.
% 
% OUTPUT
%   PHZ.data  = The transformed data.
%   PHZ.units = Optionally the value in units.

% Copyright (C) 2016 Gabriel A. Nespoli, gabenespoli@gmail.com
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

function PHZ = phz_transform(PHZ,transform,units,verbose)

if nargout == 0 && nargin == 0, help phz_transform, return, end
if isempty(transform), return, end

% parse input
if nargin < 3, units = ''; end
if nargin < 4, verbose = true; end
if ~iscell(transform), transform = {transform}; end
if ismember('rej',fieldnames(PHZ)), do_rej = true; else do_rej = false; end

for i = 1:length(transform)
    
    % apply transformation
    if isnumeric(transform{i})
        transformStr = ['Multiplied by ',num2str(transform{i}),'.'];
        PHZ.data = PHZ.data * transform{i};
        if do_rej, PHZ.proc.rej.data = PHZ.proc.rej.data * transform{i}; end
        
    else
        switch lower(transform{i})
                
            case {'sqrt','squareroot'}
                if any(PHZ.data < 0)
                    error(['Some data are less than zero. ',...
                        'A square root transformation cannot be applied.'])
                end
                transformStr = 'Square root transformation.';
                PHZ.data = sqrt(PHZ.data);
                if do_rej, PHZ.proc.rej.data = sqrt(PHZ.proc.rej.data); end
                
            case {'^2','square'}
                transformStr = 'Squared each data point.';
                PHZ.data = PHZ.data .^ 2;
                if do_rej, PHZ.proc.rej.data = PHZ.proc.rej.data .^ 2; end
                
            case 'log'
                if any(PHZ.data < 0), error('Cannot compute logarithm of negative values.'), end
                transformStr = 'Natural logarithm transformation.';
                PHZ.data = log(PHZ.data);
                if do_rej, PHZ.proc.rej.data = log(PHZ.proc.rej.data); end
                
            case 'log10'
                if any(PHZ.data < 0), error('Cannot compute logarithm of negative values.'), end
                transformStr = 'Base 10 logarithm transformation.';
                PHZ.data = log10(PHZ.data);
                if do_rej, PHZ.proc.rej.data = log10(PHZ.proc.rej.data); end
                
            case 'log2'
                if any(PHZ.data < 0), error('Cannot compute logarithm of negative values.'), end
                transformStr = 'Base 2 logarithm transformation.';
                PHZ.data = log2(PHZ.data);
                if do_rej, PHZ.proc.rej.data = log2(PHZ.proc.rej.data); end
                
            otherwise, error('Unknown transformation.')
        end
    end
    
    PHZ = phz_history(PHZ,transformStr,verbose);
end

if isempty(units)
    PHZ.proc.transform = transform;
else
    PHZ.proc.transform.transform = transform;
    PHZ.proc.transform.oldUnits = PHZ.units;
    PHZ.units = units;
end
end