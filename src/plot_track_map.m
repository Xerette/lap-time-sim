function fig = plot_track_map(track, res, outfile)
%PLOT_TRACK_MAP  Track drawn from above, coloured by simulated speed.
c = lt_colors();
fig = figure('Color', 'w', 'Position', [100 100 820 680]);
scatter(track.x, track.y, 14, res.v * 3.6, 'filled');
hold on
plot(track.x(1), track.y(1), 'o', 'MarkerSize', 10, 'MarkerFaceColor', c.orange, ...
     'MarkerEdgeColor', 'w', 'LineWidth', 2);
text(track.x(1), track.y(1), '    start', 'Color', c.ink2);
axis equal off
colormap(gca, c.speed_cmap);
cb = colorbar;
ylabel(cb, 'speed [km/h]');
title(sprintf('%s: simulated speed around the lap (%s)', track.name, ...
      fmt_laptime(res.lap_time)), 'Color', c.ink);
if nargin > 2, save_fig(fig, outfile); end
end
