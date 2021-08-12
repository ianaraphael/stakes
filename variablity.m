% variability.m

% Plots of stakewise and sitewise variability in growth rates

% Ian Raphael
% ian.th@dartmouth.edu
% 2021.08.09

% clean up
close all
clear

% get to the right directory
cd("/Users/"+getenv('USER')+"/Desktop/Stakes")
addpath(genpath(pwd));

% load the data
getThickness;
load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")

titleFontSize = 20; % title font size
labelFontSize = 16; % axis label font size
legendFontSize = 12; % legend font size

%% plot the lifetime std deviation in growth rate for each stake at each site

% get the individual sites
indivSites = unique(allStakes.siteName,'stable');

% for every site
for i = 1:length(indivSites)
    
    % get the individual stakes from this site
    indivStakes = unique(allStakes.stakeID(allStakes.siteName == indivSites(i)),'stable');
    
    % allocate a vector
    growthStdDev = nan(length(indivStakes),1);
    
    % for every stake
    for i2 = 1:length(indivStakes)
        
        % get std dev in its growth rate and add it to the vector
        growthStdDev(i2) = std(allStakes.thicknessChangeRate(allStakes.stakeID == indivStakes(i2)), 'omitnan');
    end
    
    % get a figure
    figure
    
    % bar chart its data
    bar([1:length(indivStakes)],growthStdDev);
    xticklabels(indivStakes);
    xlabel('Stake ID',...
        'FontSize',labelFontSize,...
        'FontWeight','bold');
    ylabel('Std. deviation in growth rate (cm day^{-1})',...
        'FontSize',labelFontSize,...
        'FontWeight','bold');
    title('Stakewise std. deviation in growth rate: '+indivSites(i),...
        'FontSize',titleFontSize,...
        'FontWeight','bold',...
        'Interpreter','none');
        
end

%% plot the variability in growth rate at each site for each measurement step

% get a figure
figure
hold on

% for every site
for i = 1:length(indivSites)
    
    % get the individual measurement dates at this site
    indivDates = unique(allStakes.measurementDate(allStakes.siteName == indivSites(i)),'stable');
    
    % allocate a vector to hold the std. devs
    growthStdDev = nan(length(indivDates),1);
    
    % for every timestep
    for i2 = 1:length(indivDates)
        % get the std deviation of the growth rates of all of the stakes
        % for that measurement step
        growthStdDev(i2) = std(allStakes.thicknessChangeRate(...
            allStakes.measurementDate == indivDates(i2) & ...
            allStakes.siteName == indivSites(i)),...
            'omitnan');
    end
    
    % plot it as a time series
    l = plot(indivDates,growthStdDev,'-o');
    l.MarkerFaceColor = l.Color;
    
end

xlabel('Measurement date',...
    'FontSize',labelFontSize,...
    'FontWeight','bold');
ylabel('Std. deviation in growth rate (cm day^{-1})',...
    'FontSize',labelFontSize,...
    'FontWeight','bold');
title('Sitewise std. deviation in growth rate vs. time',...
    'FontSize',titleFontSize,...
    'FontWeight','bold');
leg = legend(indivSites,...
    'FontSize',legendFontSize);
set(leg,'Interpreter', 'none')
grid on
box on
