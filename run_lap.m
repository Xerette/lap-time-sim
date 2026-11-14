%% RUN_LAP  Simulate one lap and save the plots.
% Open this file in MATLAB with the lap-time-sim folder as your Current
% Folder, then press Run (or run one %% section at a time with Ctrl+Enter).

clear; close all;
if ~exist('src', 'dir')
    error('Set MATLAB''s Current Folder to the lap-time-sim folder first.');
end
addpath('src', 'cars');

%% Settings: change these
car        = car_f1_2025();                     % edit cars/car_f1_2025.m
track_file = fullfile('data', 'tracks', 'Silverstone_raceline.csv');
track_name = 'Silverstone';
ds         = 1.0;    % track resolution [m]
smooth_m   = 5.0;    % curvature filter width [m]

%% Simulate
track = load_track(track_file, track_name, ds, smooth_m);
res   = simulate_lap(car, track);

%% Report
g = car.g;
fprintf('Car    : %s\n', car.name);
fprintf('Track  : %s, %.0f m\n', track.name, track.length);
fprintf('Lap    : %s  (%.3f s)\n', fmt_laptime(res.lap_time), res.lap_time);
fprintf('Speed  : %.0f to %.0f km/h\n', min(res.v) * 3.6, max(res.v) * 3.6);
fprintf('Peak g : %.2f lateral, %.2f accel, %.2f braking\n', ...
        max(abs(res.ay)) / g, max(res.ax) / g, -min(res.ax) / g);

%% Plots and a per-metre CSV (saved in results/)
if ~exist('results', 'dir'), mkdir('results'); end
tag = lower(track_name);
plot_track_map(track, res, fullfile('results', [tag '_map.png']));
plot_speed_trace(track, res, fullfile('results', [tag '_speed.png']));
plot_gg(res, g, fullfile('results', [tag '_gg.png']));

fid = fopen(fullfile('results', [tag '_lap.csv']), 'w');
fprintf(fid, 's_m,t_s,v_kmh,ax_g,ay_g\n');
fprintf(fid, '%.3f,%.3f,%.3f,%.3f,%.3f\n', ...
        [track.s, res.t, res.v * 3.6, res.ax / g, res.ay / g]');
fclose(fid);
fprintf('Saved plots and CSV to results/\n');
