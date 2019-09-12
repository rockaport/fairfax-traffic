close all, clear all, clc
listing = dir("*.txt");

for ii = 1:length(listing)
    [t, s] = process_file(listing(ii).name);
end
