function cmp = compare_to_telemetry(track, res, tel, g, n)
%COMPARE_TO_TELEMETRY  Line up a simulated lap with a real one and compare.
%
%   cmp = compare_to_telemetry(track, res, tel, g)
%
%   tel is a real lap from get_openf1_lap (fields t, v_kmh, lap_time).
%
%   The two laps are compared on a common "fraction of the lap" grid, because
%   the sim's racing line (track.length) and the real car's integrated
%   distance are never exactly the same length. The sim lap is then shifted
%   round the loop until its speed trace best matches the real one, which
%   finds where the real timing line sits on the sim's racing line.

if nargin < 4, g = 9.81; end
if nargin < 5, n = 4000; end
f = ((0:n-1)' + 0.5) / n;                 % lap fraction, 0..1

% ---- Real lap: integrate speed over time to get distance ----
tau   = (0:0.02:tel.lap_time)';
v_tau = interp1(tel.t, tel.v_kmh, tau, 'linear');
v_tau = fill_ends(v_tau);
d_tau = [0; cumsum(0.5 * (v_tau(1:end-1) + v_tau(2:end)) / 3.6 .* diff(tau))];
D = d_tau(end);                           % real lap distance [m]
[d_u, iu] = unique(d_tau / D);
v_real = interp1(d_u, v_tau(iu), f, 'linear');
t_real = interp1(d_u, tau(iu), f, 'linear');

% ---- Sim lap on the same grid ----
L = track.length;
s_loop = [track.s; L];
v_sim0 = interp1(s_loop, [res.v; res.v(1)] * 3.6, f * L);
k_sim0 = interp1(s_loop, [track.kappa; track.kappa(1)], f * L);

% Best circular shift: v_sim0(i + k) should match v_real(i)
a  = v_real - mean(v_real);
b  = v_sim0 - mean(v_sim0);
cc = real(ifft(conj(fft(a)) .* fft(b)));
[~, k] = max(cc);
k = k - 1;
v_sim  = circshift(v_sim0, -k);
kappa  = circshift(k_sim0, -k);
shift_m = k / n * L;                      % where the real lap starts on the sim line

% ---- Time along the lap (each lap integrated over its own length) ----
t_sim = cumsum((L / n) ./ (v_sim / 3.6));
t_sim = t_sim - 0.5 * (L / n) / (v_sim(1) / 3.6);
delta_t = t_sim - t_real;                 % + = sim behind the real car

% ---- Lateral g ----
ay_sim  = (v_sim  / 3.6).^2 .* kappa / g;
ay_real = (v_real / 3.6).^2 .* kappa / g;  % uses the sim line's curvature

% ---- Corners: dips in the sim speed, matched to the real trace ----
% A corner = a local minimum (+-40 m) that sits at least 8 km/h below the
% fastest point within 250 m on both sides.
dist = f * D;
step = D / n;
w   = max(1, round(40 / step));
wp  = max(1, round(250 / step));
w2  = max(1, round(35 / step));           % +-35 m to find the real minimum
corners = zeros(0, 4);                    % [distance, sim min, real min, index]
for i = 1:n
    near = mod((i - w:i + w) - 1, n) + 1;
    if v_sim(i) > min(v_sim(near)), continue; end
    before = mod((i - wp:i) - 1, n) + 1;
    after  = mod((i:i + wp) - 1, n) + 1;
    if min(max(v_sim(before)), max(v_sim(after))) - v_sim(i) < 8, continue; end
    if ~isempty(corners) && dist(i) - corners(end, 1) < 30, continue; end
    j = mod((i - w2:i + w2) - 1, n) + 1;
    corners(end+1, :) = [dist(i), v_sim(i), min(v_real(j)), i]; %#ok<AGROW>
end

r = corrcoef(v_sim, v_real);
cmp = struct('f', f, 'dist', dist, 'D', D, 'L', L, 'v_real', v_real, 'v_sim', v_sim, ...
             't_real', t_real, 't_sim', t_sim, 'delta_t', delta_t, ...
             'ay_real', ay_real, 'ay_sim', ay_sim, 'shift_m', shift_m, ...
             'corners', corners, 'r', r(1, 2), ...
             'rms_kmh', sqrt(mean((v_sim - v_real).^2)), ...
             'lap_sim', res.lap_time, 'lap_real', tel.lap_time);
end

% -------------------------------------------------------------------------
function v = fill_ends(v)
% Replace NaN at either end (outside the samples) with the nearest value
good = find(~isnan(v));
v(1:good(1) - 1) = v(good(1));
v(good(end) + 1:end) = v(good(end));
end
