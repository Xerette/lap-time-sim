function v = apex_speed(car, kappa)
%APEX_SPEED  Fastest speed the car can corner at, at every point.
%
%   At the limit, the tyres supply all the centripetal acceleration:
%       v^2 |kappa| = mu_y * (g + k_L v^2),   k_L = rho * CLA / (2 m)
%   Solving for v:
%       v = sqrt( mu_y g / (|kappa| - mu_y k_L) )
%   If the denominator is <= 0, downforce grows faster than the corner
%   needs, so the corner is flat out and only power / top speed limit v.

k_l   = 0.5 * car.rho * car.cla / car.mass;
k     = abs(kappa);
denom = k - car.mu_y * k_l;

v  = car.v_max * ones(size(k));
ok = denom > 0;
v(ok) = sqrt(car.mu_y * car.g ./ denom(ok));
v = min(v, car.v_max);
end
