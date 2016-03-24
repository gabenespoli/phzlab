function val = phzUtil_isphzs(PHZ)
%PHZUTIL_ISPHZS  Check if PHZ or PHZS structure.
% VAL = PHZUTIL_ISPHZS(PHZ) returns logical true for a PHZS structure,
%   false for a PHZ strucutre, and throws an error if input is neither a
%   PHZ or PHZS structure.
% 
% Written by Gabriel A. Nespoli 2016-02-22. Revised 2016-03-17.

% if participant is char, this is a PHZ
% if ischar(PHZ.participant)
%     val = false;
%     
%     
% elseif iscategorical(PHZ.participant)
%     
%     % if participant is categorial and more than one category, PHZS
%     if length(unique(PHZ.participant)) > 1
%         val = true;
%         
%         % else one category, PHZ
%     else val = false;
%     end
%     
% else error('Input is not a valid PHZ structure.')    
% end

if nargout == 0 && nargin == 0, help phzUtil_isphzs, end

switch PHZ.history{1}(37:40)
    case 'PHZ ', val = false;
    case 'PHZS'
        if length(unique(cellstr(PHZ.participant))) > 1, val = true;
        else val = false;
        end
    otherwise, error('Input is not a PHZ structure.')
end
end