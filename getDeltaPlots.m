% getDeltaPlots.m

% gets a plot of the delta thickness for all of the stakes. When new stakes
% are introduced, pins the new stake to the history of stakes with current
% similar thickness

% Ian Raphael
% ian.th@dartmouth.edu
% 2021.04.24

close all
clear


cd("/Users/"+getenv('USER')+"/Desktop/Stakes")

addpath(genpath(pwd));

getThickness;

load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat");

titleFontSize = 20;
subtitleFontSize = 16;
labelFontSize = 14;
legendFontSize = 12;

indivStakes = unique(allStakes.stakeID,'stable');
indivSites = unique(allStakes.siteName,'stable');

% get a figure
figure
hold on

% for every stake
for i = 1:length(indivStakes)
    
    % get the installation date
    holdDate = allStakes.dateInstalled(allStakes.stakeID == indivStakes(i));
    currInstallDate = holdDate(1);
    
    % if its installation date is after threshold date
    if currInstallDate >= thresholdDate
        
        % get its initial thickness
        holdThickness = allStakes.thickness(allStakes.stakeID == indivStakes(i));
        currInitialThick = holdThickness(1);
        
        % find stakes of a similar thickness in a similar measurement window
        measurementDateWindow = [currInstallDate-3 currInstallDate+3];
        
    end
    
    plot(allStakes.measurementDate(find(allStakes.stakeID == indivStakes(i))),allStakes.cumulativeThicknessChange(find(allStakes.stakeID == indivStakes(i))),'-o')
end

title('Normalized ice bottom measurement for all stakes');
ylabel('Ice bottom measurement (cm)')
xlabel('Date')
