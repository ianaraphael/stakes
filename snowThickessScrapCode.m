% tooling around with plotting snow thickness time series

indivMeasDates = unique(allStakes.measurementDate);

for i = 1:length(indivMeasDates)
    
    meanSnow(i) = mean(allStakes.snowThickness(allStakes.measurementDate == indivMeasDates(i)),'omitnan'); 
end

figure
hold on

plot(indivMeasDates,meanSnow)

box on
grid on

 %% scatterplots of average snow thickness at each site
    
    % get a figure
    figure
    hold on
    
    ax = gca;
    ax.LineStyleOrder = {'-o','-s','-^'};
    
    legendStrings = indivSites;
    
    % for every site
    for i = [1 3 6]
        
        meanSnowThick = [];
        stdSnowThick = [];
        
        % get its measurement dates
        measDates = unique(allStakes.measurementDate(allStakes.siteName == indivSites(i)));
        
        % get the mean snow thickness for each date
        for i2 = 1:length(measDates)
            meanSnowThick(i2) = mean(allStakes.snowThickness(allStakes.siteName == indivSites(i) &...
                allStakes.measurementDate == measDates(i2)),'omitnan');
            stdSnowThick(i2) = std(allStakes.snowThickness(allStakes.siteName == indivSites(i) &...
                allStakes.measurementDate == measDates(i2)),0,'omitnan');
        end
        
        errorbar(datenum(measDates),meanSnowThick,stdSnowThick,'-o');
        datetick('x','mmm dd')
    end
    
    grid on
    box on
    
    datetick('x','mmm dd');
    
    title('Site average snow thickness')
    ylabel('Snow thickness (cm)')
    xlabel('Date')
    
    legend(extractBefore(legendStrings([1 3 6],1),'/'))
 