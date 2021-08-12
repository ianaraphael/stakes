% plotStakesOperationalDates.m

% plots longevity of all stakes on mosaic

% Ian Raphael
% ian.th@dartmouth.edu
% sometime in November 2020

cd("/Users/"+getenv('USER')+"/Desktop/Stakes")

addpath(genpath(pwd));

% get the data
readStakes;
getThickness;
load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")

% get a list of individual sites
indivSites = unique(allStakes.siteName,'stable');

% get the ice type for every site
for i = 1:length(indivSites)
   holdIceAge = allStakes.iceAge(allStakes.siteName == indivSites(i));
   if holdIceAge(1) == 1
       
       indivIceTypes(i,1) = "(FYI)";
   else
       indivIceTypes(i,1) = "(SYI)";
   end 
end

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

title('MOSAiC stakes operational dates','FontSize',22,'FontWeight','Bold')
xlabel('Stake number','FontSize',18,'FontWeight','Bold')
ylabel('Operational dates','FontSize',18,'FontWeight','Bold')
legend(L,extractBefore(indivSites,'/')+" "+indivIceTypes,'Location','NorthEastOutside','FontSize',16)

box on
grid on

%% do another one but transpose x-y axes
clear stakeIDs

% get all of the stakes by ice type
for i = 1:2
    stakeIDs(i).ids = unique(allStakes.stakeID(allStakes.iceAge == i),'stable');
end

stakeCounter = 0;

figure
hold on

for i = 1:size(stakeIDs,2)
    
    % for every stake
    for i2 = 1:length(stakeIDs(i).ids)
        % if it's a fyi stake
        if i == 1
            % color it blue
            plotColor = '#4DBEEE';
        % otherwise
        else 
            % color it green
            plotColor = '#EDB120'; 
        end
        
        % if it's the first stake at the site
        if i2 == 1
            L(i) = plot([allStakes.dateInstalled(allStakes.stakeID == stakeIDs(i).ids(i2))...
                allStakes.dateOfLastMeasurement(allStakes.stakeID == stakeIDs(i).ids(i2))],[stakeCounter stakeCounter],'-','LineWidth',4,'Color',plotColor);
        else
            plot([allStakes.dateInstalled(allStakes.stakeID == stakeIDs(i).ids(i2))...
                allStakes.dateOfLastMeasurement(allStakes.stakeID == stakeIDs(i).ids(i2))],[stakeCounter stakeCounter],'-','LineWidth',4,'Color',plotColor)
        end
        
        stakeCounter = stakeCounter + length(nnz(allStakes.stakeID==stakeIDs(i).ids(i2)));
    end
    
    
end

% title('MOSAiC stakes operational dates','FontSize',22,'FontWeight','Bold')
% ylabel('Stake number','FontSize',20,'FontWeight','Bold')

% hide y ticks
set(gca,'ytick',[])
set(gca,'yticklabel',[])

xlabel('Operational dates','FontSize',16,'FontWeight','Bold')
% legend(L,extractBefore(indivSites,'/'),'Location','NorthEastOutside','FontSize',12)

box on
%grid on