function car = car_f1_2025()
%CAR_F1_2025  Point-mass parameters for a 2025-spec F1 car (estimates).
%
%   Mass, power and aero are public-ballpark estimates. Tyre grip mu was
%   tuned so the lap at Silverstone matches the 2025 pole (1:24.892).
%   Copy this file to make another car (e.g. car_jeep.m).

car.name  = 'F1 2025-spec (estimated; grip calibrated to 2025 Silverstone pole)';
car.mass  = 805;      % kg, car + driver + fuel
car.power = 745e3;    % W, peak power (engine + hybrid)
car.eta   = 0.92;     % drivetrain efficiency (power reaching the wheels)
car.mu_x  = 1.80;     % longitudinal tyre friction coefficient
car.mu_y  = 1.80;     % lateral tyre friction coefficient
car.cla   = 4.8;      % CL*A [m^2], downforce coefficient x frontal area
car.cda   = 1.3;      % CD*A [m^2], drag coefficient x frontal area
car.crr   = 0.015;    % rolling resistance coefficient
car.rho   = 1.2;      % air density [kg/m^3]
car.g     = 9.81;     % [m/s^2]
car.v_max = 100;      % hard top-speed cap [m/s] (gearing / rev limit)
end
