function [t, s] = process_file(filename)
speedLimit = 25;
recklessLimit = speedLimit + 15;

mkdir('figures')

fprintf('processing file: %s ...\n', filename);

data = readtable(filename);
data = data(data{:, 4} ~= 0, :);

t = datetime(data{:,2}, 'InputFormat', 'yyyy/M/dd') + data{:,3};
s = data{:, 5};
samples = length(t);

% cdf
uniqueSpeed = sort(unique(s));
cdf = zeros(size(uniqueSpeed));

for ii = 1:length(cdf)
    cdf(ii) = sum(s <= uniqueSpeed(ii));
end
cdf = cdf./length(s);

[~, speedLimitIdx] = min(abs(uniqueSpeed - speedLimit));
speedLimitPercentile = cdf(speedLimitIdx);
[~, recklessImitIdx] = min(abs(uniqueSpeed - recklessLimit));
recklessLimitPercentile = cdf(recklessImitIdx);

percentiles = sort([speedLimitPercentile 0.5 0.75 recklessLimitPercentile]);
n = length(percentiles);
percentileSpeeds = zeros(n, 5);
percentileSpeeds(:, 2) = percentiles;
percentileSpeeds(:, 3) = round(samples * percentiles);
percentileSpeeds(:, 4) = 1 - percentiles;
percentileSpeeds(:, 5) = round(samples * (1 - percentiles));

hsvColors = rgb2hsv([0 1 0; 1 0 0]);
colors = zeros(n, 3);
colors(:, 1) = interp1([0 1], hsvColors(:, 1), linspace(0, 1, n));
colors(:, 2) = interp1([0 1], hsvColors(:, 2), linspace(0, 1, n));
colors(:, 3) = interp1([0 1], hsvColors(:, 3), linspace(0, 1, n));
colors = hsv2rgb(colors);

figure, plot(cdf), axis('tight'), grid on, xlim([0 65])
title(sprintf('CDF (%d)\n%s', samples, filename))
ylabel('% of Data'), xlabel('Speed (MPH)')

for ii = 1:length(percentiles)
    percentile = percentiles(ii);
    
    [~, idx] = min(abs(cdf - percentile));
    mph = uniqueSpeed(idx);
    percentileSpeeds(ii, 1) = mph;
    
    yline(percentile, '--', ...
        'color', colors(ii, :), ...
        'linewidth', 2, ...
        'label', sprintf('%.0f%% (%d MPH)', 100*percentile, mph));
end

set(gcf, 'paperunits', 'inches');
set(gcf, 'paperposition', [0 0 6 6]);
print(sprintf('./figures/cdf-%s.png', filename), '-dpng', '-r0');

percentileSpeeds

% pdf
[n, edges] = histcounts(s, 'normalization', 'pdf');
edges = edges(2:end) - mean(diff(edges));

figure, plot(edges, n), grid on, xlim([0 65])
title(sprintf('PDF (%d)\n%s', samples, filename))
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

set(gcf, 'paperunits', 'inches');
set(gcf, 'paperposition', [0 0 6 6]);
print(sprintf('./figures/pdf-%s.png', filename), '-dpng', '-r0');

% time series
percentiles = sort([0 speedLimitPercentile 0.5 0.75 recklessLimitPercentile 1.0]);
n = length(percentiles) - 1;
colors = zeros(n, 3);
colors(:, 1) = interp1([0 1], hsvColors(:, 1), linspace(0, 1, n));
colors(:, 2) = interp1([0 1], hsvColors(:, 2), linspace(0, 1, n));
colors(:, 3) = interp1([0 1], hsvColors(:, 3), linspace(0, 1, n));
colors = hsv2rgb(colors);

figure
for ii = 1:length(percentiles)-1
    percentile = percentiles(ii);
    [~, idx] = min(abs(cdf - percentile));
    lowerMph = uniqueSpeed(idx);
    
    percentile = percentiles(ii + 1);
    [~, idx] = min(abs(cdf - percentile));
    upperMph = uniqueSpeed(idx);
    
    idx = ((s > lowerMph) & (s <= upperMph));
    
    plot(t(idx), s(idx), 'o', ...
        'color', colors(ii, :), ...
        'markerfacecolor', colors(ii, :), ...
        'markersize', 6), hold on,
    
    yline(upperMph, '--', ...
        'color', [0.5 0.5 0.5], ...
        'linewidth', 1, ...
        'label', sprintf('%.0f%% (%.0f MPH)', 100*percentile, upperMph));
end

grid on, datetick('x', 'HHPM')
title(sprintf('Time Series (%d)\n%s', samples, filename))
ylabel('Speed (MPH)'), xlabel('Time')

tinterval = 0.5*hours(1);
tt = dateshift(min(t), 'start', 'hour'):tinterval:dateshift(max(t), 'end', 'hour');
ss = zeros(size(tt));
vs = zeros(size(tt));

for ii = 1:length(tt)
    tmin = tt(ii) - tinterval;
    tmax = tt(ii) + tinterval;
    
    idx = ((t >= tmin) & (t <= tmax));
    speeds = s(idx);
    ss(ii) = mean(speeds);
    vs(ii) = length(speeds);
end

ss(isnan(ss)) = 0;
vs(isnan(vs)) = 0;

plot(tt, ss, 'linewidth', 2)
ylim([0 70])

yyaxis right
plot(tt, vs, 'linewidth', 2)
ylabel('Car Count')

h = findobj(gca, 'type', 'line');
legend([h(2) h(1)], 'Average Speed', 'Average Volume', 'location', 'north')

set(gcf, 'paperunits', 'inches');
set(gcf, 'paperposition', [0 0 16 10]);
print(sprintf('./figures/ts-%s.png', filename), '-dpng', '-r0');
