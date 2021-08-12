% meltSeasonFreshwaterProduction.m

% script for estimating meltwater production from surface and basal melt
% during MOSAiC melt season (defined here as May 15 – Aug 15)

% Ian Raphael
% ian.th@dartmouth.edu

% 2021.03.24

% clean up
close all
clear

cd("/Users/"+getenv('USER')+"/Desktop/Stakes")
addpath(genpath(pwd));

% get the data
readStakes;
getThickness;
load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")
load l2_meltWaterProduction.mat
load sheba_meltWaterProduction.mat

% set true if we want to plot by individual sites
plotBySite = true;

% define snow density
snowDensity = 0.3;

% define ice density
iceDensity = 0.9;

% define start of the melt season
meltStartDate = datetime(20200601,'ConvertFrom','yyyymmdd');

% define end of the melt season
meltEndDate = datetime(20200801,'ConvertFrom','yyyymmdd');

% get a list of the unique measurement days over the melt season
measurementDays = unique(allStakes.measurementDate(allStakes.measurementDate >= ...
    meltStartDate & allStakes.measurementDate <= meltEndDate));

% get a list of stakes
indivStakes = unique(allStakes.stakeID,'stable');

% declare matrices to hold the average change rates
holdSnowChangeRates = nan(length(measurementDays),length(indivStakes));
holdSurfChangeRates = nan(length(measurementDays),length(indivStakes));
holdBottomChangeRates = nan(length(measurementDays),length(indivStakes));
holdSiteName = strings(length(measurementDays),length(indivStakes));

% for every measurement timestep
for i = 1:length(measurementDays)
    
    % for each stake
    for i2 = 1:length(indivStakes)
        
        currStakeDates = allStakes.measurementDate(allStakes.stakeID == indivStakes(i2));
        
        % if the sample date is inside the operational date of the stake
        if isbetween(measurementDays(i),currStakeDates(1),currStakeDates(end))
            
            % retrieve the date with the smallest non-negative difference
            diffDates = currStakeDates - measurementDays(i);
            
            minDex = find(min(diffDates(diffDates>=0)) == diffDates);
            currSampleDate = currStakeDates(minDex);
            
            % now get the index in allStakes
            currSampleIndex = find(allStakes.stakeID == indivStakes(i2) & ...
                allStakes.measurementDate == currSampleDate);
            
            % and finally add all of the change rates from this stake
            
            % append to list of snow thickness change rates
            holdSnowChangeRates(i,i2) = allStakes.snowChangeRate(currSampleIndex);
            
            % append to list of surf change rates
            holdSurfChangeRates(i,i2) = allStakes.surfaceChangeRate(currSampleIndex);
            
            % append to list of bottom change rates
            holdBottomChangeRates(i,i2) = allStakes.bottomChangeRate(currSampleIndex);
            
            % also get the sitename
            holdSiteName(i,i2) = allStakes.siteName(currSampleIndex);
        end
    end 
end

% if plotting by site
if plotBySite
    
    % get a list of the sites
    indivSites = unique(holdSiteName(holdSiteName~=""),'stable');
    
    % set the iteration length
    iterationLength = length(indivSites);
    
    % preallocate for the cumulative matrices
    cumulativeSnowMelt = nan(length(measurementDays)-1,length(indivSites));
    cumulativeSurfMelt = nan(length(measurementDays)-1,length(indivSites));
    cumulativeBottomMelt = nan(length(measurementDays)-1,length(indivSites));
    
    % for each site
    for i=1:iterationLength
        
        % get a curr copy of each change rate matrix
        currSnowChangeRates = holdSnowChangeRates;
        currSurfChangeRates = holdSurfChangeRates;
        currBottomChangeRates = holdBottomChangeRates;
        
        % set all non-site values to nan
        currSnowChangeRates(holdSiteName==indivSites(i)) = nan;
        currSurfChangeRates(holdSiteName==indivSites(i)) = nan;
        currBottomChangeRates(holdSiteName==indivSites(i)) = nan;

        
        % average out the values & get std devs
        avgSnowChangeRates(:,i) = mean(currSnowChangeRates,2,'omitnan');
        stdSnowChangeRates(:,i) = std(currSnowChangeRates,0,2,'omitnan');
        
        avgSurfChangeRates(:,i) = mean(currSurfChangeRates,2,'omitnan');
        stdSurfChangeRates(:,i) = std(currSurfChangeRates,0,2,'omitnan');
        
        avgBottomChangeRates(:,i) = mean(currBottomChangeRates,2,'omitnan');
        stdBottomChangeRates(:,i) = std(currBottomChangeRates,0,2,'omitnan');
        
        % get the time series of freshwater production
        snowMeltTimeSeries(:,i) = -avgSnowChangeRates(:,i)*snowDensity;
        stdSnowTimeSeries(:,i)= snowDensity * stdSnowChangeRates(:,i);
        
        surfMeltTimeSeries(:,i) = -avgSurfChangeRates(:,i) * iceDensity;
        stdSurfTimeSeries(:,i) = iceDensity * stdSurfChangeRates(:,i);
        
        bottomMeltTimeSeries(:,i) = -avgBottomChangeRates(:,i) * iceDensity;
        stdBottomTimeSeries(:,i) = iceDensity * stdBottomChangeRates(:,i);
        
        for i2 = 2:length(measurementDays)
            cumulativeSnowMelt(i2,i) = trapz(datenum(measurementDays(1:i2)),snowMeltTimeSeries(1:i2,i));
            cumulativeSurfMelt(i2,i) = trapz(datenum(measurementDays(1:i2)),surfMeltTimeSeries(1:i2,i));
            cumulativeBottomMelt(i2,i) = trapz(datenum(measurementDays(1:i2)),bottomMeltTimeSeries(1:i2,i));
        end
        
    end
    
else
    
    % set the iteration length
    iterationLength = 1;
    
    % average out the values & get std devs
    avgSnowChangeRates = mean(holdSnowChangeRates,2,'omitnan');
    stdSnowChangeRates = std(holdSnowChangeRates,0,2,'omitnan');
    
    avgSurfChangeRates = mean(holdSurfChangeRates,2,'omitnan');
    stdSurfChangeRates = std(holdSurfChangeRates,0,2,'omitnan');
    
    avgBottomChangeRates = mean(holdBottomChangeRates,2,'omitnan');
    stdBottomChangeRates = std(holdBottomChangeRates,0,2,'omitnan');
    
    % get the time series of freshwater production
    snowMeltTimeSeries = -avgSnowChangeRates*snowDensity;
    stdSnowTimeSeries = snowDensity * stdSnowChangeRates;
    
    surfMeltTimeSeries = -avgSurfChangeRates * iceDensity;
    stdSurfTimeSeries = iceDensity * stdSurfChangeRates;
    
    bottomMeltTimeSeries = -avgBottomChangeRates * iceDensity;
    stdBottomTimeSeries = iceDensity * stdBottomChangeRates;
    
    for i = 2:length(measurementDays)
        cumulativeSnowMelt(i) = trapz(datenum(measurementDays(1:i)),snowMeltTimeSeries(1:i));
        cumulativeSurfMelt(i) = trapz(datenum(measurementDays(1:i)),surfMeltTimeSeries(1:i));
        cumulativeBottomMelt(i) = trapz(datenum(measurementDays(1:i)),bottomMeltTimeSeries(1:i));
    end
end



% define specs
snowColor = 'b';
surfaceColor = 'r';
bottomColor = 'k';
totalColor = 'm';

% now plot
figure
hold on
plot(measurementDays,snowMeltTimeSeries,...
    '-o',...
    'MarkerFaceColor',snowColor,...
    'color',snowColor,...
    'linewidth',1.25)
plot(measurementDays,surfMeltTimeSeries,...
    '-o',...
    'markerfacecolor',surfaceColor,...
    'color',surfaceColor,...
    'linewidth',1.25)
plot(measurementDays,bottomMeltTimeSeries,...
    '-o',...
    'markerfacecolor',bottomColor,...
    'color',bottomColor,...
    'linewidth',1.25)
plot(measurementDays,snowMeltTimeSeries+surfMeltTimeSeries+bottomMeltTimeSeries,...
    '-o',...
    'color',totalColor,...
    'markerfacecolor',totalColor,...
    'linewidth',1.25)
title('Time Series of Avg. Freshwater Production','fontsize',24)
ylabel('Freshwater input (cm day^{-1})','fontsize',16)
legend('Snow melt input','Ice surface melt input','Bottom melt input','Total','fontsize',14)
box on
grid on
...
    
figure
hold on
plot(measurementDays,cumulativeSnowMelt,...
    '-o',...
    'markerfacecolor',snowColor,...
    'color',snowColor,...
    'linewidth',1.25)
plot(measurementDays,cumulativeSurfMelt,...
    '-o',...
    'markerfacecolor',surfaceColor,...
    'color',surfaceColor,...
    'linewidth',1.25)
plot(measurementDays,cumulativeBottomMelt,...
    '-o',...
    'markerfacecolor',bottomColor,...
    'color',bottomColor,...
    'linewidth',1.25)
plot(measurementDays,cumulativeSnowMelt+cumulativeSurfMelt+cumulativeBottomMelt,...
    '-o',...
    'color',totalColor,...
    'markerfacecolor',totalColor,...
    'linewidth',1.25)

title('Cumulative Avg. Freshwater Production','Fontsize',16)
ylabel('Freshwater input (cm)')
legend('Snow melt input','Ice surface melt input','Bottom melt input','Total')
box on
grid on

%% plot against sheba

% for every site (or all stakes)
for i=iterationLength
    
    figure
    
    % get years diff
    diffYears = year(measurementDays) - year(sheba.date(7));
    
    t = tiledlayout(3,1);
    
    
    ax1 = nexttile;
    hold on
    % plot(measurementDays - calyears(diffYears), snowMeltTimeSeries,...
    %     '-o',...
    %     'linewidth',1.25)
    
    plot(datenum(measurementDays - calyears(diffYears)),snowMeltTimeSeries(:,i),...
        '-o',...
        'linewidth',1.25)
    
    %     'markerfacecolor','r',...
    %     'MarkerEdgeColor','k',...
    %     'color','r',...
    
    plot(datenum(sheba.date),sheba.snowMelt,...
        '-s',...
        'linewidth',1.25)
    %     'markerfacecolor','r',...
    %     'color','r',...
    %     'MarkerEdgeColor','k',...
    
    box on
    grid on
    datetick('x','mmm dd')
    legend({'Snow melt input (mosaic)','Snow melt input (sheba)'},'fontsize',14);
    
    ax2 = nexttile;
    hold on
    % plot(measurementDays - calyears(diffYears),surfMeltTimeSeries+bottomMeltTimeSeries,...
    %     '-o',...
    %     'linewidth',1.25)
    plot(datenum(measurementDays - calyears(diffYears)),surfMeltTimeSeries(:,i)+bottomMeltTimeSeries(:,i),... 
        '-o',...
        'linewidth',1.25)
    
    
    %     'MarkerEdgeColor','k',...
    %     'markerfacecolor',surfaceColor,...
    %     'color',surfaceColor,...
    
    plot(datenum(sheba.date),sheba.iceMelt,...
        '-s',...
        'linewidth',1.25)
    %     'markerfacecolor',surfaceColor,...
    %     'MarkerEdgeColor','k',...
    %     'color',surfaceColor,...
    
    box on
    grid on
    datetick('x','mmm dd')
    legend({'Ice melt input (mosaic)','Ice melt input (sheba)'},'fontsize',14);
    
    ax3 = nexttile(3);
    hold on
    % plot(measurementDays - calyears(diffYears),snowMeltTimeSeries+surfMeltTimeSeries+bottomMeltTimeSeries...
    %     ,'-o',...
    %     'linewidth',1.25)
    plot(datenum(measurementDays - calyears(diffYears)),snowMeltTimeSeries(:,i)+surfMeltTimeSeries(:,i)+bottomMeltTimeSeries(:,i),...
        '-o',...
        'linewidth',1.25)
    
    %     'color',totalColor,...
    %     'markerfacecolor',totalColor,...
    %     'MarkerEdgeColor','k',...
    
    plot(datenum(sheba.date),sheba.totalMelt,...
        '-s',...
        'linewidth',1.25)
    %     'color',totalColor,...
    %     'markerfacecolor',totalColor,...
    %     'MarkerEdgeColor','k',...
    
    box on
    grid on
    datetick('x','mmm dd')
    legend({'Total melt input (mosaic)','Total melt input (sheba)'},'fontsize',14);
    
    
    linkaxes([ax1 ax2 ax3],'xy')
    xlabel(t,'Date','fontsize',18,'Fontweight','bold')
    ylabel(t,'Freshwater input (cm day^{-1})','fontsize',18,'Fontweight','bold')
    title(ax1,'Snow')
    title(ax2,'Ice')
    title(ax3,'Total')
    title(t,'Time Series of Avg. Freshwater Production, MOSAiC vs. SHEBA','Fontsize',24,'Fontweight','bold')
    xticklabels(ax1,{})
    xticklabels(ax2,{})
    t.TileSpacing = 'compact';
    
    figure
    hold on
    plot(measurementDays - calyears(diffYears),cumulativeSnowMelt(:,i)+cumulativeSnowMelt(:,i),...
        '-o',...
        'markerfacecolor',surfaceColor,...
        'color',surfaceColor,...
        'linewidth',1.25)
    plot(measurementDays - calyears(diffYears),cumulativeBottomMelt(:,i),...
        '-o',...
        'markerfacecolor',bottomColor,...
        'color',bottomColor,...
        'linewidth',1.25)
    plot(measurementDays - calyears(diffYears),cumulativeSnowMelt(:,i)+cumulativeSurfMelt(:,i)+cumulativeBottomMelt(:,i),...
        '-o',...
        'color',totalColor,...
        'markerfacecolor',totalColor,...
        'linewidth',1.25)
    
    plot(sheba.cumDate,sheba.cumSurf,...
        '-v',...
        'markerfacecolor',surfaceColor,...
        'color',surfaceColor,...
        'linewidth',1.25)
    plot(sheba.cumDate,sheba.cumBottom,...
        '-v',...
        'markerfacecolor',bottomColor,...
        'color',bottomColor,...
        'linewidth',1.25)
    plot(sheba.cumDate,sheba.cumTotal,...
        '-v',...
        'color',totalColor,...
        'markerfacecolor',totalColor,...
        'linewidth',1.25)
    
    title('Cumulative Avg. Freshwater Production, MOSAiC vs. SHEBA','Fontsize',24)
    ylabel('Freshwater input (cm)','fontsize',18,'fontweight','bold')
    xlabel('Date','fontsize',18,'fontweight','bold')
    legend({'Surface melt input (mosaic)','Bottom melt input (mosaic)','Total (mosaic)',...
        'Surface melt input (sheba)','Bottom melt input (sheba)','Total (sheba)'},'fontsize',14)
    box on
    grid on
    datetick('x','mmm dd')
    
    %% plot against l2
    
    figure
    t = tiledlayout(3,1);
    
    ax1 = nexttile;
    hold on
    % plot(measurementDays,snowMeltTimeSeries+surfMeltTimeSeries,...
    %     '-o',...
    %     'linewidth',1.25)
    errorbar(datenum(measurementDays),snowMeltTimeSeries(:,i)+surfMeltTimeSeries(:,i),stdSnowTimeSeries(:,i)+stdSurfTimeSeries(:,i),...
        '-o',...
        'linewidth',1.25)
    
    plot(datenum(l2.date),l2.surfMelt,...
        '-^',...
        'linewidth',1.25)
    
    legend('Surface melt input (mosaic)','Surface melt input (L2)')
    box on
    grid on
    
    ax2 = nexttile;
    hold on
    % plot(measurementDays,bottomMeltTimeSeries,...
    %     '-o',...
    %     'linewidth',1.25)
    errorbar(datenum(measurementDays),bottomMeltTimeSeries(:,i),stdBottomTimeSeries(:,i),...
        '-o',...
        'linewidth',1.25)
    
    plot(datenum(l2.date),l2.bottomMelt,...
        '-^',...
        'linewidth',1.25)
    
    legend('Bottom melt input (mosaic)','Bottom melt input (L2)')
    box on
    grid on
    
    ax3 = nexttile;
    hold on
    % plot(measurementDays,snowMeltTimeSeries+surfMeltTimeSeries+bottomMeltTimeSeries,...
    %     '-o',...
    %     'linewidth',1.25)
    
    errorbar(datenum(measurementDays),snowMeltTimeSeries(:,i)+surfMeltTimeSeries(:,i)+bottomMeltTimeSeries(:,i),...
        stdSnowTimeSeries(:,i)+stdSurfTimeSeries(:,i)+stdBottomTimeSeries(:,i),...
        '-o',...
        'linewidth',1.25)
    
    plot(datenum(l2.date),l2.bottomMelt+l2.surfMelt,...
        '-^',...
        'linewidth',1.25)
    
    legend('Total melt input (mosaic)','Total melt input (L2)')
    box on
    grid on
    
    linkaxes([ax1 ax2 ax3],'xy')
    xlabel(t,'Date','fontsize',12,'Fontweight','bold')
    ylabel(t,'Freshwater input (cm day^{-1})','fontsize',12,'Fontweight','bold')
    title(ax1,'Snow')
    title(ax2,'Ice')
    title(ax3,'Total')
    title(t,"Time Series of Avg. Freshwater Production, "+indivSites(i)+" vs. L2",'Fontsize',16,'Fontweight','bold')
    xticklabels(ax1,{})
    xticklabels(ax2,{})
    t.TileSpacing = 'compact';
    % % datetick('x','mmm dd')
    % xlim auto
    % xticks(ax1,'auto')
    % xticks(ax2,'auto')
    % xticks(ax3,'auto')
    
    figure
    hold on
    plot(measurementDays,cumulativeSnowMelt(:,i)+cumulativeSnowMelt(:,i),...
        '-o',...
        'markerfacecolor',surfaceColor,...
        'color',surfaceColor,...
        'linewidth',1.25)
    plot(measurementDays,cumulativeBottomMelt(:,i),...
        '-o',...
        'markerfacecolor',bottomColor,...
        'color',bottomColor,...
        'linewidth',1.25)
    plot(measurementDays,cumulativeSnowMelt(:,i)+cumulativeSurfMelt(:,i)+cumulativeBottomMelt(:,i),...
        '-o',...
        'color',totalColor,...
        'markerfacecolor',totalColor,...
        'linewidth',1.25)
    
    plot(l2.cumDate,l2.cumSurf,...
        '-^',...
        'markerfacecolor',surfaceColor,...
        'color',surfaceColor,...
        'linewidth',1.25)
    plot(l2.cumDate,l2.cumBottom,...
        '-^',...
        'markerfacecolor',bottomColor,...
        'color',bottomColor,...
        'linewidth',1.25)
    plot(l2.date,l2.cumBottom+l2.cumSurf,...
        '-^',...
        'color',totalColor,...
        'markerfacecolor',totalColor,...
        'linewidth',1.25)
    
    title('Cumulative Avg. Freshwater Production, MOSAiC vs. L2','Fontsize',16)
    ylabel('Freshwater input (cm)')
    legend('Surface melt input (mosaic)','Bottom melt input (mosaic)','Total (mosaic)',...
        'Surface melt input (l2)','Bottom melt input (l2)','Total (l2)')
    box on
    grid on

end
