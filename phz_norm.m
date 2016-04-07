function PHZ = phz_norm(PHZ,normtype,verbose)
%PHZ_NORM  Convert data to z-scores.
%
% usage:    PHZ = PHZ_NORM(PHZ)
%           PHZ = PHZ_NORM(PHZ,NORMTYPE)
% 
% inputs:   PHZ      = PHZLAB data structure.
%           NORMTYPE = String specifying the grouping variable within which
%                      to normalize. For each group of trials representing
%                      a unique value of this grouping variable, each data
%                      point has the mean subtracted and is divided by the
%                      standard deviation. Entering 0 undoes normalization.
%                      Default is to normalize by 'participant'.
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
% Written by Gabriel A. Nespoli 2016-03-27. Revised 2016-04-06.
if nargin == 0 && nargout == 0; help phz_norm, return, end
if nargin > 1 && isempty(normtype), return, end
if nargin < 2, normtype = 'participant'; end
if nargin < 3, verbose = true; end

[PHZ,do_norm,do_restore] = verifyNORMinput(PHZ,normtype,verbose);

if do_norm || do_restore
    
    if do_restore
        if length(PHZ.proc.norm.mean) == 1
            PHZ.data = (PHZ.data .* PHZ.proc.norm.stDev) + PHZ.proc.norm.mean;
        else
            PHZ.data = (PHZ.data .* repmat(PHZ.proc.norm.stDev,1,size(PHZ.data,2))) + repmat(PHZ.proc.norm.mean,1,size(PHZ.data,2));
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
            PHZ.data = (PHZ.data - repmat(PHZ.proc.norm.mean,1,size(PHZ.data,2))) ./ repmat(PHZ.proc.norm.stDev,1,size(PHZ.data,2));
            
        elseif strcmp(normtype,'all') || length(PHZ.(normtype)) == 1
            normtype = 'all trials';
            PHZ.proc.norm.mean = mean(PHZ.data(:));
            PHZ.proc.norm.stDev = std(PHZ.data(:));
            PHZ.data = (PHZ.data - PHZ.proc.norm.mean) ./ PHZ.proc.norm.stDev;
            
        else
            PHZ.proc.norm.mean = nan(size(PHZ.meta.tags.(normtype)));
            PHZ.proc.norm.stDev = nan(size(PHZ.meta.tags.(normtype)));
            for i = 1:length(PHZ.(normtype))
                ind = PHZ.meta.tags.(normtype) == PHZ.(normtype)(i);
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