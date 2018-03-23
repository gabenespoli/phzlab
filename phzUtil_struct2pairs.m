function C = phzUtil_struct2pairs(S)
% Convert a struct S to a cell of parameter-value pairs C.
% If the input is already an even-length cell vector, it is just returned.
% e.g., the struct
%       S.name = 'Gabe'
%       S.id = 3
% becomes
%       C = {'name', 'Gabe', 'id', 3}

if iscell(S) && isvector(S)
    if mod(length(S), 2) == 0
        C = S;
        return
    else
        error('There are an odd number arguments in parameter-value pairs')
    end

elseif ~isstruct(S)
    error('Input must be a struct.')

end

names = fieldnames(S);
C = cell(1, length(names) * 2);

for i = 1:length(names)
    ind = 1 + (i - 1) * 2;
    C{ind}   = names{i}; % param
    C{ind+1} = S.(names{i}); % value
end

end
