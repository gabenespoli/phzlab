function PHZ = phz_norm(PHZ,normtype,verbose)
%PHZ_NORM  Convert data to z-scores.
%
% usage:    PHZ = PHZ_NORM(PHZ,NORMTYPE)
% 
% inputs:   PHZ      = PHZLAB data structure.
%           NORMTYPE = String specifying the grouping variable within which
%                      to normalize. For each group of trials representing
%                      a unique value of this grouping variable, each data
%                      point has the mean subtracted and is divided by the
%                      standard deviation. Entering 0 undoes normalization.
% 
% outputs:  PHZ.norm.type     = The grouping variable used for 
%                               normalization.
%           PHZ.norm.mean     = If there is only one unique value of 
%                               NORMTYPE, this is the mean value of all 
%                               trials. Otherwise it is a vector the same 
%                               length as the number of trials, specifying 
%                               the mean used for each trial.
%           PHZ.norm.stDev    = Same as above for standard deviation.
%           PHZ.norm.oldUnits = Units of data before conversion to
%                               z-scores.
% 
% examples:
%   PHZ = phz_norm(PHZ,'participant') >> For each participant, find the
%         mean and standard deviation of all trials, and use these values
%         normalize data.
%   PHZ = phz_norm(PHZ,0) >> Undo normalization.
%
% Written by Gabriel A. Nespoli 2016-03-27. Revised 2016-04-04.
if nargin == 0 && nargout == 0; help phz_norm, return, end
if nargin > 1 && isempty(normtype), return, end
if nargin < 2, normtype = 'participant'; end
if nargin < 3, verbose = true; end

[PHZ,do_norm,do_restore] = verifyNORMinput(PHZ,normtype,verbose);

if do_norm || do_restore
    
    if do_restore
        if length(PHZ.norm.mean) == 1
            PHZ.data = (PHZ.data .* PHZ.norm.stDev) + PHZ.norm.mean;
        else
            PHZ.data = (PHZ.data .* repmat(PHZ.norm.stDev,1,size(PHZ.data,2))) + repmat(PHZ.norm.mean,1,size(PHZ.data,2));
        end
        PHZ.units = PHZ.norm.oldUnits;
        PHZ = rmfield(PHZ,'norm');
        PHZ = phzUtil_history(PHZ,'Normalization has been undone.',verbose);
    end
    
    
    if do_norm
        
        PHZ = getNORMstructure(PHZ);
        
        % verify input
        normtype = lower(normtype);
        if ~ismember(normtype,{'participant','group','session','trials','all','none'})
            error('Invalid NORMTYPE.')
        else PHZ.norm.type = normtype;
        end 
        
        % do normalization
        if strcmp(normtype,'none')
            normtype = 'each trial';
            PHZ.norm.mean = mean(PHZ.data,2);
            PHZ.norm.stDev = std(PHZ.data,[],2);
            PHZ.data = (PHZ.data - repmat(PHZ.norm.mean,1,size(PHZ.data,2))) ./ repmat(PHZ.norm.stDev,1,size(PHZ.data,2));
            
        elseif strcmp(normtype,'all') || length(PHZ.(normtype)) == 1
            normtype = 'all trials';
            PHZ.norm.mean = mean(PHZ.data(:));
            PHZ.norm.stDev = std(PHZ.data(:));
            PHZ.data = (PHZ.data - PHZ.norm.mean) ./ PHZ.norm.stDev;
            
        else
            PHZ.norm.mean = nan(size(PHZ.tags.(normtype)));
            PHZ.norm.stDev = nan(size(PHZ.tags.(normtype)));
            for i = 1:length(PHZ.(normtype))
                ind = PHZ.tags.(normtype) == PHZ.(normtype)(i);
                data = PHZ.data(ind,:);
                PHZ.norm.mean(ind) = mean(data(:));
                PHZ.norm.stDev(ind) = std(data(:));
                PHZ.data(ind,:) = (data - mean(data(:))) ./ std(data(:));
            end
        end
        
        PHZ.norm.oldUnits = PHZ.units;
        PHZ.units = 'z-scores';
        
        PHZ = phzUtil_history(PHZ,['Converted data to z-scores by ',normtype,'.'],verbose);
        
    end
end
end

function [PHZ,do_norm,do_restore] = verifyNORMinput(PHZ,normtype,verbose)

if isnumeric(normtype) && normtype == 0
    
    % newNORM == 0, oldNORM == 0 (do nothing and return)
    if ~ismember('norm',fieldnames(PHZ))
        do_restore = false;
        do_norm = false;
        if verbose, disp('Data are currently not z-scores.'), end
        
    else % newNORM == 0, oldNORM == val
        do_restore = true;
        do_norm = false;
        
    end
    
else
    % newNORM == val, oldNORM == val
    if ismember('norm',fieldnames(PHZ))
        do_restore = true;
        do_norm = true;
        
    else % newNORM == val, oldNORM == 0
        do_restore = false;
        do_norm = true;
        
    end
end
end

function PHZ = getNORMstructure(PHZ)
PHZ.norm.type = '';
PHZ.norm.mean = [];
PHZ.norm.stDev = [];
end