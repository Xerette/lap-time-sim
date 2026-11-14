function fig = plot_sensitivity(labels, deltas, ttl, outfile)
%PLOT_SENSITIVITY  Horizontal bars of lap time change (blue faster, orange slower).
c = lt_colors();
[~, idx] = sort(abs(deltas));
labels = labels(idx);
deltas = deltas(idx);
y = 1:numel(deltas);

fig = figure('Color', 'w', 'Position', [100 100 820 120 + 50 * numel(deltas)]);
hold on
neg = deltas < 0;
% Two bar series on the same y positions (zeros where the other colour applies)
barh(y, deltas .* neg,  0.6, 'FaceColor', c.blue,   'EdgeColor', 'none');
barh(y, deltas .* ~neg, 0.6, 'FaceColor', c.orange, 'EdgeColor', 'none');
span = max(abs(deltas));
for i = y
    d = deltas(i);
    if d < 0
        text(d - 0.02 * span, i, sprintf('%+.3f s', d), 'HorizontalAlignment', 'right', 'Color', c.ink);
    else
        text(d + 0.02 * span, i, sprintf('%+.3f s', d), 'HorizontalAlignment', 'left', 'Color', c.ink);
    end
end
plot([0 0], [0.4, numel(deltas) + 0.6], 'Color', c.ink2, 'LineWidth', 1);
xlim([-1.35 1.35] * span);
ylim([0.4, numel(deltas) + 0.6]);
set(gca, 'YTick', y, 'YTickLabel', labels, 'XColor', c.ink2, 'YColor', c.ink2, 'Box', 'off');
xlabel('lap time change [s]   (blue = faster, orange = slower)');
title(ttl, 'Color', c.ink);
if nargin > 3, save_fig(fig, outfile); end
end
