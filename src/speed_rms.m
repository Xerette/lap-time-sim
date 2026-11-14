function e = speed_rms(p, car, track, tel)
%SPEED_RMS  RMS speed difference [km/h] between the sim and a real lap
%   for p = [mu, CL*A, CD*A]. Used by run_calibration.m.
if any(p <= 0), e = 1e3; return; end      % keep the search physical
c = car;
c.mu_x = p(1);  c.mu_y = p(1);  c.cla = p(2);  c.cda = p(3);
cmp = compare_to_telemetry(track, simulate_lap(c, track), tel, car.g);
e = cmp.rms_kmh;
end
