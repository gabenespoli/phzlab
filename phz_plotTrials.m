

% OUTPUT
%   PHZ.proc.rej.manual = [logical vector]

function PHZ = phz_plotTrials(PHZ, varargin)

% defaults
startTrial = 1;
smoothing = false;

% user-defined

% allow for preprocessing like smoothing
% option to keep current rejections or reset them

rej = false(size(PHZ.data,1),1);
currentTrial = 1;

keepGoing = true;
while keepGoing == true
    h = figure;
    plot(PHZ.times, PHZ.data(currentTrial,:));
    title(getPlotTitle(rej, currentTrial));
    
    [~,~,key] = ginput(1);
    
    switch key
        case {32, 114} % spacebar, r
            rej = rejToggle(rej, currentTrial);
            
        case {29, 31, 106, 110} % right, down, j, n
            currentTrial = currentTrial + 1;
            if currentTrial > size(PHZ.data,1), currentTrial = 1; end
            
        case {28, 30, 107, 112} % left, up, k, p
            currentTrial = currentTrial - 1;
            if currentTrial < 1, currentTrial = size(PHZ.data,1); end
            
        case 103 % g
            goto = input(['Enter trial number (1-', ...
                num2str(size(PHZ.data,1)), '): ']);
            if goto < 1 || goto > size(PHZ.data,1)
                fprintf('Trial number out of range. Displaying trial #%i.', currentTrial)
            else
                currentTrial = goto;
            end
            
        case {27, 113} % escape, q
            keepGoing = false;
            
    end
    close(h)
end
end

function plotTitle = getPlotTitle(rej, currentTrial)
if rej(currentTrial)
    rejStatus =  '\color{red}[REJECTED]';
else
    rejStatus = '\color{blue}[INCLUDED]';
end
plotTitle = ['Trial #', num2str(currentTrial), ' ', rejStatus];

end

function rej = rejToggle(rej,i)
if rej(i)
    rej(i) = false;
else
    rej(i) = true;
end
end
