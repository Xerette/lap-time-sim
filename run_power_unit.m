%% RUN_POWER_UNIT  2026-style power unit: where should the battery energy go?
% Replaces the single 745 kW power figure with a ~400 kW combustion engine
% plus a 350 kW MGU-K that only works while the battery has energy, then asks:
%   1. How much energy does braking alone recover per lap?
%   2. With the 8.5 MJ per lap the rules allow, does it matter WHERE it is spent?
%   3. What is each extra megajoule worth (e.g. overtake mode's +0.5 MJ)?
% Same chassis, tyres and aero as the 2025 car, so only the power unit changes.
% Takes about a minute in MATLAB.

clear; close all;
if ~exist('src', 'dir')
    error('Set MATLAB''s Current Folder to the lap-time-sim folder first.');
end
addpath('src', 'cars');

%% Settings
car      = car_f1_2026_pu();
tracks   = {'Silverstone', 'Silverstone_raceline.csv'; 'Monza', 'Monza_raceline.csv'};
e_reg    = car.e_harvest_max;      % 8.5 MJ, the per-lap harvest limit
budgets  = (2:0.5:10)';            % MJ, energy sweep for the value curve
if ~exist('results', 'dir'), mkdir('results'); end

nt = size(tracks, 1);
T  = cell(1, nt);
summary = zeros(nt, 11);

for k = 1:nt
    name  = tracks{k, 1};
    track = load_track(fullfile('data', 'tracks', tracks{k, 2}), name, 1.0, 5.0);
    tag   = lower(name);

    %% Bounds and the braking-only energy balance
    r_full  = simulate_lap_pu(car, track, 'full', 0);        % unlimited battery
    r_brake = solve_deployment(car, track, 'speed');         % energy-neutral, braking harvest only

    %% Spend the regulation 8.5 MJ two ways
    r_naive = solve_deployment(car, track, 'until', e_reg);  % from the start line until empty
    r_smart = solve_deployment(car, track, 'speed', e_reg);  % only below a speed threshold
    gain    = r_naive.lap_time - r_smart.lap_time;

    %% Value of energy: sweep the budget
    Tk = zeros(numel(budgets), 2);
    for i = 1:numel(budgets)
        Tk(i, 1) = solve_deployment(car, track, 'until', budgets(i) * 1e6).lap_time;
        Tk(i, 2) = solve_deployment(car, track, 'speed', budgets(i) * 1e6).lap_time;
    end
    T{k} = Tk;
    r_plus = solve_deployment(car, track, 'speed', e_reg + 0.5e6);   % overtake mode: +0.5 MJ
    per_mj = (interp1(budgets, Tk(:, 2), e_reg/1e6 - 0.5) - interp1(budgets, Tk(:, 2), e_reg/1e6 + 0.5));

    %% Report
    fprintf('\n=== %s (%.0f m) ===\n', name, track.length);
    fprintf('Unlimited battery (750 kW everywhere)   %s, needs %.1f MJ of MGU-K energy\n', ...
            fmt_laptime(r_full.lap_time), r_full.e_dep / 1e6);
    fprintf('Braking alone recovers                   %.2f MJ of the %.1f MJ allowed (%.0f %%)\n', ...
            r_brake.e_harv / 1e6, e_reg / 1e6, 100 * r_brake.e_harv / e_reg);
    fprintf('  -> energy-neutral lap on braking only  %s (deploy below %.0f km/h)\n', ...
            fmt_laptime(r_brake.lap_time), r_brake.param * 3.6);
    fprintf('With %.1f MJ to spend:\n', e_reg / 1e6);
    fprintf('  deploy until empty                     %s (runs out at %.0f m)\n', ...
            fmt_laptime(r_naive.lap_time), r_naive.param);
    fprintf('  deploy below %3.0f km/h                 %s\n', ...
            r_smart.param * 3.6, fmt_laptime(r_smart.lap_time));
    fprintf('  strategy is worth                      %.2f s per lap\n', gain);
    fprintf('Each extra MJ is worth                   %.3f s per lap\n', per_mj);
    fprintf('Overtake mode (+0.5 MJ) is worth         %.3f s per lap\n', r_smart.lap_time - r_plus.lap_time);

    summary(k, :) = [track.length, r_full.lap_time, r_full.e_dep/1e6, r_brake.e_harv/1e6, ...
                     r_naive.lap_time, r_naive.param, r_smart.lap_time, r_smart.param*3.6, ...
                     gain, per_mj, r_smart.lap_time - r_plus.lap_time];

    plot_deployment(track, r_naive, r_smart, r_full, e_reg, ...
                    fullfile('results', [tag '_deployment.png']));
end

plot_energy_value(budgets, T, tracks(:, 1)', e_reg / 1e6, ...
                  fullfile('results', 'power_unit_energy_value.png'));

fid = fopen(fullfile('results', 'power_unit_summary.csv'), 'w');
fprintf(fid, ['track,length_m,lap_unlimited_s,energy_unlimited_MJ,braking_harvest_MJ,' ...
              'lap_until_empty_s,until_empty_cut_m,lap_threshold_s,threshold_kmh,' ...
              'strategy_gain_s,s_per_MJ,overtake_0p5MJ_s\n']);
for k = 1:nt
    fprintf(fid, '%s,%.0f,%.3f,%.2f,%.2f,%.3f,%.0f,%.3f,%.1f,%.3f,%.3f,%.3f\n', ...
            tracks{k, 1}, summary(k, :));
end
fclose(fid);
fprintf('\nSaved plots and results/power_unit_summary.csv\n');
