function c = lt_colors()
%LT_COLORS  Colours used by all plots (one place to change them).
c.blue   = hex2rgb('2a78d6');
c.orange = hex2rgb('eb6834');
c.ink    = hex2rgb('0b0b0b');
c.ink2   = hex2rgb('52514e');
c.muted  = hex2rgb('9a9893');
c.grid   = hex2rgb('e6e5e1');

% Light-to-dark blue ramp for speed (slow = light, fast = dark)
stops = [hex2rgb('b7d3f6'); hex2rgb('6da7ec'); hex2rgb('2a78d6'); ...
         hex2rgb('1c5cab'); hex2rgb('0d366b')];
c.speed_cmap = interp1(linspace(0, 1, 5), stops, linspace(0, 1, 256));
end

function rgb = hex2rgb(h)
rgb = [hex2dec(h(1:2)), hex2dec(h(3:4)), hex2dec(h(5:6))] / 255;
end
