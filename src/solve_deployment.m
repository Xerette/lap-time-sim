function res = solve_deployment(car, track, rule, e_budget)
%SOLVE_DEPLOYMENT  Spend exactly the energy available in one lap.
%
%   res = solve_deployment(car, track, rule, e_budget)
%
%   rule     : 'until' (naive: deploy from the start line until it runs out)
%              or 'speed' (deploy only below a speed threshold)
%   e_budget : MGU-K energy available for the lap [J]. Leave it out (or [])
%              for an energy-neutral lap: the battery ends the lap where it
%              started, so the budget is what the lap harvests, times the
%              round-trip efficiency.
%
%   Finds the rule's parameter (cut-off distance or speed) by bisection so
%   that the energy deployed equals the budget. If even unlimited deployment
%   uses less than the budget, energy is not the limit and the 'full' lap
%   is returned.

if nargin < 4, e_budget = []; end

switch rule
    case 'until', lo = 0;  hi = track.length;  tol = 1;      % m
    case 'speed', lo = 0;  hi = car.v_max + 1; tol = 0.02;   % m/s
    otherwise, error('solve_deployment:rule', 'Use ''until'' or ''speed''.');
end

res = simulate_lap_pu(car, track, rule, hi);
if res.e_dep <= budget(res, car, e_budget)
    return                                   % energy is not limiting
end

for k = 1:60
    mid = 0.5 * (lo + hi);
    r = simulate_lap_pu(car, track, rule, mid);
    if r.e_dep > budget(r, car, e_budget)
        hi = mid;
    else
        lo = mid;  res = r;
    end
    if hi - lo < tol, break; end
end
if res.param ~= lo
    res = simulate_lap_pu(car, track, rule, lo);
end
end

function b = budget(r, car, e_budget)
if isempty(e_budget)
    b = car.eta_rt * r.e_harv;
else
    b = e_budget;
end
end
