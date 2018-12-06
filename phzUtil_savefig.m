function phzUtil_savefig(fig, filename, verbose)
% phzUtil_savefig: Utility function to save a figure.
% phzUtil_savefig(filename)
% phzUtil_savefig(fig, filename)
% 
% If fig is not specified, gcf (current figure) is used.
% Output type is determined from file extension. Currently supports 
%   png (automatically does transparent background), pdf, and eps.
% If filename doesn't have an extension, .png is used.

if nargin < 2
    filename = fig;
    fig = gcf;
end
if nargin < 3
    verbose = true;
end

[~,~,ext] = fileparts(filename);
if isempty(ext), ext = '.png'; end

switch ext
    case '.png'

        % save the original bg color for later use
        background = get(gcf, 'color'); 
        set(fig, 'InvertHardCopy','off');

        % print file w/o transparency
        print(fig, '-dpng',filename);

        % read image data back in
        cdata = imread(filename);

        % write it back out - setting transparency info
        imwrite(cdata, filename, 'png', ...
            'BitDepth', 16, ...
            'transparency', background)

    case '.eps'
        print(fig, '-depsc', filename);

    case '.pdf'
        print(fig, '-dpdf', filename);

end

if verbose
    fprintf('  Saved figure %s\n', filename)
end

end
