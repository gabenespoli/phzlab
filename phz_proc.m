function varargout = phz_proc(PHZ,procType)
%PHZ_PROC  Display processing history.
% 
% usage:    
%     phz_proc(PHZ) > display processing history in command window.
%     PROCLIST = phz_proc(PHZ)
%     PROCLIST = phz_proc(PHZ,PROCTYPE)
% 
% input:   
%     PHZ         = PHZLAB data structure.
%     PROCTYPE    = Specifying a PROCTYPE instead returns 0 if this
%                   function has not been run, 1 if is has, and 2 if it
%                   was the last function run. PROCTYPE is a string with
%                   an abbreviated function name (i.e. the field that
%                   would show up in PHZ.proc).
% 
% output:  
%     PROCLIST    = A cell array of a chronological list of abbreviated
%                   function names.
% 
% Written by Gabriel A. Nespoli 2016-04-11.
if nargin == 0 && nargout == 0, help phz_proc, return, end
if nargin < 2, procType = []; end

% get chronological list of functions
procList = fieldnames(PHZ.proc);
for i = 1:length(procList)
    switch procList{i}
        case 'rej',  procList{i,2} = PHZ.proc.rej.threshold;
        case 'blc',  procList{i,2} = PHZ.proc.blc.region;
        case 'norm', procList{i,2} = PHZ.proc.norm.type;
        otherwise,   procList{i,2} = (PHZ.proc.(procList{i}));
    end
end

% query if a function has been run
if ~isempty(procType)
    ind = find(ismember(procList(:,1),procType));
    if isempty(ind), ind = 0;
    elseif ind <  size(procList,1), ind = 1;
    elseif ind == size(procList,1), ind = 2;
    end
    varargout{1} = ind;
    
elseif nargout == 0
    disp(procList)
    
else varargout{1} = procList;
end
end