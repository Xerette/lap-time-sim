function track = load_track(csv_path, name, ds, smooth_m)
%LOAD_TRACK  Load a closed racing line and compute its curvature.
%
%   track = load_track(csv_path, name, ds, smooth_m)
%
%   csv_path : CSV file whose first two columns are x and y in metres
%   name     : track name, used in plot titles
%   ds       : spacing to resample the line to [m]            (default 1)
%   smooth_m : width [m] of the Gaussian filter on curvature  (default 5)
%
%   The lap sim never needs x and y directly. All it needs is the curvature
%   kappa = 1/R at every metre: zero on a straight, large in a hairpin.
%   Sign: + = left turn, - = right turn.
%
%   Uses base MATLAB only (spline, ppval, mkpp, conv): no toolboxes needed.

if nargin < 3, ds = 1.0; end
if nargin < 4, smooth_m = 5.0; end

% ---- Read x, y (lines starting with # are comments) ----
fid = fopen(csv_path, 'r');
if fid < 0
    error('load_track:file', 'Cannot open %s', csv_path);
end
C = textscan(fid, '%f %f %*[^\n]', 'Delimiter', ',', 'CommentStyle', '#');
fclose(fid);
xy = [C{1}, C{2}];
if norm(xy(1,:) - xy(end,:)) < 1e-6   % drop a repeated closing point
    xy(end,:) = [];
end
n = size(xy, 1);

% ---- Cubic spline through the points ----
% Copy a few points from each end onto the other, so the spline behaves as
% if the loop were closed (no kink at the start/finish line).
pad = 10;
xyp = [xy(end-pad+1:end, :); xy; xy(1:pad+1, :)];
u = [0; cumsum(sqrt(sum(diff(xyp).^2, 2)))];   % chord-length parameter
u_start = u(pad+1);                              % original point 1
u_end   = u(pad+n+1);                            % back at point 1 again

ppx = spline(u, xyp(:,1));    dppx = pp_deriv(ppx);   ddppx = pp_deriv(dppx);
ppy = spline(u, xyp(:,2));    dppy = pp_deriv(ppy);   ddppy = pp_deriv(dppy);

% ---- Resample at an even spacing ds along the true arc length ----
uf = linspace(u_start, u_end, 20*n + 1)';
xf = ppval(ppx, uf);  yf = ppval(ppy, uf);
sf = [0; cumsum(hypot(diff(xf), diff(yf)))];
total = sf(end);
m  = round(total / ds);
ds = total / m;
s  = (0:m-1)' * ds;
ui = interp1(sf, uf, s);

x   = ppval(ppx, ui);    y   = ppval(ppy, ui);
dx  = ppval(dppx, ui);   dy  = ppval(dppy, ui);
ddx = ppval(ddppx, ui);  ddy = ppval(ddppy, ui);

% Curvature of a parametric curve
kappa = (dx .* ddy - dy .* ddx) ./ (dx.^2 + dy.^2).^1.5;

% Taking two derivatives of measured x/y turns small wobbles in the data
% into fake curvature spikes. A few metres of filtering removes them.
if smooth_m > 0
    kappa = circular_gauss(kappa, smooth_m / ds);
end

track = struct('name', name, 's', s, 'x', x, 'y', y, ...
               'kappa', kappa, 'ds', ds, 'length', total);
end

% -------------------------------------------------------------------------
function ppd = pp_deriv(pp)
% Derivative of a piecewise polynomial (base-MATLAB version of fnder)
[breaks, coefs, ~, k, d] = unmkpp(pp);
powers = repmat(k-1:-1:1, size(coefs, 1), 1);
ppd = mkpp(breaks, coefs(:, 1:k-1) .* powers, d);
end

function out = circular_gauss(v, sigma)
% Gaussian filter that wraps around, because the lap is a closed loop
h = ceil(4 * sigma);
k = (-h:h)';
g = exp(-0.5 * (k / sigma).^2);
g = g / sum(g);
vp = [v(end-h+1:end); v; v(1:h)];
out = conv(vp, g, 'valid');
end
