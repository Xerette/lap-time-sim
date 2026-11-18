function fig = plot_deployment(track, r_naive, r_smart, r_full, e_budget, outfile)
%PLOT_DEPLOYMENT  Where the battery energy goes: speed and MGU-K power vs distance.
%   Top: speed with unlimited energy, naive deployment and speed-threshold
%   deployment. Bottom: MGU-K power (deploy up, harvest down) for both.
c = lt_colors();
fig = figure('Color', 'w', 'Position', [100 100 1100 640]);

subplot(2, 1, 1);
plot(track.s, r_full.v * 3.6, '--', 'Color', c.muted, 'LineWidth', 1.2);
hold on
plot(track.s, r_naive.v * 3.6, 'Color', c.orange, 'LineWidth', 1.6);
plot(track.s, r_smart.v * 3.6, 'Color', c.blue, 'LineWidth', 2);
plot([0 track.length], r_smart.param * 3.6 * [1 1], ':', 'Color', c.blue, 'LineWidth', 1);
xlim([0 track.length]);
grid on
set(gca, 'GridColor', c.grid, 'XColor', c.ink2, 'YColor', c.ink2, 'Box', 'off');
ylabel('speed [km/h]');
legend({sprintf('unlimited energy  %s', fmt_laptime(r_full.lap_time)), ...
        sprintf('deploy until empty  %s', fmt_laptime(r_naive.lap_time)), ...
        sprintf('deploy below %.0f km/h  %s', r_smart.param * 3.6, fmt_laptime(r_smart.lap_time)), ...
        'speed threshold'}, 'Location', 'southeast');
legend boxoff
title(sprintf('%s: spending %.1f MJ of MGU-K energy per lap (ICE 400 kW + MGU-K 350 kW)', ...
      track.name, e_budget / 1e6), 'Color', c.ink);

subplot(2, 1, 2);
plot(track.s, r_naive.p_k / 1e3, 'Color', c.orange, 'LineWidth', 1.4);
hold on
plot(track.s, r_smart.p_k / 1e3, 'Color', c.blue, 'LineWidth', 1.8);
plot(track.s, -r_smart.p_h / 1e3, 'Color', c.muted, 'LineWidth', 1.2);
plot([0 track.length], [0 0], 'Color', c.ink2, 'LineWidth', 0.8);
xlim([0 track.length]);
ylim([-400 400]);
grid on
set(gca, 'GridColor', c.grid, 'XColor', c.ink2, 'YColor', c.ink2, 'Box', 'off');
xlabel('distance from start line [m]');
ylabel('MGU-K power [kW]');
legend({'deploy: until empty', 'deploy: below threshold', ...
        sprintf('harvest under braking (%.1f MJ)', r_smart.e_harv / 1e6)}, 'Location', 'southeast');
legend boxoff
if nargin > 5, save_fig(fig, outfile); end
end
