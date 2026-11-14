function res = simulate_lap(car, track)
%SIMULATE_LAP  Quasi-steady-state point-mass lap time simulation.
%
%   res = simulate_lap(car, track)
%
%   Three limits on speed at every metre of track:
%     1. Apex limit    : fastest cornering speed (apex_speed.m)
%     2. Forward pass  : start slow, accelerate as hard as grip and power allow
%     3. Backward pass : run the lap in reverse, "accelerating" with the brakes,
%                        which finds where braking must start for each corner
%   The car's speed is the lowest of the three. Lap time = sum(ds / v).
%
%   res fields: lap_time [s], v, v_apex [m/s], ax, ay [m/s^2], t [s]

kappa = track.kappa;
ds    = track.ds;
n     = numel(kappa);
v_apex = apex_speed(car, kappa);

% Start both passes at the slowest corner: the car is certainly at its
% apex limit there, so it is a known speed on a closed lap.
[~, i0] = min(v_apex);
order = [i0:n, 1:i0-1];                 % i0, i0+1, ..., n, 1, ..., i0-1

% ---- Forward pass: accelerate ----
v_fwd = zeros(n, 1);
v_fwd(i0) = v_apex(i0);
for j = 1:n-1
    a = order(j);  b = order(j+1);
    v = v_fwd(a);
    traction = min(long_grip_left(car, v, kappa(a)), ...
                   car.eta * car.power / (car.mass * max(v, 1)));
    ax = traction - drag_accel(car, v);
    v_fwd(b) = min(sqrt(max(v^2 + 2*ax*ds, 0)), v_apex(b));
end

% ---- Backward pass: brake (drag helps the brakes here) ----
v_bwd = zeros(n, 1);
v_bwd(i0) = v_apex(i0);
rev = [i0, fliplr(order(2:end))];       % i0, i0-1, ..., 1, n, ..., i0+1
for j = 1:n-1
    b = rev(j);  a = rev(j+1);
    v = v_bwd(b);
    decel = long_grip_left(car, v, kappa(b)) + drag_accel(car, v);
    v_bwd(a) = min(sqrt(v^2 + 2*decel*ds), v_apex(a));
end

v = min(v_fwd, v_bwd);

% ---- Time: each step covers ds at the average speed of its two ends ----
v_next = circshift(v, -1);
dt = 2 * ds ./ (v + v_next);
t  = [0; cumsum(dt(1:end-1))];

res = struct('lap_time', sum(dt), 'v', v, 'v_apex', v_apex, ...
             'ax', (v_next.^2 - v.^2) / (2*ds), 'ay', v.^2 .* kappa, 't', t);
end

% -------------------------------------------------------------------------
function n = normal_accel(car, v)
% Tyre load per kg: gravity plus downforce (downforce = 1/2 rho CLA v^2)
n = car.g + 0.5 * car.rho * car.cla * v^2 / car.mass;
end

function a = drag_accel(car, v)
% Deceleration from aero drag and rolling resistance
a = 0.5 * car.rho * car.cda * v^2 / car.mass + car.crr * normal_accel(car, v);
end

function a = long_grip_left(car, v, kappa)
% Longitudinal grip still available after cornering (friction ellipse)
n      = normal_accel(car, v);
ay     = v^2 * abs(kappa);
ay_max = car.mu_y * n;
a = car.mu_x * n * sqrt(max(1 - (ay / ay_max)^2, 0));
end
