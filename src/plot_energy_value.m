function fig = plot_energy_value(budgets_mj, T, names, e_reg_mj, outfile)
%PLOT_ENERGY_VALUE  Lap time against MGU-K energy available per lap.
%   T{k} is an [n x 2] matrix for track k: column 1 = deploy until empty,
%   column 2 = deploy below a speed threshold. Times are shown relative to
%   the threshold strategy at the regulation energy (e_reg_mj).
c = lt_colors();
cols = {c.blue, c.orange};
fig = figure('Color', 'w', 'Position', [100 100 900 520]);
hold on
h = zeros(1, 2 * numel(T));
lab = cell(1, 2 * numel(T));
for k = 1:numel(T)
    t_ref = interp1(budgets_mj, T{k}(:, 2), e_reg_mj);
    h(2*k-1) = plot(budgets_mj, T{k}(:, 2) - t_ref, '-', 'Color', cols{k}, 'LineWidth', 2.2);
    h(2*k)   = plot(budgets_mj, T{k}(:, 1) - t_ref, '--', 'Color', cols{k}, 'LineWidth', 1.4);
    lab{2*k-1} = sprintf('%s: deploy below a speed threshold', names{k});
    lab{2*k}   = sprintf('%s: deploy until empty', names{k});
end
yl = ylim;
plot(e_reg_mj * [1 1], yl, ':', 'Color', c.ink2, 'LineWidth', 1);
text(e_reg_mj, yl(2), sprintf('  %.1f MJ harvest limit', e_reg_mj), ...
     'Color', c.ink2, 'VerticalAlignment', 'top');
ylim(yl);
grid on
set(gca, 'GridColor', c.grid, 'XColor', c.ink2, 'YColor', c.ink2, 'Box', 'off');
xlabel('MGU-K energy available per lap [MJ]');
ylabel('lap time vs threshold strategy at the limit [s]');
legend(h, lab, 'Location', 'northeast');
legend boxoff
title('What each megajoule is worth, and what deployment strategy is worth', 'Color', c.ink);
if nargin > 4, save_fig(fig, outfile); end
end
