function PHZ = phz_field(PHZ,field,verbose)
%PHZ_FIELD  Change the value and/or order of fields in a PHZ structure.
%   PHZ_FIELD opens a dialog with current values of the PHZ structure that
%   can be edited.
% 
% usage:    PHZ = phz_field(PHZ)
%           PHZ = phz_field(PHZ,FIELD)
% 
% inputs:   PHZ   = PHZLAB data structure.
%           FIELD = String specifying the type of fields to change. Options
%                   are 'basic' (default), 'region'.
% 
% outputs:  PHZ = PHZLAB data structure with fields adjusted.
% 
% Written by Gabriel A. Nespoli 2016-03-24. Revised 2016-04-12.
if nargin == 0 && nargout == 0, hel phz_field, return, end
if nargin < 2, field = 'basic'; end
if nargin < 3, verbose = true; end

% prompt for changes and apply changes
dlg_title = 'Change PHZ fields';
numlines = 1;

switch lower(field)
        
    case 'basic'
        prompt = {'study',...
            'datatype',...
            'units',...
            'participant',...
            'participant spec',...
            'group',...
            'group spec',...
            'session',...
            'session spec',...
            'trials',...
            'trials spec'};
        %     'srate'}; % if srate changes, times needs to change too
        
        % gather current values of fields
        old = cell(size(prompt));
        for i = 1:length(prompt)
            if strfind(prompt{i},'spec')
                old{i} = cellstr(PHZ.meta.spec.(prompt{i}(1:end-5)));
            else
                old{i} = cellstr(PHZ.(prompt{i}));
            end
            old{i} = strjoin(old{i});
        end
        
        % ask user for new values
        new = inputdlg(prompt,dlg_title,numlines,old,'on');
        
        % if new value, adjust
        for i = 1:length(new)
            if ~strcmp(new{i},old{i})
                if ismember(prompt{i},{'study','datatype','units'})
                    PHZ.(prompt{i}) = new{i};
                elseif strfind(prompt{i},'spec')
                    PHZ.meta.spec.(prompt{i}(1:end-5)) = regexp(new{i},' ','split');
                else
                    PHZ.(prompt{i}) = regexp(new{i},' ','split');
                end

                PHZ = phz_history(PHZ,['Changed ',prompt{i},...
                    ' from ''',old{i},''' to ''',new{i},'''.'],verbose);
            end
        end
        
    case {'region','regions'}
        % have region order at top
        % then have two columns, one for names, one for endpoints
        
        
        prompt = PHZ.meta.tags.region;
        
        old = cell(size(prompt));
        for i = 1:length(old)
            old{i} = num2str(PHZ.region.(prompt{i}));
        end
        
        new = inputdlg(prompt,dlg_title,numlines,old,'on');
        
        for i = 1:length(new)
            if ~strcmp(new{i},old{i})
                PHZ.region.(prompt{i}) = eval(new{i});
                
                PHZ = phz_history(PHZ,['Changed ',prompt{i},' region',...
                    ' from [',old{i},'] to [',new{i},'].'],verbose);
            end
        end
end

end