close all, clear all, clc
listing = dir("*.txt");

%for ii = 1:length(listing)
    process_file(listing(1).name)
%end

