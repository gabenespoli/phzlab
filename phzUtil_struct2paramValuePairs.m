function C = phzUtil_struct2paramValuePairs(S)
% convert a struct S to a cell of parameter-value pairs C.
% e.g., the struct
%       S.name = 'Gabe'
%       S.id = 3
% becomes
%       C = {'name', 'Gabe', 'id', 3}

if ~isstruct(S)
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
