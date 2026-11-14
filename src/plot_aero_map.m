function fig = plot_aero_map(cla, cda, T, base, track_name, outfile)
%PLOT_AERO_MAP  Lap time over a grid of downforce (CL*A) and drag (CD*A).
%   T(i,j) = lap time for cda(i), cla(j). base = [cla0, cda0] of the baseline car.
c = lt_colors();
[~, j0] = min(abs(cla - base(1)));
[~, i0] = min(abs(cda - base(2)));
dT = T - T(i0, j0);                      % lap time relative to the baseline car

fig = figure('Color', 'w', 'Position', [100 100 780 620]);
levels = floor(min(dT(:)) * 4) / 4 : 0.25 : ceil(max(dT(:)) * 4) / 4;
contourf(cla, cda, dT, levels, 'LineStyle', 'none');
hold on
whole = levels(abs(levels - round(levels)) < 1e-9);
[C, h] = contour(cla, cda, dT, whole, 'LineColor', 'w');
clabel(C, h, 'Color', 'w', 'FontSize', 8);

for ld = [3 4 5]                         % lines of constant aero efficiency L/D
    plot(cla, cla / ld, ':', 'Color', c.ink, 'LineWidth', 1);
    x_end = min(cla(end), max(cda) * ld);
    x_lab = x_end - 0.06 * (cla(end) - cla(1));
    if x_lab / ld > min(cda)
        text(x_lab, x_lab / ld, sprintf('L/D = %d', ld), 'Color', c.ink, ...
             'BackgroundColor', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center');
    end
end
plot(base(1), base(2), 'o', 'MarkerSize', 10, 'MarkerFaceColor', c.orange, ...
     'MarkerEdgeColor', 'w', 'LineWidth', 2);
text(base(1), base(2), '   baseline car', 'Color', c.ink, 'FontWeight', 'bold', ...
     'BackgroundColor', 'w', 'VerticalAlignment', 'top');
xlim([min(cla) max(cla)]);
ylim([min(cda) max(cda)]);
colormap(gca, flipud(c.speed_cmap));
cb = colorbar;
ylabel(cb, 'lap time vs baseline [s]');
xlabel('downforce  C_L A  [m^2]');
ylabel('drag  C_D A  [m^2]');
title(sprintf('%s: lap time across aero configurations', track_name), 'Color', c.ink);
if nargin > 5, save_fig(fig, outfile); end
end
