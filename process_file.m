function [output] = process_file(filename)
speedLimit = 25;

fprintf('processing file: %s ...\n', filename);

data = readtable(filename);
data = data(data{:, 4} ~= 0, :);

t = datetime(data{:,2}, 'InputFormat', 'yyyy/M/dd') + data{:,3};
s = data{:, 5};

% cdf
uniqueSpeed = sort(unique(s));
cdf = zeros(size(uniqueSpeed));

for ii = 1:length(cdf)
    cdf(ii) = sum(s <= uniqueSpeed(ii));
end
cdf = cdf./length(s);

[~, speedLimitIdx] = min(abs(uniqueSpeed - speedLimit));
speedLimitPercentile = cdf(speedLimitIdx);

percentiles = sort([speedLimitPercentile 0.5 0.75 0.9]);
n = length(percentiles);

hsvColors = rgb2hsv([0 1 0; 1 0 0]);
colors = zeros(n, 3);
colors(:, 1) = interp1([0 1], hsvColors(:, 1), linspace(0, 1, n));
colors(:, 2) = interp1([0 1], hsvColors(:, 2), linspace(0, 1, n));
colors(:, 3) = interp1([0 1], hsvColors(:, 3), linspace(0, 1, n));
colors = hsv2rgb(colors);

figure, plot(cdf), axis('square'), grid on
title(sprintf('CDF\n%s', filename))
ylabel('% of Data'), xlabel('Speed (MPH)')

for ii = 1:length(percentiles)
    percentile = percentiles(ii);

    [~, idx] = min(abs(cdf - percentile));
    mph = uniqueSpeed(idx);

    yline(percentile, '--', ...
        'color', colors(ii, :), ...
        'linewidth', 2, ...
        'label', sprintf('%.0f%% (%d MPH)', 100*percentile, mph));
end

% pdf
[n, edges] = histcounts(s, 'normalization', 'pdf');
edges = edges(2:end) - mean(diff(edges));

figure, plot(edges, n), grid on
title(sprintf('PDF\n%s', filename))
ylabel('% of Data'), xlabel('Speed (MPH)')

stdevs = sort([25 mean(s) + std(s) * (0:3)]);

n = length(stdevs);
colors = zeros(n, 3);
colors(:, 1) = interp1([0 1], hsvColors(:, 1), linspace(0, 1, n));
colors(:, 2) = interp1([0 1], hsvColors(:, 2), linspace(0, 1, n));
colors(:, 3) = interp1([0 1], hsvColors(:, 3), linspace(0, 1, n));
colors = hsv2rgb(colors);

for ii = 1:length(stdevs)
    mph = stdevs(ii);

    xline(mph, '--', ...
        'color', colors(ii, :), ...
        'linewidth', 2, ...
        'label', sprintf('%.0f MPH', mph));
end

% time series
close all

percentiles = sort([0 speedLimitPercentile 0.5 0.75 0.9 1.0]);
n = length(percentiles) - 1;
colors = zeros(n, 3);
colors(:, 1) = interp1([0 1], hsvColors(:, 1), linspace(0, 1, n));
colors(:, 2) = interp1([0 1], hsvColors(:, 2), linspace(0, 1, n));
colors(:, 3) = interp1([0 1], hsvColors(:, 3), linspace(0, 1, n));
colors = hsv2rgb(colors);

for ii = 2:length(percentiles)
    percentile = percentiles(ii - 1);
    [~, idx] = min(abs(cdf - percentile));
    lowerMph = uniqueSpeed(idx);

    percentile = percentiles(ii);
    [~, idx] = min(abs(cdf - percentile));
    upperMph = uniqueSpeed(idx);

    idx = ((s > lowerMph) & (s <= upperMph));
    plot(t(idx), s(idx), 'o', ...
        'color', colors(ii - 1, :), ...
        'markerfacecolor', colors(ii - 1, :), ...
        'markersize', 6)
    hold on
end

%figure, plot(t, s, 'o'), datetick('x', 'HHPM')