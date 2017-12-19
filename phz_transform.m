%PHZ_TRANSFORM  Apply a transformation to the data.
%
% USAGE
%   PHZ = phz_transform(PHZ,transform)
%
% INPUT
%   PHZ       = PHZLAB data structure.
%
%   transform = [string|numeric|cell] Type of transformation to apply to the
%               data. See below for a list of possible transformations. If
%               a cell, the first element is the transformation to apply,
%               and the second element is a string with the new units.
%
%       'sqrt'    = Take square root of every data point.
%                   Data cannot be negative.
%       '^2'      = Square every data point.
%       'log'     = Natural logarithm.
%       'log10'   = Base 10 logarithm.
%       'log2'    = Base 2 logarithm.
%       [numeric] = Multiply each data point by this number.
%
% OUTPUT
%   PHZ.data  = The transformed data.
%   PHZ.proc.transform.transform = The transformation(s) performed.
%   PHZ.proc.transform.

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

function PHZ = phz_transform(PHZ,transform,verbose)

if nargout == 0 && nargin == 0, help phz_transform, return, end
if isempty(transform), return, end

% parse input
if nargin < 3
    verbose = true; end

if ~iscell(transform)
    transform = {transform}; end

newUnits = false;
if length(transform) > 1
    if ischar(transform{2})
        PHZ.units = transform{2};
        newUnits = true;
    else
        warning('New units must be a string. Ignoring new units.')
    end
end

if length(transform) > 2
    warning('Transform cell array has length > 2. Only using first 2 elements.')
end

% apply transformation
if isnumeric(transform{1})
    
    transformStr = ['Multiplied by ',num2str(transform{1}),'.'];
    PHZ.data = PHZ.data * transform{1};
    
else
    
    switch lower(transform{1})
        
        case {'sqrt','squareroot'}
            if any(PHZ.data < 0)
                error('Cannot compute square root of negative values.'), end
            transformStr = 'Square root transformation.';
            PHZ.data = sqrt(PHZ.data);
            
        case {'^2','square'}
            transformStr = 'Squared each data point.';
            PHZ.data = PHZ.data .^ 2;
            
        case 'log'
            if any(PHZ.data < 0)
                error('Cannot compute logarithm of negative values.'), end
            transformStr = 'Natural logarithm transformation.';
            PHZ.data = log(PHZ.data);
            
        case 'log10'
            if any(PHZ.data < 0)
                error('Cannot compute logarithm of negative values.'), end
            transformStr = 'Base 10 logarithm transformation.';
            PHZ.data = log10(PHZ.data);
            
        case 'log2'
            if any(PHZ.data < 0)
                error('Cannot compute logarithm of negative values.'), end
            transformStr = 'Base 2 logarithm transformation.';
            PHZ.data = log2(PHZ.data);
            
        otherwise, error('Unknown transformation.')
    end
end

if newUnits
    transformStr = [transformStr, ' Changed units to ', PHZ.units, '.'];
end
PHZ = phz_history(PHZ,transformStr,verbose);
procName = phzUtil_getUniqueProcName(PHZ,'transform');
PHZ.proc.(procName) = transform;

end
