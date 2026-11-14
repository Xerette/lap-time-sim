function t = lap_time(car, track)
%LAP_TIME  Just the lap time [s] (shortcut for sensitivity sweeps).
res = simulate_lap(car, track);
t = res.lap_time;
end
