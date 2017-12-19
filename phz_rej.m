% function for backwards compatibility
% should just call phz_reject

function PHZ = phz_rej(PHZ,varargin)
PHZ = phz_reject(PHZ,varargin{:});
end
