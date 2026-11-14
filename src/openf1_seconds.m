function sec = openf1_seconds(dates)
%OPENF1_SECONDS  OpenF1 time stamps -> seconds since midnight (UTC).
%   '2025-07-05T15:09:28.589000+00:00'  ->  54568.589
%   Accepts one string or a cell array of strings.
if ischar(dates), dates = {dates}; end
tok = regexp(dates, 'T(\d+):(\d+):(\d+(\.\d+)?)', 'tokens', 'once');
sec = cellfun(@(c) str2double(c{1}) * 3600 + str2double(c{2}) * 60 + str2double(c{3}), tok);
sec = sec(:);
end
