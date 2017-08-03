%PHZ_DISCARD

% this function should be called by these functions before they 
%   do anything else:
% - phz_summary
% - phz_feature
% - phz_plot
% - phz_writetable
%
% this function will actually get rid of trials that are marked
%   for rejection in:
% - PHZ.reject.keep
% - PHZ.review.keep
% - PHZ.subset.keep (check for multiple of these in PHZ.proc)
%
% issues:
% - should the rejections from the different sources be done in
%   the order they appear, or some other order?
%
% - could find indices of any of them, loop them, and switch/case
%   them to do the rejections
%
% - the proc fields that are actually dependant on each other
%   such that it matters which order they are done in are:
%   reject, blsub, norm, transform
%
