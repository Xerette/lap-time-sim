function fig = plot_validation(cmp, track_name, real_label, outfile)
%PLOT_VALIDATION  Simulated vs real lap: speed, speed difference, time delta.
c = lt_colors();
fig = figure('Color', 'w', 'Position', [60 60 1150 820]);

% ---- 1) Speed traces ----
ax1 = subplot(3, 1, 1);
plot(cmp.dist, cmp.v_real, 'Color', c.orange, 'LineWidth', 1.6); hold on
plot(cmp.dist, cmp.v_sim, 'Color', c.blue, 'LineWidth', 1.6);
for i = 1:size(cmp.corners, 1)          % number each corner above the traces
    text(cmp.corners(i, 1), min(cmp.corners(i, 2:3)) - 18, sprintf('%d', i), ...
         'HorizontalAlignment', 'center', 'Color', c.ink2, 'FontSize', 9);
end
ylim([0, 1.08 * max([cmp.v_sim; cmp.v_real])]);
ylabel('speed [km/h]');
legend({sprintf('real: %s (%s)', real_label, fmt_laptime(cmp.lap_real)), ...
        sprintf('simulated (%s)', fmt_laptime(cmp.lap_sim))}, ...
       'Location', 'northoutside', 'Orientation', 'horizontal');
legend boxoff
title(sprintf('%s: simulated vs real lap  (speed correlation r = %.3f, RMS error %.1f km/h)', ...
      track_name, cmp.r, cmp.rms_kmh), 'Color', c.ink);
style(c);

% ---- 2) Speed difference ----
ax2 = subplot(3, 1, 2);
plot(cmp.dist, cmp.v_sim - cmp.v_real, 'Color', c.ink2, 'LineWidth', 1.2); hold on
plot([0 cmp.D], [0 0], 'Color', c.muted);
ylabel('sim - real [km/h]');
style(c);

% ---- 3) Time delta along the lap ----
ax3 = subplot(3, 1, 3);
plot(cmp.dist, cmp.delta_t, 'Color', c.ink, 'LineWidth', 1.6); hold on
plot([0 cmp.D], [0 0], 'Color', c.muted);
ylabel('time delta [s]  (+ = sim behind)');
xlabel('distance along the real lap [m]');
style(c);

linkaxes([ax1 ax2 ax3], 'x');
xlim(ax1, [0 cmp.D]);
if nargin > 3, save_fig(fig, outfile); end
end

function style(c)
grid on
set(gca, 'GridColor', c.grid, 'XColor', c.ink2, 'YColor', c.ink2, 'Box', 'off');
end
