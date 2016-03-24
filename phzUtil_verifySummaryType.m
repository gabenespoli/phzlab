function keepVars = phzUtil_verifySummaryType(keepVars)

if nargout == 0 && nargin == 0, help phzUtil_verifySummaryType, end

if ~iscell(keepVars), keepVars = {keepVars}; end

if ~isempty(keepVars)
    
    if ~all(ismember(keepVars,{'trials','session','group','participant','all','',' ','none'}))
        error('Invalid summaryType.')
    end
    
    if any(ismember({'all','',' ','none'},keepVars)) && length(keepVars) > 1
        error('A value in summaryType must be used on its own, but is being used with other summaryTypes.')
    end
    
    if ismember(keepVars{1},{' '}) || isempty(keepVars{1})
        keepVars = {'none'};
    end
    
end
end