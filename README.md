# Lap Time Simulator (MATLAB)

A quasi-steady-state, point-mass lap time simulator written in MATLAB, built to answer
the question an aerodynamicist cares about: **how much lap time is a change to the car worth?**

v1 drives an estimated 2025-spec F1 car around Silverstone on a real racing line.
Base MATLAB only, no toolboxes needed.

| Result (Silverstone) | Value |
|---|---|
| Simulated lap | 1:24.826 (2025 pole 1:24.892; tyre grip calibrated to it) |
| +10 kg mass | +0.31 s per lap (paddock rule of thumb: 0.3–0.4 s) |
| +0.1 m² CL·A (downforce) | −0.37 s |
| +0.1 m² CD·A (drag) | +0.58 s |
| Break-even L/D for a new aero part | 1.56 |

## Run it

1. Open MATLAB and set the **Current Folder** to this `lap-time-sim` folder.
2. Open `run_lap.m` and press **Run**: prints the lap time and peak g, saves plots to `results/`.
3. Open `run_sensitivity.m` and press **Run**: parameter sensitivities plus a 21 × 21
   downforce/drag map (441 laps).
4. Open `run_validation.m` and press **Run**: downloads Verstappen's 2025 Silverstone pole
   lap from the free [OpenF1 API](https://openf1.org/docs/) (first run needs internet; the data is
   cached in `data/telemetry/`), lines it up with the simulated lap and plots speed,
   speed difference and time delta, plus a table of corner minimum speeds.

Change the car in `cars/car_f1_2025.m`. Change the track at the top of `run_lap.m`
(Silverstone and Monza racing lines are in `data/tracks/`).

## How it works

| Step | File | What happens |
|---|---|---|
| 1 | `src/load_track.m` | Spline through the racing line, resample every 1 m, curvature κ = 1/R, 5 m Gaussian filter |
| 2 | `src/apex_speed.m` | Fastest cornering speed at each point: v²·abs(κ) = μ·(g + ρ·CL·A·v²/2m) |
| 3 | `src/simulate_lap.m` | Forward pass (accelerate: grip or power, minus drag) and backward pass (brake), friction ellipse shares grip between cornering and accelerating |
| 4 | `src/simulate_lap.m` | Speed = min(apex, forward, backward); lap time = Σ 2Δs / (vᵢ + vᵢ₊₁) |
| 5 | `src/get_openf1_lap.m`, `src/compare_to_telemetry.m` | Real lap from OpenF1, distance by integrating speed, both laps lined up by best speed-trace match |

## Known limitations (next steps)

- Point mass: no load transfer, no tyre load sensitivity, so peak g is too high
  (about 6.9 g cornering, 7.5 g braking).
- The curvature filter width changes the lap by about 3 s between 0 and 10 m; it must be fixed with a reason.
- Constant aero (no ride height, no DRS), no gears.
- Real F1 speed data comes at about 3.7 samples per second, so real corner minimum speeds can read slightly high.

## Data

Racing lines from the [TUMFTM racetrack-database](https://github.com/TUMFTM/racetrack-database)
(LGPL-3.0, see `data/tracks/LICENSE_racetrack-database`).
