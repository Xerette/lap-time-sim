function s = fmt_laptime(t)
%FMT_LAPTIME  Seconds -> 'm:ss.sss'
s = sprintf('%d:%06.3f', floor(t / 60), mod(t, 60));
end
