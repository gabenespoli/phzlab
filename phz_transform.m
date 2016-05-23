%PHZ_TRANSFORM  Apply a transformation to the data.
%
% USAGE
%   PHZ = phz_transform(PHZ,transform)
% 
% INPUT
%   PHZ       = PHZLAB data structure.
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
% OUTPUT
%   PHZ.data  = The transformed data.
%
% Written by Gabriel A. Nespoli 2016-03-26. Revised 2016-04-04.

function PHZ = phz_transform(PHZ,transform,verbose)

if nargout == 0 && nargin == 0, help phz_transform, return, end
if isempty(transform), return, end

% parse input
if nargin < 3, verbose = true; end
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

PHZ.proc.transform = transform;
end