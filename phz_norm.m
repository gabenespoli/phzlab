%PHZ_NORM  Convert data to z-scores.
%
% USAGE    
%   PHZ = PHZ_NORM(PHZ)
%   PHZ = PHZ_NORM(PHZ,NORMTYPE)
% 
% INPUT
%   PHZ       = [struct] PHZLAB data structure.
% 
%   NORMTYPE  = [string] Specifies the grouping variable within which
%               to normalize. For each group of trials representing a
%               unique value of this grouping variable, each data point
%               has the mean subtracted and is divided by the standard
%               deviation. Entering 0 undoes normalization. Default
%               is to normalize by 'participant'.
% 
% OUTPUT
%   PHZ.norm.type     = [string] The grouping variable used in NORMTYPE.
%                             
%   PHZ.norm.mean     = [numeric] If there is only one unique value of 
%                       NORMTYPE this is the mean value of all trials. 
%                       Otherwise it is a vector the same length as the 
%                       number of trials, specifying the mean used for 
%                       each trial.
% 
%   PHZ.norm.stDev    = [numeric] Same as above for standard deviation.
% 
%   PHZ.norm.oldUnits = [string] Units before normalization (new units
%                       after normalization is 'z-score'.
% 
% EXAMPLES
%   PHZ = phz_norm(PHZ,'participant') >> For each participant, find the
%         mean and standard deviation of all trials, and use these values
%         normalize data.
% 
%   PHZ = phz_norm(PHZ,0) >> Undo normalization.

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

function PHZ = phz_norm(PHZ,normtype,verbose)

if nargin == 0 && nargout == 0; help phz_norm, return, end
if nargin > 1 && isempty(normtype), return, end
if nargin < 2, normtype = 'participant'; end
if nargin < 3, verbose = true; end

[PHZ,do_norm,do_restore] = verifyNORMinput(PHZ,normtype,verbose);

if do_norm || do_restore
    
    ind = 1:size(PHZ.data,1);
    
    if do_restore
        
        % check that no other processing has been done since phz_norm
        names = fieldnames(PHZ.proc);
        if ~strcmp(names{end},'norm')
            error(['Other processing has been done since',...
                'normalization. Cannot undo normalization.'])
        end
        
        if length(PHZ.proc.norm.mean) == 1
            PHZ.data = (PHZ.data .* PHZ.proc.norm.stDev(ind)) + PHZ.proc.norm.mean(ind);
        else
            PHZ.data = (PHZ.data .* repmat(PHZ.proc.norm.stDev(ind),1,size(PHZ.data,2))) + repmat(PHZ.proc.norm.mean(ind),1,size(PHZ.data,2));
        end
        PHZ.units = PHZ.proc.norm.oldUnits;
        PHZ.proc = rmfield(PHZ.proc,'norm');
        PHZ = phz_history(PHZ,'Normalization has been undone.',verbose);
    end
    
    if do_norm
        
        PHZ = getNORMstructure(PHZ);
        
        % verify input
        normtype = lower(normtype);
        if ~ismember(normtype,{'participant','group','session','trials','all','none'})
            error('Invalid NORMTYPE.')
        else PHZ.proc.norm.type = normtype;
        end 
        
        % do normalization
        if strcmp(normtype,'none')
            normtype = 'each trial';
            PHZ.proc.norm.mean = mean(PHZ.data,2);
            PHZ.proc.norm.stDev = std(PHZ.data,[],2);
            PHZ.data = (PHZ.data - repmat(PHZ.proc.norm.mean(ind),1,size(PHZ.data,2))) ./ repmat(PHZ.proc.norm.stDev(ind),1,size(PHZ.data,2));
            
        elseif strcmp(normtype,'all') || length(PHZ.(normtype)) == 1
            normtype = 'all trials';
            PHZ.proc.norm.mean = mean(PHZ.data(:)); % single value
            PHZ.proc.norm.stDev = std(PHZ.data(:));
            PHZ.data = (PHZ.data - PHZ.proc.norm.mean(ind)) ./ PHZ.proc.norm.stDev(ind);
            
        else
            PHZ.proc.norm.mean = nan(size(PHZ.lib.tags.(normtype)));
            PHZ.proc.norm.stDev = nan(size(PHZ.lib.tags.(normtype)));
            for i = 1:length(PHZ.(normtype))
                ind = PHZ.lib.tags.(normtype) == PHZ.(normtype)(i);
                data = PHZ.data(ind,:);
                PHZ.proc.norm.mean(ind) = mean(data(:));
                PHZ.proc.norm.stDev(ind) = std(data(:));
                PHZ.data(ind,:) = (data - mean(data(:))) ./ std(data(:));
            end
        end
        
        PHZ.proc.norm.oldUnits = PHZ.units;
        PHZ.units = 'z-scores';
        
        PHZ = phz_history(PHZ,['Converted data to z-scores by ',normtype,'.'],verbose);
        
    end
end
end

function [PHZ,do_norm,do_restore] = verifyNORMinput(PHZ,normtype,verbose)

if isnumeric(normtype) && normtype == 0
    
    % newNORM == 0, oldNORM == 0 (do nothing and return)
    if ~ismember('norm',fieldnames(PHZ.proc))
        do_restore = false;
        do_norm = false;
        if verbose, disp('Data are currently not z-scores.'), end
        
    else % newNORM == 0, oldNORM == val
        do_restore = true;
        do_norm = false;
        
    end
    
else
    % newNORM == val, oldNORM == val
    if ismember('norm',fieldnames(PHZ.proc))
        do_restore = true;
        do_norm = true;
        
    else % newNORM == val, oldNORM == 0
        do_restore = false;
        do_norm = true;
        
    end
end
end

function PHZ = getNORMstructure(PHZ)
PHZ.proc.norm.type = '';
PHZ.proc.norm.mean = [];
PHZ.proc.norm.stDev = [];
end
