% modOpData.m

% just a quick mangy script to modify the operational data sheet to include
% some more parameters

% Ian Raphael
% 2021.03.24

close all
clear

cd("/Users/"+getenv('USER')+"/Desktop/Stakes")

readStakes % read in the newest version of the stakes data
getThickness % recalc thickness data

load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat") % load the data

% get a list of individual stakes
indivStakes = unique(allStakes.stakeID,'stable');


initIceThick = nan(length(indivStakes),1);
initSnowThick = nan(length(indivStakes),1);
maxSnowThick = nan(length(indivStakes),1);
iceGrowthTotal = nan(length(indivStakes),1);
bottomGrowthStart = NaT(length(indivStakes),1);
bottomGrowthEnd = NaT(length(indivStakes),1);

snowMeltTotal = nan(length(indivStakes),1);
surfMeltTotal = nan(length(indivStakes),1);
bottomMeltTotal = nan(length(indivStakes),1);

bottomMeltStart = NaT(length(indivStakes),1);
bottomMeltEnd = NaT(length(indivStakes),1);

% for every stake
for i = 1:length(indivStakes)
    
    % get all of the indices in the allStakes list where this stake lives
    currIndices = find(allStakes.stakeID == indivStakes(i));
    
    % get the first value for init ice thickness
    initIceThick(i) = allStakes.initialIceThickness(currIndices(1));
    
    % get the init snow thickness
    initSnowThick(i) = allStakes.snowThickness(currIndices(1));
    
    % get the max snow thickness
    maxSnowThick(i) =  max(allStakes.snowThickness(currIndices));
    
    % get the max snow surface position and save its index
    [maxSnow, maxSnowIndex] = max(allStakes.snowSurfaceMeasurement(currIndices));
    
    % get the initial ice surf position and save its index
    initSurf = allStakes.iceSurfaceMeasurement(currIndices(1));
    
    % get the absolute value of the max bottom position and save its index
    [maxBottom, maxBottomIndex] = max(abs(allStakes.thicknessGaugeMeasurementNormalized(currIndices)));
    bottomGrowthEnd(i) = allStakes.measurementDate(currIndices(maxBottomIndex));
    bottomMeltStart(i) = allStakes.measurementDate(currIndices(maxBottomIndex));
    
    
    % If there's more than one measurement
    if length(currIndices)>1
        
        
        % get the total snow melt (max snow reading minus min following
        % reading. Note that this does not account for snow erosion (i.e.
        % assigns snow erosion to melt. Will deal with this manually.
        snowMeltTotal(i) = maxSnow - min(allStakes.snowSurfaceMeasurement(currIndices(maxSnowIndex:end)));
        
        % get the total surf melt (initial surface minus minimum following
        % value
        surfMeltTotal(i) = initSurf - min(allStakes.iceSurfaceMeasurement(currIndices(1:end)));
        
    else % otherwise
        
        % assign nans
        snowMeltTotal(i) = nan;
        surfMeltTotal(i) = nan;
        
    end
    
    % if there's more than 1 non nan measurement on the thickness gauge
    if length(find(~isnan(allStakes.thicknessGaugeMeasurementNormalized(currIndices)))) > 1

        % get the total bottom melt (max bottom - minimum following value)
        bottomMeltTotal(i) = maxBottom - min(abs(allStakes.thicknessGaugeMeasurementNormalized(currIndices(maxBottomIndex:end))));
        [~,idx] = min(abs(allStakes.thicknessGaugeMeasurementNormalized(currIndices(maxBottomIndex:end))));
        bottomMeltEnd(i) = allStakes.measurementDate(currIndices(idx));
        
        % get the max ice growth (maximum - init)
        iceGrowthTotal(i) = max(abs(allStakes.thicknessGaugeMeasurementNormalized(currIndices)))...
            - abs(allStakes.thicknessGaugeMeasurementNormalized(currIndices(1)));
        bottomGrowthStart(i) = (allStakes.measurementDate(currIndices(1)));
        
        % if melt start date = melt end date
        if bottomMeltStart(i) == bottomMeltEnd(i)
            % set to nans
            bottomMeltTotal(i) = nan;
            bottomMeltStart(i) = NaT;
            bottomMeltEnd(i) = NaT;
        end
        
        % if growth start date = growth end date
        if bottomGrowthStart(i) == bottomGrowthEnd(i)
            
            % set to nans
            iceGrowthTotal(i) = nan;
            bottomGrowthStart(i) = NaT;
            bottomGrowthEnd(i) = NaT;
        end
    else
        % assign nans
        bottomMeltTotal(i) = nan;
        iceGrowthTotal(i) = nan;
        bottomGrowthStart(i) = NaT;
        bottomGrowthEnd(i) = NaT;
        bottomMeltStart(i) = NaT;
        bottomMeltEnd(i) = NaT;
    end
end

filename = "./1. Data/0. Metadata/allStakes_operationalDatesOverview.xlsx";
A = table(initIceThick, initSnowThick, maxSnowThick, iceGrowthTotal, bottomGrowthStart,...
    bottomGrowthEnd, snowMeltTotal, surfMeltTotal, bottomMeltTotal,...
    bottomMeltStart, bottomMeltEnd);
sheet = 1;
fileRange = 'F2';
writetable(A,filename,'Sheet',sheet,'Range',fileRange,'WriteVariableNames',false,'WriteRowNames',false);
