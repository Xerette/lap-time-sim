function car = car_f1_2026_pu()
%CAR_F1_2026_PU  The 2025 car with a 2026-style hybrid power unit.
%
%   Same chassis, tyres and aero as car_f1_2025.m (grip calibrated to the
%   2025 Silverstone pole), so any lap time change comes from the power unit
%   alone. The single 745 kW power figure is replaced by:
%
%     combustion engine (ICE)  ~400 kW   always available
%     MGU-K                     350 kW   only while the battery has energy
%     harvest per lap          <= 8.5 MJ (MGU-K under braking, rear axle)
%
%   Sources: Honda's 2026 regulations overview (ICE ~400 kW, MGU-K 350 kW,
%   ~8.5 MJ recovered per lap). Efficiencies and brake split are estimates.
%   Not modelled: active aero (2026 low-drag straight mode), the lower 2026
%   minimum mass, part-throttle harvesting and speed-dependent MGU-K limits.

car = car_f1_2025();
car.name = '2025 chassis + 2026-style power unit (estimates)';
car = rmfield(car, 'power');

car.p_ice            = 400e3;   % W, combustion engine
car.p_k              = 350e3;   % W, MGU-K deploy and harvest limit
car.e_harvest_max    = 8.5e6;   % J, max energy recovered per lap
car.eta_rt           = 0.90;    % battery round-trip efficiency (harvest -> deploy)
car.rear_brake_share = 0.42;    % share of braking power on the rear axle (MGU-K side)
end
