function lap = get_openf1_lap(year, circuit, session_name, driver, cache_dir)
%GET_OPENF1_LAP  A driver's fastest lap in a session, from the free OpenF1 API.
%
%   lap = get_openf1_lap(2025, 'Silverstone', 'Qualifying', 1)
%
%   Downloads (once) the session list, the driver's laps and the car's speed
%   data from https://api.openf1.org, caches them as JSON in data/telemetry/,
%   picks the fastest lap and returns its speed trace:
%     lap.t       time since the start of the lap [s]   (about 3.7 samples/s)
%     lap.v_kmh   speed [km/h]
%     lap.lap_time, lap.lap_number, lap.session_key, lap.driver
%   Delete the cached files to download again.

if nargin < 5, cache_dir = fullfile('data', 'telemetry'); end
if ~exist(cache_dir, 'dir'), mkdir(cache_dir); end
base = 'https://api.openf1.org/v1/';

% ---- 1) Which session? ----
file = fullfile(cache_dir, sprintf('sessions_%d_%s_%s.json', year, circuit, ...
                strrep(session_name, ' ', '_')));
fetch_once(sprintf('%ssessions?year=%d&circuit_short_name=%s&session_name=%s', ...
           base, year, url_word(circuit), url_word(session_name)), file);
S = as_cell(jsondecode(fileread(file)));
if isempty(S)
    error('get_openf1_lap:session', 'No %d %s %s session found on OpenF1.', ...
          year, circuit, session_name);
end
session_key = S{1}.session_key;

% ---- 2) The driver's laps: pick the fastest ----
file = fullfile(cache_dir, sprintf('laps_%d_driver%d.json', session_key, driver));
fetch_once(sprintf('%slaps?session_key=%d&driver_number=%d', base, session_key, driver), file);
L = as_cell(jsondecode(fileread(file)));
dur = cellfun(@(r) num_or_nan(r, 'lap_duration'), L);
[lap_time, k] = min(dur);                 % min() skips NaN
if isnan(lap_time) || isempty(L{k}.date_start)
    error('get_openf1_lap:laps', 'No timed lap found for driver %d.', driver);
end
t0 = openf1_seconds(L{k}.date_start);

% ---- 3) Speed samples for the whole session, then cut out that lap ----
file = fullfile(cache_dir, sprintf('car_data_%d_driver%d.json', session_key, driver));
fetch_once(sprintf('%scar_data?session_key=%d&driver_number=%d', base, session_key, driver), file);
D = as_cell(jsondecode(fileread(file)));
t = openf1_seconds(cellfun(@(r) r.date, D, 'UniformOutput', false));
v = cellfun(@(r) num_or_nan(r, 'speed'), D);

keep = t >= t0 - 2 & t <= t0 + lap_time + 2 & ~isnan(v);   % 2 s margin each end
[ts, iu] = unique(t(keep) - t0);          % sorted, no repeated time stamps
vs = v(keep);
vs = vs(iu);

lap = struct('t', ts(:), 'v_kmh', vs(:), 'lap_time', lap_time, ...
             'lap_number', L{k}.lap_number, 'session_key', session_key, 'driver', driver);
fprintf('OpenF1: session %d, driver %d, lap %d, %s, %d speed samples\n', ...
        session_key, driver, lap.lap_number, fmt_laptime(lap_time), sum(ts >= 0 & ts <= lap_time));
end

% -------------------------------------------------------------------------
function fetch_once(url, file)
if exist(file, 'file'), return; end
fprintf('Downloading %s\n', url);
if exist('OCTAVE_VERSION', 'builtin')
    urlwrite(url, file);
else
    websave(file, url, weboptions('Timeout', 120));
end
pause(0.5);                               % stay under OpenF1's rate limit
end

function s = url_word(s)
s = strrep(s, ' ', '%20');
end

function c = as_cell(x)
% jsondecode gives a struct array when every record has the same fields,
% and a cell array of structs when they differ. Make it always a cell.
if isempty(x)
    c = {};
elseif isstruct(x)
    c = num2cell(x(:));
else
    c = x(:);
end
end

function x = num_or_nan(r, name)
if isfield(r, name) && isnumeric(r.(name)) && ~isempty(r.(name))
    x = double(r.(name));
else
    x = NaN;
end
end
