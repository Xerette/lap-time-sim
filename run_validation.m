%% RUN_VALIDATION  Compare the simulated lap with a real F1 lap (Phase 2).
% Downloads the real lap from the free OpenF1 API the first time (needs
% internet), caches it in data/telemetry/, then lines the two laps up and
% shows where the sim is too fast or too slow.

clear; close all;
if ~exist('src', 'dir')
    error('Set MATLAB''s Current Folder to the lap-time-sim folder first.');
end
addpath('src', 'cars');

%% Settings
car        = car_f1_2025();
track_name = 'Silverstone';
track_file = fullfile('data', 'tracks', 'Silverstone_raceline.csv');
year       = 2025;
session    = 'Qualifying';
driver     = 1;                 % car number (1 = Verstappen in 2025)
real_label = 'Verstappen, 2025 pole';
% Corner names in lap order (used if the number of detected corners matches)
corner_names = {'Abbey', 'Village', 'The Loop', 'Brooklands', 'Luffield', 'Copse', ...
                'Maggotts', 'Becketts', 'Chapel', 'Stowe', 'Vale', 'Club'};

%% Simulated lap
track = load_track(track_file, track_name, 1.0, 5.0);
res   = simulate_lap(car, track);

%% Real lap from OpenF1
tel = get_openf1_lap(year, track_name, session, driver);

%% Line them up and compare
cmp = compare_to_telemetry(track, res, tel, car.g);

fprintf('\nLap time    sim %s   real %s   (sim %+.3f s)\n', ...
        fmt_laptime(cmp.lap_sim), fmt_laptime(cmp.lap_real), cmp.lap_sim - cmp.lap_real);
fprintf('Distance    sim line %.0f m, real car %.0f m (from integrating speed)\n', cmp.L, cmp.D);
fprintf('Speed trace correlation r = %.3f, RMS difference %.1f km/h\n', cmp.r, cmp.rms_kmh);
fprintf('Top speed   sim %.0f km/h   real %.0f km/h\n', max(cmp.v_sim), max(cmp.v_real));
fprintf('Peak lateral g   sim %.2f   real %.2f  (real = v^2 x the sim line''s curvature)\n', ...
        max(abs(cmp.ay_sim)), max(abs(cmp.ay_real)));

fprintf('\nCorner minimum speeds (real samples are ~3.7 per second, so real minima may read a little high):\n');
nc = size(cmp.corners, 1);
if numel(corner_names) ~= nc
    corner_names = arrayfun(@(i) sprintf('corner %d', i), 1:nc, 'UniformOutput', false);
end
fprintf('  #  corner        at [m]   sim [km/h]   real [km/h]   sim - real\n');
for i = 1:nc
    k = cmp.corners(i, :);
    fprintf('%3d  %-12s %7.0f   %9.0f   %10.0f   %+7.0f km/h (%+.0f %%)\n', ...
            i, corner_names{i}, k(1), k(2), k(3), k(2) - k(3), 100 * (k(2) - k(3)) / k(3));
end

%% Save the plot and the corner table
if ~exist('results', 'dir'), mkdir('results'); end
tag = lower(track_name);
plot_validation(cmp, track_name, real_label, fullfile('results', [tag '_validation.png']));
fid = fopen(fullfile('results', [tag '_corners.csv']), 'w');
fprintf(fid, 'number,corner,distance_m,sim_min_kmh,real_min_kmh\n');
for i = 1:nc
    fprintf(fid, '%d,%s,%.0f,%.1f,%.1f\n', i, corner_names{i}, cmp.corners(i, 1:3));
end
fclose(fid);
fprintf('\nSaved results/%s_validation.png and results/%s_corners.csv\n', tag, tag);
