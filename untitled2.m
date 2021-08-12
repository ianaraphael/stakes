close all

cd("/Users/"+getenv('USER')+"/Desktop/Stakes")

addpath(genpath(pwd));

getThickness;

load allStakes_timeSeries_withThicknessAndChange_20201003.mat

titleFontSize = 20;
subtitleFontSize = 16;
labelFontSize = 14;
legendFontSize = 12;


% scatterplot of bottom meas vs. time for all stakes
figure
hold on
for i = 1:length(indivStakes)
plot(allStakes.measurementDate(find(allStakes.stakeID == indivStakes(i))),allStakes.thicknessGaugeMeasurement(find(allStakes.stakeID == indivStakes(i))),'-o')
end
title('Rate of basal growth/melt for all stakes');
ylabel('Rate of change (cm d^-1)')
xlabel('Date')

%% scatterplots of bottom change for every stake at each site


% get all of the individual sites
indivSites = unique(allStakes.siteName,'stable');

% for every site
for i = 1:length(indivSites)
    
    ax=gobjects(2,1);
    
    % get the individual stakes
    indivStakes = unique(allStakes.stakeID(allStakes.siteName == indivSites(i)));
    
    % get a figure
    figure
    t = tiledlayout(2,1);
    
    % name it after the site
    title(t,extractBefore(indivSites(i),'/'),'FontSize',titleFontSize,'FontWeight','Bold');
    
    % get the first tile
    nexttile;
    hold on

    ax(1) = gca;
    ax(1).LineStyleOrder = {'-o','-s','-^'};
    
    % for every stake
    for i2 = 1:length(indivStakes)
        
        % plot the bottom measurement
        l = plot(datenum(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2))),...
            allStakes.thicknessGaugeMeasurement(allStakes.stakeID==indivStakes(i2)));
        l.MarkerFaceColor = l.Color;
    end
    
    datetick('x','mmm dd'); 
    
    grid on
    box on
    
    % do some titling
    title('Relative ice bottom position','FontSize',subtitleFontSize);
    ylabel('Position (cm)','FontSize',subtitleFontSize,'FontWeight','Bold')
    xlabel('Date','FontSize',subtitleFontSize,'FontWeight','Bold')
    legend(string(indivStakes),'FontSize',legendFontSize,'Location','eastoutside');
    
    % get another tile
    nexttile;
    hold on
    
    ax(2) = gca;
    ax(2).LineStyleOrder = {'-o','-s','-^'};
    
    % for every stake
    for i2 = 1:length(indivStakes)
        
        % plot the bottom change rate
        l = plot(datenum(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2))),...
            allStakes.bottomChangeRate(allStakes.stakeID==indivStakes(i2)));
        l.MarkerFaceColor = l.Color;
    end
    
    grid on
    box on
    
    datetick('x','mmm dd'); 
    
    title('Bottom growth/melt rate','FontSize',subtitleFontSize);
    ylabel('Rate of growth/melt (cm d^{-1})','FontSize',labelFontSize,'FontWeight','Bold')
    xlabel('Date','FontSize',labelFontSize,'FontWeight','Bold')
    legend(string(indivStakes),'FontSize',legendFontSize,'Location','eastoutside');
     
    
    % plot a refline
    hline = plot([datenum(min(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))-5)...
        datenum(max(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))+5)],[0 0]);
    hline.Color = 'k';
    hline.LineWidth = 0.75;
    hline.LineStyle = '-.';
    hline.Marker = 'none';
    uistack(hline,'bottom');
    
    
    set(get(get(hline,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    
    xlim(ax,[datenum(min(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))-5)...
        datenum(max(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))+5)]);
end

%% scatterplots of average bottom change at each site

% get a figure
figure
hold on

ax = gca;
ax.LineStyleOrder = {'-o','-s','-^'};

legendStrings = indivSites;

% for every site
for i = 1:length(indivSites)
    
    % get the max date for the site
    maxDate = max(allStakes.dateOfLastMeasurement(allStakes.siteName==indivSites(i)));
    
    % and the min date
    minDate = min(allStakes.dateInstalled(allStakes.siteName==indivSites(i)));
    
    dateSpan = [minDate+1:1:maxDate]';
    
    % get the individual stakes
    indivStakes = unique(allStakes.stakeID(allStakes.siteName == indivSites(i)));
    
    % get one matrix to hold each stake's rates
    currSiteMatrix = nan(datenum(maxDate)-datenum(minDate),length(indivStakes));
    

    
    % for every stake
    for i2=1:length(indivStakes)
        
        % pull out the bottom change rates
        currStakeChangeRate = allStakes.bottomChangeRate(allStakes.stakeID == indivStakes(i2));
        currStakeChangeDate = allStakes.measurementDate(allStakes.stakeID == indivStakes(i2));
        
        % then for every change rate
        for i3 = 1:length(currStakeChangeRate)
            
            % for every date in the datespan
            for i4 = 1:length(dateSpan)
                % if the date matches
                if currStakeChangeDate(i3) == dateSpan(i4)
                    
                    % stuff the change rate in there
                    currSiteMatrix(i4,i2) = currStakeChangeRate(i3);
                end
            end
        end
    end
    
    % TODO: better way to do this? interpolater between outliers?
    % filter outliers 
    currSiteMatrix = filloutliers(currSiteMatrix,nan,2);
    
    % then average across rows, omitting nans to find site average rates
    currSiteBottomChangeAvg = mean(currSiteMatrix,2,'omitnan');
    
    % then plot
    l = plot(datenum(dateSpan(isfinite(currSiteBottomChangeAvg))),...
        currSiteBottomChangeAvg(isfinite(currSiteBottomChangeAvg)));
    if isempty(l)
        legendStrings(legendStrings == indivSites(i)) = [];
        continue
    end
    l.MarkerFaceColor = l.Color;
end

grid on
box on

datetick('x','mmm dd');

title('Site-average bottom growth/melt rate','FontSize',titleFontSize,'FontWeight','Bold')
ylabel('Rate of growth/melt (cm d^{-1})','FontSize',labelFontSize,'FontWeight','Bold')
xlabel('Date','FontSize',labelFontSize,'FontWeight','Bold')

legend(extractBefore(legendStrings,'/'),'FontSize',legendFontSize,'Location','eastoutside');

% plot a refline
hline = refline(0,0);
hline.Color = 'k';
hline.LineWidth = 0.75;
hline.LineStyle = '-.';
hline.Marker = 'none';
uistack(hline,'bottom');

set(get(get(hline,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
