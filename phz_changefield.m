function PHZ = phz_changefield(PHZ,varargin)
%PHZ_CHANGEFIELD  Change the value of fields in a PHZ structure.
% 
% PHZ = PHZ_CHANGEFIELD(PHZ,FIELDTYPE) opens a dialog box to change the 
%   fields of a PHZ structure. FIELDTYPE is a string specifying which
%   fields to change: 'basic' (or not specifying a FIELDTYPE) edits the 
%   study name, grouping variables, and units; 'region' edits the time
%   regions in PHZ.region; 'order' edits the orders and spec in PHZ.spec.
% 
% Written by Gabriel A. Nespoli 2016-03-24. Revised 2016-03-26.

% defaults
fieldtype = 'basic';
verbose = true;

% user-defined
for i = 1:length(varargin)
    if isnumeric(varargin{i}), verbose = varargin{i};
    elseif ischar(varargin{i}), fieldtype = varargin{i};
    end
end

% prompt for changes and apply changes
dlg_title = 'Change PHZ fields';
numlines = 1;

switch lower(fieldtype)
    
    case {'spec','colour','colours','color','colors','linespec'}
        prompt = fieldnames(PHZ.spec);
        old = cell(size(prompt));
        for i = 1:length(old)
            old{i} = strjoin(PHZ.spec.(prompt{i}));
        end
        
        new = inputdlg(prompt,dlg_title,numlines,old);
        
        for i = 1:length(new)
            if ~strcmp(new{i},old{i})
                PHZ.spec.(prompt{i}) = regexp(new{i},' ','split');
                PHZ = phzUtil_history(PHZ,['Changed ',prompt{i},...
                    ' from ''',old{i},''' to ''',new{i},'''.'],verbose);
            end
        end
        
    case 'basic'
        prompt = {'study',...
            'datatype',...
            'participant',...
            'group',...
            'session',...
            'units'};
        %     'srate'}; % if srate changes, times needs to change too
        
        % gather current values of fields
        old = cell(size(prompt));
        for i = 1:length(prompt)
            old{i} = cellstr(PHZ.(prompt{i}));
            old{i} = old{i}{1};
        end
        
        new = inputdlg(prompt,dlg_title,numlines,old);
        
        % if new value, adjust
        for i = 1:length(new)
            if ~strcmp(new{i},old{i})
                PHZ.(prompt{i}) = new{i};
                PHZ = phzUtil_history(PHZ,['Changed ',prompt{i},...
                    ' from ''',old{i},''' to ''',new{i},'''.'],verbose);
            end
        end
        
    case {'region','regions'}
        % have region order at top
        % then have two columns, one for names, one for endpoints
        
        
        prompt = PHZ.spec.region_order;
        
        old = {num2str(PHZ.region.(PHZ.spec.region_order{1})),...
            num2str(PHZ.region.(PHZ.spec.region_order{2})),...
            num2str(PHZ.region.(PHZ.spec.region_order{3})),...
            num2str(PHZ.region.(PHZ.spec.region_order{4})),...
            num2str(PHZ.region.(PHZ.spec.region_order{5}))};
        
        new = inputdlg(prompt,dlg_title,numlines,old);
        
        for i = 1:length(new)
            if ~strcmp(new{i},old{i})
                PHZ.region.(prompt{i}) = str2num(new{i});
                
                PHZ = phzUtil_history(PHZ,['Changed ',prompt{i},' region',...
                    ' from [',old{i},'] to [',new{i},'].'],verbose);
            end
        end
end

end