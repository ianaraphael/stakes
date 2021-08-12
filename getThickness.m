% get thickness.m

% script for calculating thicknesses, rates of interface change from stakes
% data

% Ian Raphael
% ian.th@dartmouth.edu

% last updated 2021.03.15

cd("/Users/"+getenv('USER')+"/Desktop/Stakes")
addpath(genpath(pwd));

readStakes;

load("allStakes_timeSeries_QAd_"+date+".mat");

% mask QAd purge points if true. Don't save points in thickness change
% calculations etc.
purge = true;


allStakes.thickness = nan(size(allStakes.stakeID,1),1); % declare a vector for calculated thickness

allStakes.thicknessChangeRate = nan(size(allStakes.stakeID,1),1); % thickness change/elapsed time
allStakes.snowChangeRate = nan(size(allStakes.stakeID,1),1); % snow change/elapsed time
allStakes.surfaceChangeRate = nan(size(allStakes.stakeID,1),1); % surface change/elapsed time
allStakes.bottomChangeRate = nan(size(allStakes.stakeID,1),1); % bottom change/elapsed time

allStakes.thicknessGaugeMeasurementNormalized = nan(size(allStakes.stakeID,1),1); % thickness gauge meas. normalized to the initial ice surface
allStakes.iceSurfaceMeasurementNormalized =  nan(size(allStakes.stakeID,1),1); % ice surface meas normalized to initial ice surface
allStakes.snowSurfaceMeasurementNormalized = nan(size(allStakes.stakeID,1),1); % snow surface measurement normalized to initial ice surface

allStakes.cumulativeThicknessChange = nan(size(allStakes.stakeID,1),1); % total amount of ice thickness change to date for each timestep
allStakes.cumulativeSurfaceChange = nan(size(allStakes.stakeID,1),1); % total amount of surface change to date for each timestep
allStakes.cumulativeBottomChange = nan(size(allStakes.stakeID,1),1); % total amount of bottom change to date for each timestep
allStakes.cumulativeSnowChange = nan(size(allStakes.stakeID,1),1); % total amount of snow surface change to date for each timestep

% if purging bad points
if purge == true
    
    % first make sure all nans are logical 0s
    allStakes.purgeTop(isnan(allStakes.purgeTop)) = 0;
    
    % then set bad measurements to nan
    allStakes.snowSurfaceMeasurement(logical(allStakes.purgeTop)) = nan;
    
    % do the same for bottom
    allStakes.purgeBottom(isnan(allStakes.purgeBottom)) = 0;
    allStakes.thicknessGaugeMeasurement(logical(allStakes.purgeBottom)) = nan;
    
end

% get a list of the unique stake IDs, in order of ocurrence
indivStakes = unique(allStakes.stakeID,'stable');

% for every unique stake
for i = 1:length(indivStakes)
    
    % get the indices where the stake exists
    currIndices = find(allStakes.stakeID == indivStakes(i));
    
    % first set the ice surf meas as the initial value
    allStakes.iceSurfaceMeasurement(currIndices) =...
        repmat(allStakes.iceSurfaceMeasurement(currIndices(1)),size(currIndices,1),1);
    
    % then extract the ice top and bottom and snow surface measurements for this stake
    currSurfMeas = allStakes.iceSurfaceMeasurement(currIndices);
    currSnowMeas = allStakes.snowSurfaceMeasurement(currIndices);
    currBottomMeas = allStakes.thicknessGaugeMeasurement(currIndices);    
    
    % where the snow surf meas is less than the initial ice surface measurement
    % (i.e. ice surface melt is beginning)
    % set the ice surface measurement as the snow surface measurement
    currSurfMeas(currSnowMeas < currSurfMeas(1) | isnan(currSnowMeas)) =...
        currSnowMeas(currSnowMeas < currSurfMeas(1) | isnan(currSnowMeas));
    
    % then stuff the surface measurement back into the master vector
    allStakes.iceSurfaceMeasurement(currIndices) = currSurfMeas;
    
    % where the stake is ponded
    % set the ice surface measurement as the snow surface measurement - snow thickness
    allStakes.iceSurfaceMeasurement(find(allStakes.stakeID == indivStakes(i) & allStakes.pondFlag == 1)) =...
        allStakes.snowSurfaceMeasurement(find(allStakes.stakeID == indivStakes(i) & allStakes.pondFlag == 1)) -...
        allStakes.snowThickness(find(allStakes.stakeID == indivStakes(i) & allStakes.pondFlag == 1));
    
    % and set the snow surface measurement to the ice surf meas
    allStakes.snowSurfaceMeasurement(find(allStakes.stakeID == indivStakes(i) & allStakes.pondFlag == 1)) = ...
        allStakes.iceSurfaceMeasurement(find(allStakes.stakeID == indivStakes(i) & allStakes.pondFlag == 1));
    
    % get a normalized ice surface version (init surface measurement = 0)
    allStakes.iceSurfaceMeasurementNormalized(currIndices) = allStakes.iceSurfaceMeasurement(currIndices)...
        - allStakes.iceSurfaceMeasurement(currIndices(1));
    
    % normalize the bottom measurements to the initial ice surface
    % (initial ice thickness +/- ∂bottom). So call init ice surface 'zero'
    % for all ice thicknesses
    currBottomMeasNormalized = -(allStakes.initialIceThickness(currIndices) +...
        (repmat(allStakes.thicknessGaugeMeasurement(currIndices(1)),size(currIndices,1),1)-...
        allStakes.thicknessGaugeMeasurement(currIndices)));
    
    % put it back in
    allStakes.thicknessGaugeMeasurementNormalized(currIndices) = currBottomMeasNormalized;
    
    % normalize the snow surface measurement
    currSnowMeasNormalized = currSnowMeas - allStakes.iceSurfaceMeasurement(currIndices(1));
    
    % put it back in
    allStakes.snowSurfaceMeasurementNormalized(currIndices) = currSnowMeasNormalized;
    
    % for every stake
    % get the ice thickness for each timestep as:
    % currThickness = initThickness + (initialGauge - currGauge) + (currSurf - initSurf)
    allStakes.thickness(currIndices) = allStakes.initialIceThickness(currIndices) +...
        (repmat(allStakes.thicknessGaugeMeasurement(currIndices(1)),size(currIndices,1),1)-...
        allStakes.thicknessGaugeMeasurement(currIndices)) +...
        (allStakes.iceSurfaceMeasurement(currIndices) -...
        (repmat(allStakes.iceSurfaceMeasurement(currIndices(1)),size(currIndices,1),1)));
    
    % and also get snow thickness
    allStakes.snowThickness(currIndices) = allStakes.snowSurfaceMeasurementNormalized(currIndices) -...
        allStakes.iceSurfaceMeasurementNormalized(currIndices);
    
    %% now for each measurement
    
    % get the thickness change/elapsed time
    allStakes.thicknessChangeRate(currIndices(2:end)) = diff(allStakes.thickness(currIndices))./...
        diff(datenum(allStakes.measurementDate(currIndices)));
    
    % get the snow change/elapsed time
    allStakes.snowChangeRate(currIndices(2:end)) = diff(allStakes.snowThickness(currIndices))./...
        diff(datenum(allStakes.measurementDate(currIndices)));
    
    % get the surface change/elapsed time
    allStakes.surfaceChangeRate(currIndices(2:end)) = diff(allStakes.iceSurfaceMeasurementNormalized(currIndices))./...
        diff(datenum(allStakes.measurementDate(currIndices)));
    
    % get the bottom change/elapsed time
    allStakes.bottomChangeRate(currIndices(2:end)) = -diff(allStakes.thicknessGaugeMeasurementNormalized(currIndices))./...
        diff(datenum(allStakes.measurementDate(currIndices)));
    
    %% Now get cumulative (delta) change
    
    % first assign the values to their initial normalized vals
    allStakes.cumulativeSnowChange(currIndices) = allStakes.snowSurfaceMeasurementNormalized(currIndices);
    allStakes.cumulativeSurfaceChange(currIndices) = allStakes.iceSurfaceMeasurementNormalized(currIndices);
    allStakes.cumulativeBottomChange(currIndices) = allStakes.thicknessGaugeMeasurementNormalized(currIndices);
    allStakes.cumulativeThicknessChange(currIndices) = allStakes.thickness(currIndices);
    
    % then subtract the initial measurement from all values to get the delta
    allStakes.cumulativeSnowChange(currIndices) = allStakes.cumulativeSnowChange(currIndices) - allStakes.snowSurfaceMeasurementNormalized(currIndices(1));
    allStakes.cumulativeSurfaceChange(currIndices) = allStakes.cumulativeSurfaceChange(currIndices) - allStakes.iceSurfaceMeasurementNormalized(currIndices(1));
    allStakes.cumulativeBottomChange(currIndices) = allStakes.cumulativeBottomChange(currIndices) - allStakes.thicknessGaugeMeasurementNormalized(currIndices(1));
    allStakes.cumulativeThicknessChange(currIndices) = allStakes.cumulativeThicknessChange(currIndices) - allStakes.thickness(currIndices(1));
    
end



%% save out the data

% if this is a purged (cleaned/QAd) dataset
if purge == true
    % save it as QAd
    save("./1. Data/2. Preprocessed Data/allStakes_timeSeries_withThicknessAndChange_QA_"+string(date),'allStakes');
    writetable(struct2table(allStakes), "./1. Data/2. Preprocessed Data/allStakes_timeSeries_withThicknessAndChange_QA_"+string(date)+".csv")
else
   % otherwise flag it as not QAd
   save("./1. Data/2. Preprocessed Data/allStakes_timeSeries_withThicknessAndChange_NOTQA_"+string(date),'allStakes');
   writetable(struct2table(allStakes), "./1. Data/2. Preprocessed Data/allStakes_timeSeries_withThicknessAndChange_NOTQA_"+string(date)+".csv")
end

clear all