function fig = plot_speed_trace(track, res, outfile)
%PLOT_SPEED_TRACE  Speed vs distance, with the cornering limit dashed.
c = lt_colors();
fig = figure('Color', 'w', 'Position', [100 100 1100 420]);
cap = min(res.v_apex, max(res.v) * 1.15) * 3.6;   % keep the plot readable
plot(track.s, cap, '--', 'Color', c.muted, 'LineWidth', 1.2);
hold on
plot(track.s, res.v * 3.6, 'Color', c.blue, 'LineWidth', 2);
xlim([0 track.length]);
ylim([0 max(cap) * 1.05]);
grid on
set(gca, 'GridColor', c.grid, 'XColor', c.ink2, 'YColor', c.ink2, 'Box', 'off');
xlabel('distance [m]');
ylabel('speed [km/h]');
legend({'cornering limit (apex speed)', 'simulated speed'}, 'Location', 'southeast');
legend boxoff
title(sprintf('%s: speed vs distance', track.name), 'Color', c.ink);
if nargin > 2, save_fig(fig, outfile); end
end
