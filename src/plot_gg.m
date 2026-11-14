function fig = plot_gg(res, g, outfile)
%PLOT_GG  G-G diagram: longitudinal vs lateral acceleration, 1 dot per metre.
c = lt_colors();
fig = figure('Color', 'w', 'Position', [100 100 560 560]);
plot(res.ay / g, res.ax / g, '.', 'Color', c.blue, 'MarkerSize', 6);
hold on
plot(xlim, [0 0], 'Color', c.muted);
plot([0 0], ylim, 'Color', c.muted);
axis equal
grid on
set(gca, 'GridColor', c.grid, 'XColor', c.ink2, 'YColor', c.ink2, 'Box', 'off');
xlabel('lateral acceleration [g]');
ylabel('longitudinal acceleration [g]   (+ accel, - brake)');
title('G-G diagram (each dot = 1 m of track)', 'Color', c.ink);
if nargin > 2, save_fig(fig, outfile); end
end
