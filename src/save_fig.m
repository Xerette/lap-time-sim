function save_fig(fig, outfile)
%SAVE_FIG  Save a figure as a 150 dpi PNG.
set(fig, 'PaperPositionMode', 'auto');
print(fig, outfile, '-dpng', '-r150');
end
