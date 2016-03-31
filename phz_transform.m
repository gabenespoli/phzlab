function PHZ = phz_transform(PHZ,transform,varargin)
%PHZ_TRANSFORM  Apply a transformation to the data.
%
% PHZ = PHZ_TRANSFORM(PHZ,TRANSFORM) applies the transformation TRANSFORM
%   to all data points in PHZ.data. TRANSFORM can be a string or a cell
%   array of strings. If trials have been rejected with PHZ_REJ, the
%   transformation is also applied to rejected trials. Possible
%   transformations are:
%
%   'full', 'abs' = Full-wave rectification. This function takes the
%                   absolute value of each data point.
%   'half'        = Half-wave rectification. This function sets all
%                   negative data points to zero.
%   'sqrt'        = Take square root of every data point. Data cannot be
%                   negative.
%   '^2'          = Square every data point.
%   'log'         = Natural logarithm.
%   'log10'       = Base 10 logarithm.
%   'log2'        = Base 2 logarithm.
%   [numeric]     = Multiply each data point by this number.
%
%
% Written by Gabriel A. Nespoli 2016-03-26. Revised 2016-03-29.
if nargout == 0 && nargin == 0, help phz_transform, return, end
if isempty(transform), return, end

% parse input
if nargin > 2, verbose = varargin{1}; else verbose = true; end
if ~iscell(transform), transform = {transform}; end
if ismember('rej',fieldnames(PHZ)), do_rej = true; else do_rej = false; end


for i = 1:length(transform)
    
    % apply transformation
    if isnumeric(transform{i})
        transformStr = ['Multiplied by ',num2str(transform{i}),'.'];
        PHZ.data = PHZ.data * transform{i};
        if do_rej, PHZ.rej.data = PHZ.rej.data * transform{i}; end
        
    else
        switch lower(transform{i})
            case {'full','abs'}
                transformStr = 'Full-wave rectification.';
                PHZ.data = abs(PHZ.data);
                if do_rej, PHZ.rej.data = abs(PHZ.rej.data); end
                
            case {'half','truncate','trunc'}
                transformStr = 'Half-wave rectification.';
                PHZ.data(PHZ.data < 0) = 0;
                if do_rej, PHZ.rej.data(PHZ.rej.data < 0) = 0; end
                
            case {'sqrt','squareroot'}
                if any(PHZ.data < 0)
                    error(['Some data are less than zero. ',...
                        'A square root transformation cannot be applied.'])
                end
                transformStr = 'Square root transformation.';
                PHZ.data = sqrt(PHZ.data);
                if do_rej, PHZ.rej.data = sqrt(PHZ.rej.data); end
                
            case {'^2','square'}
                transformStr = 'Squared each data point.';
                PHZ.data = PHZ.data .^ 2;
                if do_rej, PHZ.rej.data = PHZ.rej.data .^ 2; end
                
            case 'log'
                if any(PHZ.data < 0), error('Cannot compute logarithm of negative values.'), end
                transformStr = 'Natural logarithm transformation.';
                PHZ.data = log(PHZ.data);
                
            case 'log10'
                if any(PHZ.data < 0), error('Cannot compute logarithm of negative values.'), end
                transformStr = 'Base 10 logarithm transformation.';
                PHZ.data = log10(PHZ.data);
                
            case 'log2'
                if any(PHZ.data < 0), error('Cannot compute logarithm of negative values.'), end
                transformStr = 'Base 2 logarithm transformation.';
                PHZ.data = log2(PHZ.data);
                
            otherwise, error('Unknown transformation.')
        end
    end
    PHZ = phzUtil_history(PHZ,transformStr,verbose);

end

end