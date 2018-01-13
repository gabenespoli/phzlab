%PHZ_FIELD  Change the value and/or order of fields in a PHZ structure.
%   PHZ_FIELD opens a dialog with current values of the PHZ structure that
%   can be edited.
% 
% USAGE    
%   PHZ = phz_field(PHZ)
%   PHZ = phz_field(PHZ,FIELD)
% 
% INPUT   
%   PHZ   = [struct] PHZLAB data structure.
%   FIELD = [string] String specifying the type of fields to change.
%           Options are 'basic' (default), 'region'.
% 
% OUTPUT
%   PHZ = [struct] PHZLAB data structure with fields adjusted.

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

function PHZ = phz_field(PHZ,field,verbose)

if nargin == 0 && nargout == 0, help phz_field, return, end
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
                old{i} = cellstr(PHZ.lib.spec.(prompt{i}(1:end-5)));
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
                    PHZ.lib.spec.(prompt{i}(1:end-5)) = regexp(new{i},' ','split');
                else
                    PHZ.(prompt{i}) = regexp(new{i},' ','split');
                end

                PHZ = phz_history(PHZ,['Changed ',prompt{i},...
                    ' from ''',old{i},''' to ''',new{i},'''.'],verbose);
            end
        end
        
    case {'region','regions'}
                
        prompt = PHZ.lib.tags.region;
        
        old = cell(size(prompt));
        
        for i = 1:length(old)
            old{i} = num2str(PHZ.region.(prompt{i}));
        end
        
        new = inputdlg(prompt,dlg_title,numlines,old,'on');
        
        for i = 1:length(new)
            if ~strcmp(new{i},old{i})
                PHZ.region.(prompt{i}) = eval(['[',new{i},']']);
                
                PHZ = phz_history(PHZ,['Changed ',prompt{i},' region',...
                    ' from [',old{i},'] to [',new{i},'].'],verbose);
            end
        end
        
    case {'regionnames','regionname'}
        
        prompt = {'' '' '' '' ''};
        
        old = PHZ.lib.tags.region;
        
        new = inputdlg(prompt,dlg_title,numlines,old,'on');
        
        for i = 1:length(new)
            if ~strcmp(new{i},old{i})
                PHZ.lib.tags.region{i} = new{i};
                
                PHZ = phz_history(PHZ,['Changed region name ',old{i},...
                    ' to ',new{i},'.'],verbose);
            end
        end
        
        
end

end
