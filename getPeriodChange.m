% get thickness.m

% script for calculating thicknesses from stakes data

% Ian Raphael
% ian.th@dartmouth.edu

load allStakes_timeSeries_raw.mat

% declare a vector to hold calculated thickness
allStakes.thickness = nan(size(allStakes.stakeID,1),1);

% get a list of the unique stake IDs, in order of ocurrence
indivStakes = unique(allStakes.stakeID,'stable');

% for every unique stake
for i = 1:length(indivStakes)
    
    % get the indices where the stake exists
    currIndices = find(allStakes.stakeID == indivStakes(i));
    
    
    % first set the ice surf meas as the initial value
    allStakes.iceSurfaceMeasurement(currIndices) =...
        repmat(allStakes.iceSurfaceMeasurement(currIndices(1)),size(currIndices,1),1);
    
    % if the snow surf meas is less than the initial ice surface measurement
    % (i.e. ice surface melt is beginning)
    % set the ice surface measurement as the snow surface measurement
    allStakes.iceSurfaceMeasurement(allStakes.snowSurfaceMeasurement(currIndices) <...
        allStakes.iceSurfaceMeasurement(currIndices(1))) =...
        allStakes.snowSurfaceMeasurement(allStakes.snowSurfaceMeasurement(currIndices) <...
        allStakes.iceSurfaceMeasurement(currIndices(1)));
    
    % if the stake is ponded
    % set the ice surface measurement as the snow surface measurement - snow thickness
        allStakes.snowSurfaceMeasurement(allStakes.pondFlag(currIndices) == 1) -...
        allStakes.snowThickness(allStakes.pondFlag(currIndices) == 1);
    
    % for every stake
    % get the ice thickness for each timestep as:
    % currThickness = initThickness + (initGauge - currGauge) + (currSurf - initSurf)
    allStakes.thickness(currIndices) = allStakes.initialIceThickness(currIndices) +...
        (repmat(allStakes.thicknessGaugeMeasurement(currIndices(1)),size(currIndices,1),1)-...
        allStakes.thicknessGaugeMeasurement(currIndices)) +...
        ((repmat(allStakes.iceSurfaceMeasurement(currIndices(1)),size(currIndices,1),1))-...
        allStakes.iceSurfaceMeasurement(currIndices));
end



