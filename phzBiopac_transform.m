%PHZBIOPAC_TRANSFORM  Use gain setting to transform data. This function
%   assumes that Biopac data is output in the range -10 to 10 Volts, and
%   scales the data according to the gain and the desired output units
%   (e.g., microvolts).
%
% USAGE
%   PHZ = phzBiopac_transform(PHZ, gain)
%   PHZ = phzBiopac_transform(PHZ, gain, units)
%
% INPUT
%   PHZ   = [struct] PHZLAB data structure.
%   gain  = [numeric] Gain value from the Biopac amplifier.
%   units = [string] Desired units to convert to. Possible values:
%           'tera'  or 'T'
%           'giga'  or 'G'
%           'mega'  or 'M'
%           'kilo'  or 'k'
%           'hecto' or 'h'
%           'deca'  or 'da'
%           '' (empty; default)
%           'deci'  or 'd'
%           'centi' or 'c'
%           'milli' or 'm'
%           'micro' or 'u'
%           'nano'  or 'n'
%           'pico'  or 'p'
%
% OUTPUT
%   PHZ.data is multiplied by the appropriate factor for the desired units.
%   PHZ.units is prepended with the value in units.
%
% EXAMPLES
%    >> PHZ = phzBiopac_transform(PHZ, 10000)
%       PHZ.data will be divided by 10 to put the output on a -1:1 range,
%       then divided by 10000 to correct for the gain value.
%
%    >> PHZ = phzBiopac_transform(PHZ, 10000, 'u')
%       PHZ.data will additionally be multiplied by 1000000 to convert
%       values to micro (e.g., if PHZ.units was 'Volts', units will now
%       be 'uVolts').
%
% REFERENCE
%   https://www.biopac.com/knowledge-base/calibration-in-volts-millivolts-microvolts/

function PHZ = phzBiopac_transform(PHZ, gain, units, verbose)

if nargin == 0 && nargout == 0, help phzBiopac_transform, end
if nargin < 2, error('Gain must be specified.'), end
if nargin < 3 || isempty(units), units = ''; end
if nargin < 4, verbose = true; end

switch units
    case {'tera',  'T'},    unitsGain = 10e-12;
    case {'giga',  'G'},    unitsGain = 10e-9;
    case {'mega',  'M'},    unitsGain = 10e-6;
    case {'kilo',  'k'},    unitsGain = 10e-3;
    case {'hecto', 'h'},    unitsGain = 10e-2;
    case {'deca',  'da'},   unitsGain = 10e-1;
    case {''},              unitsGain = 1;
    case {'deci',  'd'},    unitsGain = 10e1;
    case {'centi', 'c'},    unitsGain = 10e2;
    case {'milli', 'm'},    unitsGain = 10e3;
    case {'micro', 'u'},    unitsGain = 10e6;
    case {'nano',  'n'},    unitsGain = 10e9;
    case {'pico',  'p'},    unitsGain = 10e12;
    otherwise,              error('Invalid units.')
end

% - divide data by the amplifier gain to get volts on a -10:10 scale
% - dived data by 10 to get back to get volts on a -1:1 scale
% - multiply by the units factor to get desired units
multiplier = unitsGain / gain / 10;
units = [units, PHZ.units];

PHZ = phz_transform(PHZ, {multiplier, units}, verbose);

end
