function res = simulate_lap_pu(car, track, rule, param)
%SIMULATE_LAP_PU  Lap simulation with a hybrid power unit (ICE + MGU-K).
%
%   res = simulate_lap_pu(car, track, rule, param)
%
%   Same quasi-steady-state method as simulate_lap.m, but the power is
%   car.p_ice plus car.p_k from the MGU-K wherever the deployment rule is on:
%
%     'none'  : ICE only, never deploy
%     'full'  : always deploy (unlimited battery energy, an upper bound)
%     'until' : deploy from the start line until distance param [m]
%               (the naive "use it until it runs out" strategy)
%     'speed' : deploy fully while the car is slower than param [m/s];
%               above it, deploy only enough to hold that speed
%               (spend the energy where it buys the most time)
%
%   After the lap is solved, the MGU-K power actually used and the energy
%   harvested under braking are worked out from the final speed trace:
%
%     wheel power   P_w = m v (a_x + drag/m)          (+ driving, - braking)
%     MGU-K deploy  P_k = min(max(P_w/eta - P_ice, 0), MGU-K power the rule allows)
%     MGU-K harvest P_h = min(p_k, rear_share * braking power), capped per lap
%
%   res fields: lap_time, v, t, dt, p_k (deploy, W), p_h (harvest, W),
%               e_dep, e_harv (J), batt (battery energy vs start line, J),
%               p_allow (MGU-K power the rule allowed at each point, W)

kappa = track.kappa;
ds    = track.ds;
s     = track.s;
n     = numel(kappa);
v_apex = apex_speed(car, kappa);

[~, i0] = min(v_apex);
order = [i0:n, 1:i0-1];

% ---- Forward pass: accelerate with ICE (+ MGU-K where the rule is on) ----
v_fwd   = zeros(n, 1);
p_allow = zeros(n, 1);
v_fwd(i0) = v_apex(i0);
for j = 1:n-1
    a = order(j);  b = order(j+1);
    v = v_fwd(a);
    p_allow(a) = deploy_power(car, rule, param, s(a), v);
    p = car.p_ice + p_allow(a);
    traction = min(long_grip_left(car, v, kappa(a)), car.eta * p / (car.mass * max(v, 1)));
    ax = traction - drag_accel(car, v);
    v_fwd(b) = min(sqrt(max(v^2 + 2*ax*ds, 0)), v_apex(b));
end
p_allow(order(n)) = deploy_power(car, rule, param, s(order(n)), v_fwd(order(n)));

% ---- Backward pass: brake (unchanged; the MGU-K only replaces friction braking) ----
v_bwd = zeros(n, 1);
v_bwd(i0) = v_apex(i0);
rev = [i0, fliplr(order(2:end))];
for j = 1:n-1
    b = rev(j);  a = rev(j+1);
    v = v_bwd(b);
    decel = long_grip_left(car, v, kappa(b)) + drag_accel(car, v);
    v_bwd(a) = min(sqrt(v^2 + 2*decel*ds), v_apex(a));
end

v = min(v_fwd, v_bwd);
v_next = circshift(v, -1);
dt = 2 * ds ./ (v + v_next);
t  = [0; cumsum(dt(1:end-1))];
ax = (v_next.^2 - v.^2) / (2*ds);

% ---- Power flows on the final speed trace ----
n_acc   = car.g + 0.5 * car.rho * car.cla * v.^2 / car.mass;
drag    = 0.5 * car.rho * car.cda * v.^2 / car.mass + car.crr * n_acc;
p_wheel = car.mass .* v .* (ax + drag);
p_k     = min(max(max(p_wheel, 0) / car.eta - car.p_ice, 0), p_allow);
p_h     = min(car.p_k, car.rear_brake_share .* max(-p_wheel, 0));

e_dep      = sum(p_k .* dt);
e_harv_raw = sum(p_h .* dt);
e_harv     = min(e_harv_raw, car.e_harvest_max);
p_h        = p_h * (e_harv / max(e_harv_raw, eps));    % apply the per-lap cap
batt       = cumsum((car.eta_rt * p_h - p_k) .* dt);  % stored minus spent, from the start line

res = struct('lap_time', sum(dt), 'v', v, 't', t, 'dt', dt, 'p_k', p_k, 'p_h', p_h, ...
             'e_dep', e_dep, 'e_harv', e_harv, 'batt', batt, 'p_allow', p_allow, ...
             'rule', rule, 'param', param);
end

% -------------------------------------------------------------------------
function p = deploy_power(car, rule, param, s, v)
% MGU-K power the deployment rule allows at this point [W]
switch rule
    case 'none',  p = 0;
    case 'full',  p = car.p_k;
    case 'until', p = car.p_k * (s < param);
    case 'speed'
        if v < param
            p = car.p_k;
        else
            % At or above the threshold: only what it takes to hold this
            % speed against drag (zero if the ICE alone can hold it)
            p = min(car.p_k, max(0, car.mass * v * drag_accel(car, v) / car.eta - car.p_ice));
        end
    otherwise
        error('simulate_lap_pu:rule', 'Unknown rule %s', rule);
end
end

function n = normal_accel(car, v)
n = car.g + 0.5 * car.rho * car.cla * v^2 / car.mass;
end

function a = drag_accel(car, v)
a = 0.5 * car.rho * car.cda * v^2 / car.mass + car.crr * normal_accel(car, v);
end

function a = long_grip_left(car, v, kappa)
n      = normal_accel(car, v);
ay     = v^2 * abs(kappa);
ay_max = car.mu_y * n;
a = car.mu_x * n * sqrt(max(1 - (ay / ay_max)^2, 0));
end
