% linkTimeSeries.m

% links discontinuous time series of delta thickness for each stake by 
% thickness category, creating a continuous time series for stakes in the
% same thickness categories

% Ian Raphael
% ian.th@dartmouth.edu
% 2021.08.10

% clean up
close all
clear

% get to the right directory
cd("/Users/"+getenv('USER')+"/Desktop/Stakes")
addpath(genpath(pwd));

% load the data
getThickness;
load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")

%% globals
growthInitDate = datetime(20200109,'ConvertFrom','yyyymmdd'); % growth init date; basically ground zero for all thicknesses
growthEndDate = datetime(20200512,'ConvertFrom','yyyymmdd'); % growth end date; final measurement date during the growth season
meltInitDate = datetime(20200626,'ConvertFrom','yyyymmdd'); % melt init date; beginning of melt measurements
meltEndDate = datetime(20200725,'ConvertFrom','yyyymmdd'); % melt end date; final measurement date during the melt season
searchHalfWindow = 10; % half window to search for matching measurement dates

% ice thickness category bin edges, based on lower bounds from:
% https://cice-consortium-icepack.readthedocs.io/en/master/science_guide/sg_itd.html
% six edges provides five bins, with last bin from 3.6 m to +inf
thicknessCategories_edges = [0; 0.6; 1.4; 2.4; 3.6; inf];
thicknessCategories_edges = thicknessCategories_edges * 100; % convert from m to cm
numThicknessCategories = 5;

% plot stuff
titleFontSize = 18;
labelFontSize = 16;
legendFontSize = 12;


%% A function to infer the missing endpoints (initial and final conditions) of each stake
function [] = inferEndpoints(initDate,endDate,searchHalfWindow,stakesObject)

allStakes = stakesObject;
growthInitDate = initDate;
growthEndDate = endDate;

% % allocate a vector to hold the init thickness categories and orders of inference
% allStakes.initialThicknessCategory_inferred = nan(length(allStakes.thickness),1);
% allStakes.initialThicknessCategory_orderOfInference = nan(length(allStakes.thickness),1);

% % and final
% allStakes.finalThicknessCategory_inferred = nan(length(allStakes.thickness),1);
% allStakes.finalThicknessCategory_orderOfInference = nan(length(allStakes.thickness),1);


% find the indices of the stakes that were measured within the search window of the
% init date
initIndices = find(allStakes.measurementDate >= (growthInitDate - searchHalfWindow) &... % stake was measured after bottom end of window
    allStakes.measurementDate <= (growthEndDate - searchHalfWindow),'stable');% stake was measured before top end of window

% get the stake IDs
initStakes = allStakes.stakeID(initIndices);
% get the measurement dates
initDates = allStakes.measurementDate(initIndices);
% get the thicknesses 
initThickness = allStakes.thickness(initIndices);
% get the ice age
initIceAge = allStakes.iceAge(initIndices);

% sort everything by the measurement date
[initDates, sortOrder] = sort(initDates);
initStakes = initStakes(sortOrder);
initThickness = initThickness(sortOrder);
initIceAge = initIceAge(sortOrder);

% get the unique IDs (will give first occurrence, so earliest date for each stake)
[initStakes, uniqueIndices] = unique(initStakes,'stable');
% pull the corresponding dates and thicknesses
initDates = initDates(uniqueIndices);
initThickness = initThickness(uniqueIndices);
initIceAge = initIceAge(uniqueIndices);

% discretize the intial ice thicknessess into ice thickness category
initialThicknessCategory_inferred(initStakes) = ...
    discretize(initThickness,...
    thicknessCategories_edges,...
    'categorical', ...
    {'cat_1', 'cat_2', 'cat_3', 'cat_4', 'cat_5'});

% flag these as 0th order of inference
initialThicknessCategory_orderOfInference(initStakes) = 0;

% save the modal thickness category for 1st and 2nd year types
modalInitThickness(1) = mode(initialThicknessCategory_inferred(initIceAge == 1));
modalInitThickness(2) = mode(initialThicknessCategory_inferred(allStakes.iceAge == 2));

% 
% %TODO: find the stakes that were functional before and after init date
% initStakes = unique(...
%     allStakes.stakeID(growthInitDate >= allStakes.dateInstalled &...
%     growthInitDate <=allStakes.dateOfLastMeasurement),...
%     'stable');
% 
% % find the indices of their first occurrence in the allstakes struct
% [~,initStakes_indices] = intersect(allStakes.stakeID,initStakes,'stable');
% 
% % discretize their intial ice thickness into ice thickness category
% allStakes.initialThicknessCategory_inferred(initStakes_indices) = ...
%     discretize(allStakes.initialIceThickness(initStakes_indices),...
%     thicknessCategories_edges,...
%     'categorical', ...
%     {'cat_1', 'cat_2', 'cat_3', 'cat_4', 'cat_5'});
% 
% % flag these as 0th order of inference
% allStakes.initialThicknessCategory_orderOfInference(initStakes_indices) = 0';
% 
% % save the modal thickness category for 1st and 2nd year types
% modalInitThickness(1) = mode(allStakes.initialThicknessCategory_inferred(...
%     find(allStakes.iceAge == 1)));
% modalInitThickness(2) = mode(allStakes.initialThicknessCategory_inferred(...
%     find(allStakes.iceAge == 2)));
% 

%%

% find the stakes whose installation dates came after the init date
missingInitStakes = unique(...
    allStakes.stakeID(growthInitDate <= allStakes.dateInstalled),...
    'stable');

% find the indices of their first occurrence in the allstakes struct
[~,missingInitStakes_indices] = intersect(allStakes.stakeID,missingInitStakes,'stable');

% discretize their installation ice thicknesses into ice thickness categories
missingInitStakes_installIceThickness = ...
    discretize(allStakes.initialIceThickness(missingInitStakes_indices),...
    thicknessCategories_edges,...
    'categorical', ...
    {'cat_1', 'cat_2', 'cat_3', 'cat_4', 'cat_5'});

%% we should proceed chronologically from here, to ensure that we have the
% most overlap between stakes

% sort the stakes by their installation date
[missingInitStakes_installDate_sorted, sortOrder] = sort(allStakes.dateInstalled(missingInitStakes_indices),...
    'ascend');
missingInitStakes_sorted = missingInitStakes(sortOrder);
missingInitStakes_indices_sorted = missingInitStakes_indices(sortOrder);
missingInitStakes_installIceThickness_sorted =...
    missingInitStakes_installIceThickness(sortOrder);

% for every stake
for i=1:length(missingInitStakes_indices_sorted)
    
    % get the date that the stake was installed
    currInstallDate = allStakes.dateInstalled(missingInitStakes_indices_sorted(i));
    
    % find all of the stakes (not self) that:
    % have a measurement date within the search window of the curr stake's installation date,
    % match the stake's ice type
    % currently match the stake's installation thickness (by thickness category)
    matchStakes = unique(allStakes.stakeID(... % find all unique stakes where
        (allStakes.measurementDate >= (currInstallDate-searchHalfWindow)) &...% the meas. date is >= the bottom end of the window
        (allStakes.measurementDate <= (currInstallDate+searchHalfWindow)) &...% <= the top end of the window 
        (allStakes.iceAge == allStakes.iceAge(missingInitStakes_indices_sorted(i))) &...% the ice age (1st vs. 2nd yr) is the same
            (discretize(allStakes.thickness,thicknessCategories_edges,...% and the current measured thickness category matches the installation thickness category for the stake
                'categorical',{'cat_1', 'cat_2', 'cat_3', 'cat_4', 'cat_5'})==...
            discretize(allStakes.initialIceThickness(missingInitStakes_indices_sorted(i)),thicknessCategories_edges,...
                'categorical',{'cat_1', 'cat_2', 'cat_3', 'cat_4', 'cat_5'}))...
        ), 'stable'); % return stably sorted
    matchStakes = setxor(matchStakes,missingInitStakes_sorted(i),'stable'); % exclude self
    
    % if the set isn't empty
    if ~isempty(matchStakes)
        
        % find the indices of the matching stakes' first occurrence in the allstakes struct
        [~,matchStakes_indices] = intersect(allStakes.stakeID,matchStakes,'stable');
        
        % get the initial thickness category for all (TODO: or initial thickness...
        % haven't decided yet. probably category makes sense, since we'd be
        % averaging the thicknesses anyway)
        match_initialThicknessCategory = ...
            allStakes.initialThicknessCategory_inferred(matchStakes_indices);
        
        % if there are any non-nan thickness category matches
        if nnz(~isnan(match_initialThicknessCategory)) >= 1
            
            % get the mode of the matches
            match_initialThicknessCategory_mode = mode(match_initialThicknessCategory);
            
            % get the modal order of inference of the matches
            match_orderOfInference = ...
                mode(allStakes.initialThicknessCategory_orderOfInference(matchStakes_indices));
            
            % add one
            curr_orderOfInference = match_orderOfInference + 1;
            
            % save both
            allStakes.initialThicknessCategory_inferred(missingInitStakes_indices_sorted(i)) =...
                match_initialThicknessCategory_mode;
            allStakes.initialThicknessCategory_orderOfInference(missingInitStakes_indices_sorted(i)) =...
                curr_orderOfInference;
            
            % continue to the next 
            continue
        end
    end
    
    % if we failed to match, then we'll assign the modal initial state
    % for the appropriate ice type
    allStakes.initialThicknessCategory_inferred(missingInitStakes_indices_sorted(i)) =...
        modalInitThickness(allStakes.iceAge(missingInitStakes_indices_sorted(i)));
    
    % and give it a -1 code to flag it as such
    allStakes.initialThicknessCategory_orderOfInference(missingInitStakes_indices_sorted(i)) = -1;
end

% discretize the order of inference
allStakes.initialThicknessCategory_orderOfInference_disc = ...
discretize(allStakes.initialThicknessCategory_orderOfInference,...
[-1,0,1,2,3,4,5,6],...
'categorical', ...
{'-1th','0th', '1st', '2nd', '3rd', '4th','5th'});

% get a histogram
figure
histogram(allStakes.initialThicknessCategory_orderOfInference_disc)
title('Orders of inference with search half-window: '+string(searchHalfWindow),...
    'fontsize',titleFontSize);
xlabel('Order of inference',...
    'fontsize',labelFontSize');
box on
grid on

% discretize the thickness cats
allStakes.initialThicknessCategory_inferred_disc =...
    categorical(allStakes.initialThicknessCategory_inferred);


end

% get a histogram
figure
hold on

histogram(allStakes.initialThicknessCategory_inferred_disc(allStakes.iceAge ==1))
histogram(allStakes.initialThicknessCategory_inferred_disc(allStakes.iceAge ==2))
title('Distribution of inferred initial thickness categories',...
    'fontsize',titleFontSize);
xlabel('Thickness category',...
    'fontsize',labelFontSize');
legend('FYI','SYI',...
    'fontsize',legendFontSize);
box on
grid on


% get a histogram of only the 0th order
figure
hold on

histogram(allStakes.initialThicknessCategory_inferred_disc(allStakes.iceAge ==1 &...
    allStakes.initialThicknessCategory_orderOfInference == 0))
histogram(allStakes.initialThicknessCategory_inferred_disc(allStakes.iceAge ==2 &...
    allStakes.initialThicknessCategory_orderOfInference == 0))
title('Distribution of 0th order initial thickness categories',...
    'fontsize',titleFontSize);
xlabel('Thickness category',...
    'fontsize',labelFontSize');
legend('FYI','SYI',...
    'fontsize',legendFontSize);
box on
grid on


% %% Now get cumulative (delta) change
% 
% % first assign the values to their initial normalized vals
% allStakes.cumulativeSnowChange(currIndices) = allStakes.snowSurfaceMeasurementNormalized(currIndices);
% allStakes.cumulativeSurfaceChange(currIndices) = allStakes.iceSurfaceMeasurementNormalized(currIndices);
% allStakes.cumulativeBottomChange(currIndices) = allStakes.thicknessGaugeMeasurementNormalized(currIndices);
% allStakes.cumulativeThicknessChange(currIndices) = allStakes.thickness(currIndices);
% 
% % then subtract the initial measurement from all values to get the delta
% allStakes.cumulativeSnowChange(currIndices) = allStakes.cumulativeSnowChange(currIndices) - allStakes.snowSurfaceMeasurementNormalized(currIndices(1));
% allStakes.cumulativeSurfaceChange(currIndices) = allStakes.cumulativeSurfaceChange(currIndices) - allStakes.iceSurfaceMeasurementNormalized(currIndices(1));
% allStakes.cumulativeBottomChange(currIndices) = allStakes.cumulativeBottomChange(currIndices) - allStakes.thicknessGaugeMeasurementNormalized(currIndices(1));
% allStakes.cumulativeThicknessChange(currIndices) = allStakes.cumulativeThicknessChange(currIndices) - allStakes.thickness(currIndices(1));
% 

%% compare average growth to average melt

% get initial thicknes
