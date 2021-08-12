% plot stakes longevity

load allStakes_timeSeries_withThicknessAndChange_20201003.mat

indivSites = unique(allStakes.siteName,'stable');
stakeCounter = 0;

figure
hold on

ColOrd = get(gca,'ColorOrder');
% Determine the number of colors in
% the matrix
[m,n] = size(ColOrd);

for i = 1:length(indivSites)
    
    stakeIDs = allStakes.stakeID(allStakes.siteName==indivSites(i));
    beginDates = allStakes.dateInstalled(allStakes.siteName==indivSites(i));
    endDates = allStakes.dateOfLastMeasurement(allStakes.siteName==indivSites(i));
    
    [~,indices] = unique(stakeIDs,'stable');
    
    uniqueStart = beginDates(indices);
    uniqueEnd = endDates(indices);
    
    ColRow = rem(i,m);
    if ColRow == 0
        ColRow = m;
    end
    % Get the color
    Col = ColOrd(ColRow,:);
    
    for i2 = 1:length(indices)
        if i2 == 1
            L(i) = plot([i2+stakeCounter i2+stakeCounter],[uniqueStart(i2) uniqueEnd(i2)],'LineWidth',4,'Color',Col);
        else
            plot([i2+stakeCounter i2+stakeCounter],[uniqueStart(i2) uniqueEnd(i2)],'LineWidth',4,'Color',Col)
        end
    end
    
    stakeCounter = stakeCounter + length(indices);
    
    
end

title('MOSAiC Stakes operational dates','FontSize',18,'FontWeight','Bold')
xlabel('Stake ID','FontSize',16,'FontWeight','Bold')
ylabel('Operational dates','FontSize',16,'FontWeight','Bold')
legend(L,extractBefore(indivSites,'/'),'Location','NorthEastOutside','FontSize',12)

box on
grid on