function PHZ = phz_create
%PHZ_CREATE  Create a new PHZ structure.
% 
% PHZ = PHZ_CREATE creates a blank PHZ structure with fields that are to be
%   filled manually by the user. Ideally, all epoched datafiles are
%   readable into MATLAB so that this can be scripted. A recommended
%   workflow for this process is described in the help for phz_create_loop.
% 
%   study           = 'string'
%   datatype        = 'string', type of data in PHZ.data.
%   participant     = 'string', {'1D cell array of strings'}, or [numeric].
%                     Must be of length 1 or same length as trials.
%   group           = (same as participant)
%   session         = (same as participant)
%   trials          = 'string', {'1D cell array of strings'}, or [numeric].
%                     Must be same length as size(data,1).
%   times           = [numeric], vector of times for each sample (in s).
%                     Must be same length as size(data,2).
%   data            = [numeric], 2D array TRIALS-by-TIME.
%   units           = 'string', units of data in PHZ.data.
%   srate           = [numeric], sampling frequency.
%   region.baseline = [numeric], endpoints of baseline region (in s).
%   region.target   = [numeric], endpoints of target region. Also
%                     available are target2, target3, and target4 (in s).
%   resp.q1         = {'1D cell array of strings'}, behavioural responses
%                     to each trial. Also available are q2, q3, q4, and q5.
%   resp.q1_acc     = [numeric], column of accuracy values.
%   resp.q1_rt      = [numeric], column of reaction times.
%   spec.*_order    = {'1D cell array of strings'}, specifying the unique
%                     values and the desired order of a grouping variable.
%                     Replace '*' with 'participant', 'group', 'session',
%                     'trials', and 'region'.
%   spec.*_spec     = {'1D cell array of strings'} specifying the colour
%                     and line type specfications for plotting. Must be the
%                     same length as spec.*_order. See the help for the
%                     plot.m function for more detail on line types.
%   misc            = Any type, available for user data.
%
% Written by Gabe Nespoli 2016-01-27. Revised 2016-03-22.

if nargout == 0 && nargin == 0, help phz_create, return, end

% create empty PHZ structure
PHZ.study = '';
PHZ.datatype = ''; % i.e. 'scl', 'zyg', 'ffr', etc.

PHZ.participant = '';
PHZ.group = ''; % aka between-subjects variable
PHZ.session = ''; % aka within-subjects variable
PHZ.trials = ''; % trialtype label for each trial (i.e., trial order)
PHZ.times = []; % in seconds

PHZ.data = []; % actual data, 2D, trials X time
PHZ.units = '';
PHZ.srate = []; % sampling frequency in Hz

PHZ.region.baseline = []; % baseline region if data are baseline-corrected
PHZ.region.target = [];
PHZ.region.target2 = [];
PHZ.region.target3 = [];
PHZ.region.target4 = [];

PHZ.resp.q1 = {};
PHZ.resp.q1_acc = [];
PHZ.resp.q1_rt = [];
PHZ.resp.q2 = {};
PHZ.resp.q2_acc = [];
PHZ.resp.q2_rt = [];
PHZ.resp.q3 = {};
PHZ.resp.q3_acc = [];
PHZ.resp.q3_rt = [];
PHZ.resp.q4 = {};
PHZ.resp.q4_acc = [];
PHZ.resp.q4_rt = [];
PHZ.resp.q5 = {};
PHZ.resp.q5_acc = [];
PHZ.resp.q5_rt = [];

PHZ.spec.participant_order = {};
PHZ.spec.participant_spec = {};
PHZ.spec.group_order = {};
PHZ.spec.group_spec = {};
PHZ.spec.session_order = {};
PHZ.spec.session_spec = {};
PHZ.spec.trials_order = {};
PHZ.spec.trials_spec = {};
PHZ.spec.region_order = {'baseline','target','target2','target3','target4'};
PHZ.spec.region_spec = {'k','b','g','y','r'};

PHZ.misc = [];
PHZ.history = {};

% add creation date to FFR.history
PHZ = phzUtil_history(PHZ,'PHZ structure created.');

end