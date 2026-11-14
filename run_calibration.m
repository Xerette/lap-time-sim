%% RUN_CALIBRATION  Fit tyre grip, downforce and drag to the real lap.
% Least-squares fit (fminsearch) of mu, CL*A and CD*A that makes the
% simulated speed trace match Verstappen's 2025 Silverstone pole lap as
% closely as possible. Run run_validation.m first (it downloads the data).
%
% What this tells you: if the fit removes most of the error, the car
% parameters were wrong. If a large error remains, the problem is something
% the car parameters cannot fix (track geometry, missing physics).

clear; close all;
if ~exist('src', 'dir')
    error('Set MATLAB''s Current Folder to the lap-time-sim folder first.');
end
addpath('src', 'cars');

%% Settings
car   = car_f1_2025();
track = load_track(fullfile('data', 'tracks', 'Silverstone_raceline.csv'), 'Silverstone', 1.0, 5.0);
tel   = get_openf1_lap(2025, 'Silverstone', 'Qualifying', 1);

%% Baseline
cmp0 = compare_to_telemetry(track, simulate_lap(car, track), tel, car.g);

%% Fit [mu, CL*A, CD*A] to minimise the RMS speed difference
p0  = [car.mu_x, car.cla, car.cda];
obj = @(p) speed_rms(p, car, track, tel);
opts = optimset('TolX', 1e-3, 'TolFun', 1e-3, 'MaxFunEvals', 300, 'Display', 'off');
fprintf('Fitting mu, CL*A and CD*A to the real speed trace...\n');
p = fminsearch(obj, p0, opts);

fit = car;
fit.mu_x = p(1);  fit.mu_y = p(1);  fit.cla = p(2);  fit.cda = p(3);
res1 = simulate_lap(fit, track);
cmp1 = compare_to_telemetry(track, res1, tel, car.g);

%% Report
fprintf('\n                 baseline    fitted\n');
fprintf('mu               %8.2f  %8.2f\n', car.mu_x, fit.mu_x);
fprintf('CL*A [m^2]       %8.2f  %8.2f\n', car.cla, fit.cla);
fprintf('CD*A [m^2]       %8.2f  %8.2f\n', car.cda, fit.cda);
fprintf('RMS speed error  %8.1f  %8.1f km/h\n', cmp0.rms_kmh, cmp1.rms_kmh);
fprintf('Correlation r    %8.3f  %8.3f\n', cmp0.r, cmp1.r);
fprintf('Lap time         %8s  %8s   (real %s)\n', fmt_laptime(cmp0.lap_sim), ...
        fmt_laptime(cmp1.lap_sim), fmt_laptime(tel.lap_time));
fprintf('Peak lateral g   %8.2f  %8.2f\n', max(abs(cmp0.ay_sim)), max(abs(cmp1.ay_sim)));
