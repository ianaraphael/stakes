% seasonalAverageStats.m

% find statistics for growth and melt season for FYI SYI and aggregate

% Ian Raphael
% 2021.04.24

close all
clear

cd("/Users/"+getenv('USER')+"/Desktop/Stakes")

readStakes % read in the newest version of the stakes data
getThickness % recalc thickness data

load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat") % load the data

% define start of the melt season
meltStartDate = datetime(20200509,'ConvertFrom','yyyymmdd');

% define end of the melt season
meltEndDate = datetime(20200801,'ConvertFrom','yyyymmdd');

% get a list of individual stakes
indivStakes = unique(allStakes.stakeID,'stable');

% get the ice type for every stake
for i = 1:length(indivStakes)
   holdIceAge = allStakes.iceAge(allStakes.stakeID == indivStakes(i));
   indivStakesIceType(i,1) = holdIceAge(1);
end

% initIceThick = nan(length(indivStakes),1);
% initSnowThick = nan(length(indivStakes),1);
% maxSnowThick = nan(length(indivStakes),1);
% iceGrowthTotal = nan(length(indivStakes),1);
% bottomGrowthStart = NaT(length(indivStakes),1);
% bottomGrowthEnd = NaT(length(indivStakes),1);
% 
% snowMeltTotal = nan(length(indivStakes),1);
% surfMeltTotal = nan(length(indivStakes),1);
% bottomMeltTotal = nan(length(indivStakes),1);
% 
% bottomMeltStart = NaT(length(indivStakes),1);
% bottomMeltEnd = NaT(length(indivStakes),1);
% 
% surfaceMeltStart = NaT(length(indivStakes),1);
% surfaceMeltEnd = NaT(length(indivStakes),1);


% for every stake
for i = 1:length(indivStakes) 
    
    
    %% first do melt season:
    % how much has ice surface melted since initial, how much has ice
    % bottom melted since initial, and how much has thickness changed since
    % initial
    
    % get melt indices
    meltIndices = find(allStakes.stakeID == indivStakes(i) & allStakes.measurementDate...
        >= meltStartDate & allStakes.measurementDate < meltEndDate);
    
    if (length(meltIndices) > 1) & (nnz(~isnan(allStakes.iceSurfaceMeasurementNormalized(meltIndices))) > 1)
        
        % get the first index of the first ice surface change
        [~, surfMeltStartIndex] = find(allStakes.iceSurfaceMeasurementNormalized(meltIndices)<0,1,'first');
        
        surfMeltStart(i) = emptyArrayToNat(allStakes.measurementDate(meltIndices(surfMeltStartIndex)));
        
        % get the minimum following surface value
        [minIceSurf,surfMeltEndIndex] = min(allStakes.iceSurfaceMeasurementNormalized(meltIndices(surfMeltStartIndex:end)));
        
        surfMeltTotal(i) = abs(emptyArrayToNan(minIceSurf));
        
        % and the melt end date
        surfMeltEnd(i) = emptyArrayToNat(allStakes.measurementDate(meltIndices(surfMeltEndIndex)));
        
        % get the initial melt season ice bottom date
        bottomMeltStart(i) = allStakes.measurementDate(meltIndices(1));
        
        % and value
        initIceBottom = abs(allStakes.thicknessGaugeMeasurementNormalized(meltIndices(1)));
        
        % and the minimum
        [minIceBottom, bottomMeltEndIndex]= min(abs(allStakes.thicknessGaugeMeasurementNormalized(meltIndices)));
        
        % bottom melt end date
        bottomMeltEnd(i) = allStakes.measurementDate(meltIndices(bottomMeltEndIndex));
        
        % get the difference between the two
        bottomMeltTotal(i) = initIceBottom - minIceBottom;
        
        % now get the melt start
        meltStart(i) = allStakes.measurementDate(meltIndices(1));
        
        % the initial ice thickness
        initIceThick = allStakes.thickness(meltIndices(1));
        
        % minimum ice thickness
        [minIceThick, minIceThickIndex] = min(allStakes.thickness(meltIndices));
        
        % get the difference
        totalMelt(i) = initIceThick - minIceThick;
        
        % and the melt end date
        meltEnd(i) = allStakes.measurementDate(meltIndices(minIceThickIndex));
        
        surfMeltPeriod(i) = surfMeltEnd(i) - surfMeltStart(i);
        bottomMeltPeriod(i) = bottomMeltEnd(i)-bottomMeltStart(i);
        meltPeriod(i) = meltEnd(i) - meltStart(i);
        
    else
        surfMeltTotal(i) = nan;
        bottomMeltTotal(i) = nan;
        totalMelt(i) = nan;
        
        surfMeltPeriod(i) = NaT-NaT;
        bottomMeltPeriod(i) = NaT-NaT;
        meltPeriod(i) = NaT-NaT;
        
        bottomMeltStart(i) = NaT;
        bottomMeltEnd(i) = NaT;
        surfMeltStart(i) = NaT;
        surfMeltEnd(i) = NaT;
        meltStart(i) = NaT;
        meltEnd(i) = NaT;
    end
    
    
    %% Now do growth season
    % how much did the the ice change over the growth period
    
    % get the growth indices
    growthIndices = find(allStakes.stakeID == indivStakes(i) & allStakes.measurementDate < meltStartDate);
    if length(growthIndices)>1
        % get the start date
        [growthStart(i),growthStartIndex] = min(allStakes.measurementDate(growthIndices));
        
        % get the initial thickness
        initIceThick = allStakes.thickness(growthIndices(growthStartIndex));
        
        % get the maximum ice thickness
        [maxIceThick, maxIceThickIndex] = max(allStakes.thickness(growthIndices));
        
        % and the date of max ice thickness
        growthEnd(i) = allStakes.measurementDate(growthIndices(maxIceThickIndex));
        
        % get the difference
        iceGrowthTotal(i) = maxIceThick - initIceThick;
        growthPeriod(i) = growthEnd(i) - growthStart(i);
        
    else
        
        iceGrowthTotal(i) = 0;
        growthPeriod(i) = NaT-NaT;
        growthStart(i) = NaT;
        growthEnd(i) = NaT;
    end
end

% growth season
% for both ice types
for i=1:2
    
    % get a list of stakes of that ice type
    currStakes = unique(allStakes.stakeID(allStakes.iceAge == i),'stable');
    
    % for every stake of that ice type
    for i2 = 1:length(currStakes)
        
        % get its peak delta growth
        currIceGrowth = iceGrowthTotal(currStakes(i2)==indivStakes);
        currGrowthPeriod = datenum(growthPeriod(currStakes(i2)==indivStakes));
        
%         % get its growth period
%         currGrowthPeriod = datenum(growthEnd(currStakes(i2)==indivStakes)) -...
%             datenum(growthStart(currStakes(i2)==indivStakes));
        
        % find the average growth rate and add it to the array of growth rates for this ice type
        change(i).growthRates(i2) = currIceGrowth/currGrowthPeriod;
    end
    
    % get stats of the array
    change(i).meanGrowthRate = mean(change(i).growthRates,'omitnan');
    change(i).medGrowthRate = median(change(i).growthRates,'omitnan');
    change(i).stdGrowthRate = std(change(i).growthRates,'omitnan');
end

% melt season
% for both ice types
for i=1:2
    
    % get a list of stakes of that ice type
    currStakes = unique(allStakes.stakeID(allStakes.iceAge == i),'stable');
    
    % for every stake of that ice type
    for i2 = 1:length(currStakes)
        
        % get its peak delta melt
        currSurfMelt = surfMeltTotal(currStakes(i2)==indivStakes);
        currBottomMelt = bottomMeltTotal(currStakes(i2)==indivStakes);
        currTotalMelt = totalMelt(currStakes(i2)==indivStakes);
        
        currBottomMeltPeriod = datenum(bottomMeltPeriod(currStakes(i2)==indivStakes));
        currSurfMeltPeriod = datenum(surfMeltPeriod(currStakes(i2)==indivStakes));
        currMeltPeriod = datenum(meltPeriod(currStakes(i2)==indivStakes));
        
%         % get its bottom and surf melt periods
%         currBottomMeltPeriod = datenum(bottomMeltEnd(currStakes(i2)==indivStakes)) -...
%             datenum(bottomMeltStart(currStakes(i2)==indivStakes));
%         
%         currSurfMeltPeriod = datenum(surfMeltEnd(currStakes(i2)==indivStakes)) -...
%             datenum(surfMeltStart(currStakes(i2)==indivStakes));

        
        % find the average melt rate and add it to the array of melt rates for this ice type
        change(i).bottomMeltRate(i2) = currBottomMelt/currBottomMeltPeriod;
        change(i).totalMeltRate(i2) = currTotalMelt/currMeltPeriod;
        
        if ~isempty(currSurfMeltPeriod)
            change(i).surfMeltRate(i2) = currSurfMelt/currSurfMeltPeriod;
        else
            change(i).surfMeltRate(i2) = nan;
        end
    end
    
    % get stats of the array
    change(i).meanSurfMeltRate = mean(change(i).surfMeltRate,'omitnan');
    change(i).medSurfMeltRate = median(change(i).surfMeltRate,'omitnan');
    change(i).stdSurfMeltRate = std(change(i).surfMeltRate,'omitnan');

    change(i).meanBottomMeltRate = mean(change(i).bottomMeltRate,'omitnan');
    change(i).medBottomMeltRate = median(change(i).bottomMeltRate,'omitnan');
    change(i).stdBottomMeltRate = std(change(i).bottomMeltRate,'omitnan');
    
    change(i).meanTotalMeltRate = mean(change(i).totalMeltRate,'omitnan');
    change(i).medTotalMeltRate = median(change(i).totalMeltRate,'omitnan');
    change(i).stdTotalMeltRate = std(change(i).totalMeltRate,'omitnan');
    
end

%% plot stuff up

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
    
    
    if contains(allStakes.siteName(indivStakes(i)==allStakes.stakeID),"_14")
        continue
    end
    
    plot(allStakes.measurementDate(find(allStakes.stakeID == indivStakes(i))),...
        allStakes.cumulativeThicknessChange(find(allStakes.stakeID == indivStakes(i))),...
        '-o','color',plotColor,'markerfacecolor',plotColor,'markeredgecolor','k');
end

ax = gca;
ax.FontSize = tickFontSize;
title('Cumulative ice thickness change for all stakes','fontsize',titleFontSize,'fontweight','b');
ylabel('Ice thickness change (cm)','fontsize',labelFontSize,'fontweight','b')
xlabel('Date','fontsize',labelFontSize,'fontweight','b')
box on
grid on


figure
hold on

plot(NaT,nan,...
    '-o','color',fyiColor,'markerfacecolor',fyiColor,'markeredgecolor','k');
plot(NaT,nan,...
    '-o','color',syiColor,'markerfacecolor',syiColor,'markeredgecolor','k');
legend('FYI','SYI','fontsize',legendFontSize,'AutoUpdate','off')

% now with linear change rates on top
for i = 1:length(indivStakes)
    if indivStakesIceType(i) == 1
        plotColor = fyiColor;
    else
        plotColor = syiColor;
    end
%     plot(allStakes.measurementDate(find(allStakes.stakeID == indivStakes(i))),...
%         allStakes.cumulativeThicknessChange(find(allStakes.stakeID == indivStakes(i))),...
%         '-o','color',[0.2 0.2 0.2],'markerfacecolor',[0.2 0.2 0.2],'markeredgecolor',[0.3 0.3 0.3])
    
    l1 = plot([growthStart(i) growthEnd(i)],[0 iceGrowthTotal(i)],...
        '-o','color',plotColor,'markerfacecolor',plotColor,'markeredgecolor','k');
    l2 = plot([meltStart(i) meltEnd(i)],[iceGrowthTotal(i) iceGrowthTotal(i)-totalMelt(i)],...
        '-o','color',plotColor,'markerfacecolor',plotColor,'markeredgecolor','k');
    
        
    if indivStakesIceType(i) == 1
        uistack(l1,'top')
        uistack(l2,'top')
    else
        uistack(l1,'bottom')
        uistack(l2,'bottom')
    end
    
end

p1 = fill([min(xlim) meltStartDate meltStartDate min(xlim)], ...
    [max(ylim) max(ylim) min(ylim) min(ylim)], [246/255 255/255 255/255]);
p2 = fill([meltStartDate max(xlim) max(xlim) meltStartDate], ...
    [max(ylim) max(ylim) min(ylim) min(ylim)], [255/255 255/255 241/255]);

uistack(p1,'bottom')
uistack(p2,'bottom')

ax = gca;
ax.FontSize = tickFontSize;
title('Season-wise interpolation for all stakes','fontsize',titleFontSize,'fontweight','b');
ylabel('Ice thickness change (cm)','fontsize',labelFontSize,'fontweight','b')
xlabel('Date','fontsize',labelFontSize,'fontweight','b')
box on
grid on


%% function definitions

% define a function to convert an empty array to a nan value
function ret = emptyArrayToNan(x)

% if the array is empty
if isempty(x)
    % set x = nan
    ret = nan;
else
    ret = x;
end
end

function ret = emptyArrayToNat(x)

% if the array is empty
if isempty(x)
    % set x = nan
    ret = NaT;
else
    ret = x;
end
end

