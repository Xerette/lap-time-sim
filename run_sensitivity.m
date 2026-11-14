%% RUN_SENSITIVITY  What is each car parameter worth in lap time?
% Changes one parameter at a time and re-runs the lap, then sweeps a grid of
% downforce (CL*A) and drag (CD*A) to show the aero trade-off.

clear; close all;
if ~exist('src', 'dir')
    error('Set MATLAB''s Current Folder to the lap-time-sim folder first.');
end
addpath('src', 'cars');

%% Settings
car        = car_f1_2025();
track_name = 'Silverstone';
track      = load_track(fullfile('data', 'tracks', 'Silverstone_raceline.csv'), track_name, 1.0, 5.0);
n_grid     = 21;     % aero map resolution (n_grid^2 laps; 21 -> 441 laps)

if ~exist('results', 'dir'), mkdir('results'); end
tag = lower(track_name);
t0  = lap_time(car, track);
fprintf('Baseline %s: %.3f s\n\n', track_name, t0);

%% 1) The same +1 percent change on every parameter: which one matters most here?
labels = {'downforce C_L A', 'drag C_D A', 'mass', 'power', 'tyre grip \mu'};
deltas = zeros(1, 5);
c = car; c.cla   = car.cla * 1.01;   deltas(1) = lap_time(c, track) - t0;
c = car; c.cda   = car.cda * 1.01;   deltas(2) = lap_time(c, track) - t0;
c = car; c.mass  = car.mass * 1.01;  deltas(3) = lap_time(c, track) - t0;
c = car; c.power = car.power * 1.01; deltas(4) = lap_time(c, track) - t0;
c = car; c.mu_x  = car.mu_x * 1.01;  c.mu_y = car.mu_y * 1.01;
deltas(5) = lap_time(c, track) - t0;

fprintf('+1 %% on each parameter:\n');
names = {'downforce CL*A', 'drag CD*A', 'mass', 'power', 'tyre grip mu'};
for i = 1:5
    fprintf('  %-16s %+.3f s\n', names{i}, deltas(i));
end
plot_sensitivity(strcat(labels, ' +1 %'), deltas, ...
    sprintf('%s: lap time change for +1 %% of each parameter', track_name), ...
    fullfile('results', [tag '_sensitivity.png']));

%% 2) Engineering units: the trade-offs a team actually talks about
fprintf('\nIn engineering units:\n');
c = car; c.mass  = car.mass + 10;    fprintf('  +10 kg mass                %+.3f s\n', lap_time(c, track) - t0);
c = car; c.power = car.power + 10e3; fprintf('  +10 kW power               %+.3f s\n', lap_time(c, track) - t0);
c = car; c.cla   = car.cla + 0.1;    fprintf('  +0.1 m^2 CL*A (downforce)  %+.3f s\n', lap_time(c, track) - t0);
c = car; c.cda   = car.cda + 0.1;    fprintf('  +0.1 m^2 CD*A (drag)       %+.3f s\n', lap_time(c, track) - t0);

% Break-even L/D: how much downforce must a part add per unit of drag?
c1 = car; c1.cla = car.cla + 0.05;  c2 = car; c2.cla = car.cla - 0.05;
dT_dcla = (lap_time(c1, track) - lap_time(c2, track)) / 0.1;
c1 = car; c1.cda = car.cda + 0.05;  c2 = car; c2.cda = car.cda - 0.05;
dT_dcda = (lap_time(c1, track) - lap_time(c2, track)) / 0.1;
fprintf('\nBreak-even L/D for a new aero part at %s: %.2f\n', track_name, abs(dT_dcda / dT_dcla));
fprintf('(a part that adds downforce and drag at a better ratio than this is worth fitting)\n');

%% 3) Aero map: lap time over a grid of downforce and drag
cla = linspace(car.cla * 0.7, car.cla * 1.3, n_grid);
cda = linspace(car.cda * 0.7, car.cda * 1.3, n_grid);
T = zeros(n_grid, n_grid);
fprintf('\nAero map: %d laps ', n_grid^2);
for i = 1:n_grid
    for j = 1:n_grid
        c = car; c.cla = cla(j); c.cda = cda(i);
        T(i, j) = lap_time(c, track);
    end
    fprintf('.');
end
fprintf(' done\n');
plot_aero_map(cla, cda, T, [car.cla, car.cda], track_name, ...
              fullfile('results', [tag '_aero_map.png']));
save(fullfile('results', [tag '_aero_map.mat']), 'cla', 'cda', 'T');
