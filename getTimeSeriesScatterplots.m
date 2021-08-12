% getTimeSeriesScatterplots.m

% gets various scatterplots of _all_ individual stakes times series,
% plotted by stakes site.

% Ian Raphael
% ian.th@dartmouth.edu
% Sometime in November 2020

close all
clear


cd("/Users/"+getenv('USER')+"/Desktop/Stakes")

addpath(genpath(pwd));

getThickness;

load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")

iceTypePlots = false; % get plots by ice type
sitePlots = false; % get plots by stakes site
allStakesPlots = true; % get plots for all stakes

titleFontSize = 24;
subtitleFontSize = 16;
labelFontSize = 20;
legendFontSize = 14;
tickFontSize = 14;

indivStakes = unique(allStakes.stakeID,'stable');
indivSites = unique(allStakes.siteName,'stable');

fyiColor = 'r';
syiColor = 'b';

% get the ice type for every site
for i = 1:length(indivSites)
   holdIceAge = allStakes.iceAge(allStakes.siteName == indivSites(i));
   indivSiteIceTypes(i,1) = holdIceAge(1);
end

% get the ice type for every stake
for i = 1:length(indivStakes)
   holdIceAge = allStakes.iceAge(allStakes.stakeID == indivStakes(i));
   indivStakesIceType(i,1) = holdIceAge(1);
end


if allStakesPlots == true
    
    
    
    % scatterplot of delta thickness vs. time for all stakes
    figure
    hold on
    
    plot(NaT,nan,...
        '-o','color',fyiColor,'markerfacecolor',fyiColor,'markeredgecolor','k');
    plot(NaT,nan,...
        '-o','color',syiColor,'markerfacecolor',syiColor,'markeredgecolor','k');
    legend('FYI','SYI','fontsize',legendFontSize,'AutoUpdate','off')

    for i = 1:length(indivStakes)
        if indivStakesIceType(i) == 1
            plotColor = fyiColor;
        else
            plotColor = syiColor;
        end
        plot(allStakes.measurementDate(find(allStakes.stakeID == indivStakes(i))),...
            allStakes.cumulativeThicknessChange(find(allStakes.stakeID == indivStakes(i))),...
            '-o','color',plotColor,'markerfacecolor',plotColor,'markeredgecolor','k')
    end
    
    title('Delta thickness for all stakes','fontsize',titleFontSize,'fontweight','bold');
    ylabel('Ice thickness delta (cm)','fontsize',labelFontSize,'fontweight','bold')
    xlabel('Date','fontsize',labelFontSize,'fontweight','bold')
    
    
    % scatterplot of thickness change vs time for all stakes
    figure
    hold on
    plot(NaT,nan,...
        '-o','color',fyiColor,'markerfacecolor',fyiColor,'markeredgecolor','k');
    plot(NaT,nan,...
        '-o','color',syiColor,'markerfacecolor',syiColor,'markeredgecolor','k');
    legend('FYI','SYI','fontsize',legendFontSize,'AutoUpdate','off')
    
    for i = 1:length(indivStakes)
        
        if indivStakesIceType(i) == 1
            plotColor = fyiColor;
        else
            plotColor = syiColor;
        end
        
        plot(allStakes.measurementDate(find(allStakes.stakeID == indivStakes(i))),...
            allStakes.thickness(find(allStakes.stakeID == indivStakes(i))),...
            '-o','color',plotColor,'markerfacecolor',plotColor,'markeredgecolor','k')
    end
    title('Ice thickness for all stakes','fontsize',titleFontSize,'fontweight','bold');
    ylabel('Ice thickness measurement (cm)','fontsize',labelFontSize,'fontweight','bold')
    xlabel('Date','fontsize',labelFontSize,'fontweight','bold')
    
end


if sitePlots == true
    %% scatterplots of bottom change for every stake at each site
    % get all of the individual sites
    indivSites = unique(allStakes.siteName,'stable');
    
    % for every site
    for i = 1:length(indivSites)
        
        ax=gobjects(3,1);
        
        % get the individual stakes
        indivStakes = unique(allStakes.stakeID(allStakes.siteName == indivSites(i)));
        
        % get a figure
        figure
        t = tiledlayout(3,1);
        
        % name it after the site
        title(t,extractBefore(indivSites(i),'/'),'FontSize',titleFontSize,'FontWeight','Bold');
        % get the first tile
        nexttile;
        hold on
        
        ax(1) = gca;
        ax(1).LineStyleOrder = {'-o','-s','-^'};
        
        % for every stake
        for i2 = 1:length(indivStakes)
            
            % plot the thickness measurement
            l = plot(datenum(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2))),...
                allStakes.thickness(allStakes.stakeID==indivStakes(i2)));
            l.MarkerFaceColor = l.Color;
        end
        
        datetick('x','mmm dd');
        
        grid on
        box on
        
        % do some titling
        title('Ice thickness','FontSize',subtitleFontSize);
        ylabel('Thickness (cm)','FontSize',subtitleFontSize,'FontWeight','Bold')
        xlabel('Date','FontSize',subtitleFontSize,'FontWeight','Bold')
        legend(string(indivStakes),'FontSize',legendFontSize,'Location','eastoutside');
        
        % get the  next tile
        nexttile;
        hold on
        
        ax(2) = gca;
        ax(2).LineStyleOrder = {'-o','-s','-^'};
        
        % for every stake
        for i2 = 1:length(indivStakes)
            
            % plot the bottom measurement
            l = plot(datenum(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2))),...
                allStakes.thicknessGaugeMeasurementNormalized(allStakes.stakeID==indivStakes(i2)));
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
        
        ax(3) = gca;
        ax(3).LineStyleOrder = {'-o','-s','-^'};
        
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
        
        title('Bottom growth rate','FontSize',subtitleFontSize);
        ylabel('Rate of growth (cm d^{-1})','FontSize',labelFontSize,'FontWeight','Bold')
        xlabel('Date','FontSize',labelFontSize,'FontWeight','Bold')
        legend(string(indivStakes),'FontSize',legendFontSize,'Location','eastoutside');
        
        
        % plot a refline
        hline = plot(xlim,[0 0]);
        hline.Color = 'k';
        hline.LineWidth = 0.75;
        hline.LineStyle = '-.';
        hline.Marker = 'none';
        uistack(hline,'bottom');
        
        
        set(get(get(hline,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
        
        xlim(ax,[datenum(min(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))-5)...
            datenum(max(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))+5)]);
    end 
end


if iceTypePlots == true
    %% scatterplots of bottom change for every stake of each ice type (fyi and syi)
    
    % for each ice type
    for i = 1:2
        
        ax=gobjects(2,1);
        
        % get the individual stakes
        indivStakes = unique(allStakes.stakeID(allStakes.iceAge == i),'stable');
        
        % get a figure
        figure
        t = tiledlayout(2,1);
        
        % name it after the site
        title(t,i+"(st/nd) year ice bottom change",'FontSize',titleFontSize,'FontWeight','Bold');
        
        % get the first tile
        nexttile;
        hold on
        
        ax(1) = gca;
        ax(1).LineStyleOrder = {'-o','-s','-^'};
        
        % for every stake
        for i2 = 1:length(indivStakes)
            
            % plot the bottom measurement
            l = plot(datenum(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2))),...
                allStakes.thickness(allStakes.stakeID==indivStakes(i2)));
            l.MarkerFaceColor = l.Color;
        end
        
        datetick('x','mmm dd');
        
        grid on
        box on
        
        xlim auto
        ylim auto
        
        % do some titling
        title('Relative ice bottom position','FontSize',subtitleFontSize);
        ylabel('Position (cm)','FontSize',subtitleFontSize,'FontWeight','Bold')
        xlabel('Date','FontSize',subtitleFontSize,'FontWeight','Bold')
        % legend(string(indivStakes),'FontSize',legendFontSize,'Location','eastoutside');
        
        % get another tile
        nexttile;
        hold on
        
        ax(2) = gca;
        ax(2).LineStyleOrder = {'-o','-s','-^'};
        
        % for every stake
        for i2 = 1:length(indivStakes)
            
            % plot the bottom change rate
            l = plot(datenum(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2))),...
                allStakes.thicknessChangeRate(allStakes.stakeID==indivStakes(i2)));
            l.MarkerFaceColor = l.Color;
        end
        
        grid on
        box on
        
        datetick('x','mmm dd');
        
        title('Bottom growth/melt rate','FontSize',subtitleFontSize);
        ylabel('Rate of growth/melt (cm d^{-1})','FontSize',labelFontSize,'FontWeight','Bold')
        xlabel('Date','FontSize',labelFontSize,'FontWeight','Bold')
        % legend(string(indivStakes),'FontSize',legendFontSize,'Location','eastoutside');
        
        
        % plot a refline
        hline = plot(xlim,[0 0]);
        hline.Color = 'k';
        hline.LineWidth = 0.75;
        hline.LineStyle = '-.';
        hline.Marker = 'none';
        uistack(hline,'bottom');
        
        
        set(get(get(hline,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
        
        xlim auto
        ylim auto
    end
end


if allStakesPlots == true
    %% scatterplots of average bottom change at each site
    
    % get a figure
    figure
    hold on
    
    ax = gca;
    ax.LineStyleOrder = {'-o','-s','-^'};
    
    legendStrings = indivSites;
    
    % for every site
    for i = [1 3 6]
        
        % get the max date for the site
        maxDate = max(allStakes.dateOfLastMeasurement(allStakes.siteName==indivSites(i)));
        
        % and the min date
        minDate = min(allStakes.dateInstalled(allStakes.siteName==indivSites(i)));
        
        dateSpan = [minDate+1:1:maxDate]';
        
        % get the individual stakes
        indivStakes = unique(allStakes.stakeID(allStakes.siteName == indivSites(i)));
        
        % get matrices to hold each stake's rates
        currSiteSnowMatrix = nan(datenum(maxDate)-datenum(minDate),length(indivStakes));
        currSiteSurfMatrix = nan(datenum(maxDate)-datenum(minDate),length(indivStakes));
        currSiteBottomMatrix = nan(datenum(maxDate)-datenum(minDate),length(indivStakes));
        currSiteThicknessMatrix = nan(datenum(maxDate)-datenum(minDate),length(indivStakes));
        
        % for every stake
        for i2=1:length(indivStakes)
            
            % pull out the bottom change rates
            currStakeSnowChangeRate = allStakes.snowChangeRate(allStakes.stakeID == indivStakes(i2));
            currStakeSurfaceChangeRate = allStakes.surfaceChangeRate(allStakes.stakeID == indivStakes(i2));
            currStakeBottomChangeRate = allStakes.bottomChangeRate(allStakes.stakeID == indivStakes(i2));
            currStakeThicknessChangeRate = allStakes.thicknessChangeRate(allStakes.stakeID == indivStakes(i2));
            currStakeChangeDate = allStakes.measurementDate(allStakes.stakeID == indivStakes(i2));
            
            % then for every change rate
            for i3 = 1:length(currStakeBottomChangeRate)
                
                % for every date in the datespan
                for i4 = 1:length(dateSpan)
                    % if the date matches
                    if currStakeChangeDate(i3) == dateSpan(i4)
                        
                        % stuff the change rate in there
                        currSiteSnowMatrix(i4,i2) = currStakeSnowChangeRate(i3);
                        currSiteSurfMatrix(i4,i2) = currStakeSurfaceChangeRate(i3);
                        currSiteBottomMatrix (i4,i2) = currStakeBottomChangeRate(i3);
                        currSiteThicknessMatrix(i4,i2) = currStakeThicknessChangeRate(i3);
                    end
                end
            end
        end
        
        % TODO: better way to do this? interpolater between outliers?
        % filter outliers
        currSiteSnowMatrix = filloutliers(currSiteSnowMatrix,nan,2);
        currSiteSurfMatrix = filloutliers(currSiteSurfMatrix,nan,2);
        currSiteBottomMatrix = filloutliers(currSiteBottomMatrix,nan,2);
        currSiteThicknessMatrix = filloutliers(currSiteThicknessMatrix,nan,2);
        
        % then average across rows, omitting nans to find site average rates
        currSiteSnowChangeAvg = mean(currSiteSnowMatrix,2,'omitnan');
        currSiteSurfChangeAvg = mean(currSiteSurfMatrix,2,'omitnan');
        currSiteBottomChangeAvg = mean(currSiteBottomMatrix,2,'omitnan');
        currSiteThicknessChangeAvg = mean(currSiteThicknessMatrix,2,'omitnan');
        
        currSiteBottomChangeStd = std(currSiteBottomMatrix,0,2,'omitnan');
        
%         % then plot
%         if indivSiteIceTypes(i) == 1
%             plotColor = fyiColor;
%         else
%             plotColor = syiColor;
%         end
       
%         l = plot(datenum(dateSpan(isfinite(currSiteBottomChangeAvg))),...
%             currSiteBottomChangeAvg(isfinite(currSiteBottomChangeAvg)), plotColor);
%         
%         l = plot(datenum(dateSpan(isfinite(currSiteSurfChangeAvg))),...
%             currSiteSurfChangeAvg(isfinite(currSiteSurfChangeAvg)), plotColor);
        
        l = plot(datenum(dateSpan(isfinite(currSiteThicknessChangeAvg))),...
            currSiteThicknessChangeAvg(isfinite(currSiteThicknessChangeAvg)));
        
        if isempty(l)
            legendStrings(legendStrings == indivSites(i)) = [];
            continue
        end
        l.MarkerFaceColor = l.Color;
    end
    
    
    grid on
    box on
    
    datetick('x','mmm dd');
    
    title('Site-average thickness change rate','FontSize',titleFontSize,'FontWeight','Bold')
    ylabel('Rate of change (cm d^{-1})','FontSize',labelFontSize,'FontWeight','Bold')
    xlabel('Date','FontSize',labelFontSize,'FontWeight','Bold')
    
    legend(extractBefore(legendStrings(10:11,1),'/'),'FontSize',legendFontSize,'Location','northeastoutside');
    
    % plot a refline
    hline = refline(0,0);
    hline.Color = 'k';
    hline.LineWidth = 0.75;
    hline.LineStyle = '-.';
    hline.Marker = 'none';
    uistack(hline,'bottom');
    
    set(get(get(hline,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end