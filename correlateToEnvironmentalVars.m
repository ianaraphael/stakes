% correlateToEnvironmentalVars.m

% correlate rates of change in stakes data environmental variables over the
% time period of change

% Ian Raphael
% ian.th@dartmouth.edu
% 2021.03.23

close all
clear

cd("/Users/"+getenv('USER')+"/Desktop/Stakes")

addpath(genpath(pwd));

% get up-to-date version of thickness data
getThickness;

% define last day of growth season (for now we'll just call it 1st of may)
growthEnd = datetime(20200515,'ConvertFrom','yyyymmdd');
   
% load it in
load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")

% load in daily avg of environmental vars
load dailyAverageEverything.mat

% % get all of the measurement dates
% indivDates = unique(allStakes.measurementDate,'stable');
% 
% % pull the appropriate indices for the env. vars.
% envVarIndices = intersect(dailyAverageEverything.measurementDate,indivDates,stable);

% copy this for a second and remove datetime field and all stdDev fields
rmFields = fields(dailyAverageEverything);
dailyAverageEverythingCopy = rmfield(dailyAverageEverything,[{'measurementDate'}; rmFields(contains(rmFields,'StdDev'))]);

% stuff all of the environmental variables into a matrix
envVars = struct2array(dailyAverageEverythingCopy);

% and also keep the tags
envVarsLabels = fieldnames(dailyAverageEverythingCopy);

% build an array with the correlation labels for later
correlationLabels = ["interfaceChangeRate";string(envVarsLabels);"snowThickness";"iceThickness"];

% delete our copy
clear dailyAverageEverythingCopy

% for each ice type
for i = 1:2
    
    % allocate matrices to hold the average corrs across all stakes of this type
    corrs(i).growthSnowCorrs = [];
    corrs(i).growthSurfCorrs = [];
    corrs(i).growthBottomCorrs = [];
    corrs(i).growthSnowP = [];
    corrs(i).growthSurfP = [];
    corrs(i).growthBottomP = [];
    
    corrs(i).meltSnowCorrs = [];
    corrs(i).meltSurfCorrs = [];
    corrs(i).meltBottomCorrs = [];
    corrs(i).meltSnowP = [];
    corrs(i).meltSurfP = [];
    corrs(i).meltBottomP = [];
    
    corrs(i).growthSnowChangeRates = [];
    corrs(i).growthSurfChangeRates = [];
    corrs(i).growthBottomChangeRates = [];
    
    
    corrs(i).meltSnowChangeRates = [];
    corrs(i).meltSurfChangeRates = [];
    corrs(i).meltBottomChangeRates = [];
    
    corrs(i).growthEnvVars = [];
    corrs(i).meltEnvVars = [];
    
    % get the stakes belonging to this ice type
    indivStakes = unique(allStakes.stakeID(allStakes.iceAge == i),'stable');
    
    % for each stake
    for i2 = 1:length(indivStakes)
        
        % get the indices of the stake
        currStakeIndices = find(allStakes.stakeID == indivStakes(i2));
        
        % pull the rates of change
        currSnowChangeRate = allStakes.snowChangeRate(currStakeIndices(2:end));
        currSurfChangeRate = allStakes.surfaceChangeRate(currStakeIndices(2:end));
        currBottomChangeRate = allStakes.bottomChangeRate(currStakeIndices(2:end));
        
        % and the appropriate dates
        currDates = allStakes.measurementDate(currStakeIndices);
        
        % get growth season indices
        growthIndices = find(currDates <= growthEnd);
                
        % get melt season indices
        meltIndices = find(currDates > growthEnd);
        
        % if growth season indices exist
        if ~isempty(growthIndices)
            
            % drop the first value (because it disappears when we calculate parameter change)
            growthIndices(1) = [];

        else
            % otherwise delete from melt season indices because shift will happen here
            meltIndices(1) = [];
        end
        
        % and subtract one from the indices to deal with the shift
        growthIndices = growthIndices - 1;
        meltIndices = meltIndices - 1;
        
        % pull the relevant indices for the env. vars. (matching all dates)
        [~,currEnvVarIndices] = intersect(dailyAverageEverything.measurementDate,currDates,'stable');
        
        % allocate a matrix to hold the avg environmental variables
        currAvgEnvVars = nan(size(currEnvVarIndices,1)-1,size(envVars,2)+2);
        
        % for every 'window' between measurement dates
        for i3 = 1:(length(currEnvVarIndices)-1)
           
            % get the mean value of all of the env variables over that window
            currAvgEnvVars(i3,1:size(currAvgEnvVars,2)-2) = ...
                mean(envVars(currEnvVarIndices(i3):currEnvVarIndices(i3+1),:),1,'omitnan');
            
            % and the mean snow thickness over that window
            currAvgEnvVars(i3,size(currAvgEnvVars,2)-1) = ...
                mean(allStakes.snowThickness(currStakeIndices(i3):currStakeIndices(i3+1)),'omitnan');
            
            % and the mean thickness over that window
            currAvgEnvVars(i3,size(currAvgEnvVars,2)) = ...
                mean(allStakes.thickness(currStakeIndices(i3):currStakeIndices(i3+1)),'omitnan');
        end
        
        % and append the current env. vars. to the running vector
        corrs(i).growthEnvVars = [corrs(i).growthEnvVars;currAvgEnvVars(growthIndices,:)];
        corrs(i).meltEnvVars = [corrs(i).meltEnvVars;currAvgEnvVars(meltIndices,:)];
        
        % for growth season
        % if we have more than two data points
        if (length(find(~isnan(currSnowChangeRate(growthIndices))))>2)
             
            % get the correlation matrix for snow, top, bottom change vs each env. var
            [currSnowCorr,currSnowP] = corrcoef([currSnowChangeRate(growthIndices)...
                currAvgEnvVars(growthIndices,:)],'Rows','complete');
            
            % and stack it onto the 'average' matrix (not actually avg. yet)
            corrs(i).growthSnowCorrs = cat(3, corrs(i).growthSnowCorrs, currSnowCorr);
            corrs(i).growthSnowP = cat(3, corrs(i).growthSnowP, currSnowP);
            
            
        end
        % append the change rates to the running vector
        corrs(i).growthSnowChangeRates = [corrs(i).growthSnowChangeRates;currSnowChangeRate(growthIndices)];
        
        if (length(find(~isnan(currSurfChangeRate(growthIndices))))>2)
            
            [currSurfCorr,currSurfP] = corrcoef([currSurfChangeRate(growthIndices)...
                currAvgEnvVars(growthIndices,:)],'Rows','complete');
            
            corrs(i).growthSurfCorrs = cat(3, corrs(i).growthSurfCorrs, currSurfCorr);
            corrs(i).growthSurfP = cat(3, corrs(i).growthSurfP, currSurfP);
            
            
        end
        % append the change rates to the running vector
        corrs(i).growthSurfChangeRates = [corrs(i).growthSurfChangeRates;currSurfChangeRate(growthIndices)];
        
        if (length(find(~isnan(currBottomChangeRate(growthIndices))))>2)
            
            [currBottomCorr,currBottomP] = corrcoef([currBottomChangeRate(growthIndices)...
                currAvgEnvVars(growthIndices,:)],'Rows','complete');
            
            corrs(i).growthBottomCorrs = cat(3, corrs(i).growthBottomCorrs, currBottomCorr);
            corrs(i).growthBottomP = cat(3, corrs(i).growthBottomP, currBottomP);
            
            
            %             Experimenting with some scatter plots
            %             close all
            %             for i4 = 1:size(envVars,2)
            %                figure
            %                scatter(currBottomChangeRate(growthIndices),envVars(growthIndices,i4),'filled');
            %                title(envVarsLabels(i4))
            %             end
            %[~,~,~,~,stats] = regress(currBottomChangeRate,[ones(size(currAvgEnvVars,1),1) currAvgEnvVars(:,1) currAvgEnvVars(:,12) currAvgEnvVars(:,size(currAvgEnvVars,2))]);
        end
        % append the change rates to the running vector
        corrs(i).growthBottomChangeRates = [corrs(i).growthBottomChangeRates;currBottomChangeRate(growthIndices)];
        
        
        % for melt season
        % if we have more than two data points
        if (length(find(~isnan(currSnowChangeRate(meltIndices))))>2)
            
            % get the correlation matrix for snow, top, bottom change vs each env. var
            [currSnowCorr,currSnowP] = corrcoef([currSnowChangeRate(meltIndices)...
                currAvgEnvVars(meltIndices,:)],'Rows','complete');
            
            % and stack it onto the 'average' matrix (not actually avg. yet)
            corrs(i).meltSnowCorrs = cat(3, corrs(i).meltSnowCorrs, currSnowCorr);
            corrs(i).meltSnowP = cat(3, corrs(i).meltSnowP, currSnowP);
        end
        % append the change rates to the running vector
        corrs(i).meltSnowChangeRates = [corrs(i).meltSnowChangeRates;currSnowChangeRate(meltIndices)];
        if (length(find(~isnan(currSurfChangeRate(meltIndices))))>2)
            
            [currSurfCorr,currSurfP] = corrcoef([currSurfChangeRate(meltIndices)...
                currAvgEnvVars(meltIndices,:)],'Rows','complete');
            
            corrs(i).meltSurfCorrs = cat(3, corrs(i).meltSurfCorrs, currSurfCorr);
            corrs(i).meltSurfP = cat(3, corrs(i).meltSurfP, currSurfP);
        end
        % append the change rates to the running vector
        corrs(i).meltSurfChangeRates = [corrs(i).meltSurfChangeRates;currSurfChangeRate(meltIndices)];
        if (length(find(~isnan(currBottomChangeRate(meltIndices))))>2)
            
            [currBottomCorr,currBottomP] = corrcoef([currBottomChangeRate(meltIndices)...
                currAvgEnvVars(meltIndices,:)],'Rows','complete');
            
            corrs(i).meltBottomCorrs = cat(3, corrs(i).meltBottomCorrs, currBottomCorr);
            corrs(i).meltBottomP = cat(3, corrs(i).meltBottomP, currBottomP);
        end
        % append the change rates to the running vector
        corrs(i).meltBottomChangeRates = [corrs(i).meltBottomChangeRates;currBottomChangeRate(meltIndices)];
    end
    %     for i4 = 1:size(currAvgEnvVars,2)
    %        figure
    %        scatter(growthBottomChangeRates,growthEnvVars(:,i4),'filled');
    %        xlabel('avg. bottom change rate')
    %        ylabel('avg. value of env. var. over period of change')
    %        title(correlationLabels(i4))
    %     end
    
    % get correlations for the aggregate measurements of each type
    [corrs(i).masterMeltSnowCorr,corrs(i).masterMeltSnowP] = corrcoef([corrs(i).meltSnowChangeRates...
        corrs(i).meltEnvVars],'Rows','complete');
    [corrs(i).masterMeltSurfCorr,corrs(i).masterMeltSurfP] = corrcoef([corrs(i).meltSurfChangeRates...
        corrs(i).meltEnvVars],'Rows','complete');
    [corrs(i).masterMeltBottomCorr,corrs(i).masterMeltBottomP] = corrcoef([corrs(i).meltBottomChangeRates...
        corrs(i).meltEnvVars],'Rows','complete');
    
    [corrs(i).masterGrowthSnowCorr,corrs(i).masterGrowthSnowP] = corrcoef([corrs(i).growthSnowChangeRates...
        corrs(i).growthEnvVars],'Rows','complete');
    [corrs(i).masterGrowthSurfCorr,corrs(i).masterGrowthSurfP] = corrcoef([corrs(i).growthSurfChangeRates...
        corrs(i).growthEnvVars],'Rows','complete');
    [corrs(i).masterGrowthBottomCorr,corrs(i).masterGrowthBottomP] = corrcoef([corrs(i).growthBottomChangeRates...
        corrs(i).growthEnvVars],'Rows','complete');
    
end



% clean up a little bit
clearvars -except allStakes correlationLabels corrs

% do we want to plot histos?
keepPlotting = questdlg('Get correlation plots?','', 'Yes','No','Yes');
keepOpen = "No";

% if so
while strcmp(keepPlotting,'Yes')
    if ~strcmp(keepOpen,'Yes')
        close all
    end
    
    listItems = ["Aggregate","Individual"];
     % ask which stakes subset we want to display
    [typeIdx,tf] = listdlg('PromptString',{'Display individual or aggregate correlations?',...
        'Only one can be selected at a time.',''},...
        'SelectionMode','single','ListString',listItems);
    
    % if aggregate
    if typeIdx == 1
        % get the list of fields
        listItems = fields(corrs);
        listItems = "Aggregate " + extractAfter(listItems(contains(listItems,'master')&~contains(listItems,'P')),'master');
        
    % if individual
    else
        % get the list of fields
        listItems = fields(corrs);
        listItems = extractBefore(listItems(contains(listItems,'Corr')),'Corr');
    end
    
    % ask which subset of correlations we want to display
    [corrIdx,tf1] = listdlg('PromptString',{'Pick a seasonal+interface subset of correlations to display.',...
        'Only one can be selected at a time.',''},...
        'SelectionMode','single','ListString',listItems);
    
    if ~tf1
       break 
    end
    
    % if aggregate correlations
    if typeIdx == 1
        

        % fyi or syi?
        iceType = questdlg('FYI, SYI, All?','', 'FYI','SYI','All','');
        if strcmp(iceType,'FYI')
            iceAge = 1;
        elseif strcmp(iceType,'SYI')
            iceAge = 2;
        else
           iceAge = 1:2; 
        end
        
        % separate the string
        separatedString = regexp(extractBefore(extractAfter(listItems{corrIdx},'Aggregate '),'Corr'),'.*?[a-z](?=[A-Z]|$)','match');
        
        % get the season
        season = string(separatedString{1});
        
        % get the interface
        interface = string(separatedString{2});
        
        % get the array in question
        currCorr = vertcat(corrs(iceAge).("master"+season+interface+"Corr"));
        currPVals = vertcat(corrs(iceAge).("master"+season+interface+"P"));

        % get the aggregate change rates
        currAggChangeRates = vertcat(corrs(iceAge).(lower(season)+interface+"ChangeRates"));
        
        % and the env. vars
        currAggEnvVars = vertcat(corrs(iceAge).(lower(season)+"EnvVars"));
        
        % get a histogram of the change rates
        
        h = figure;
        corrplot([currAggChangeRates currAggEnvVars],'rows','pairwise','varnames',correlationLabels);
        title("Correlations for aggregate "+iceType+" "+lower(interface)+ " measurements over the "+lower(season)+" season");
        
        figure
        title("Correlations coeff. and p value for aggregate "+iceType+" "+lower(interface)+ " measurements over the "+lower(season)+" season");
        tiledlayout(2,1)
        
        % Top bar graph
        b = bar(categorical(correlationLabels(2:end)),currCorr(2:end,1));
        ylabel('Pearson''s corr. coeff.')
        xtips1 = b(1).XEndPoints;
        ytips1 = b(1).YEndPoints;
        labels = string(currPVals(2:end,1));
        text(xtips1,ytips1,labels,'HorizontalAlignment','center',...
            'VerticalAlignment','cap')

        
    % if individual correlations
    elseif typeIdx == 2
        
        % fyi or syi?
        %         iceType = questdlg('FYI, SYI, All?','', 'FYI','SYI','All','');
        iceType = questdlg('FYI or SYI?','', 'FYI','SYI','');
        if strcmp(iceType,'FYI')
            iceAge = 1;
        elseif strcmp(iceType,'SYI')
            iceAge = 2;
            %         else
            %             iceAge = 1:2;
        end
        
        % ask which variable we want to display
        [variableIdx,tf2] = listdlg('PromptString',{'Pick a variable against which to correlate.',...
            'Only one can be selected at a time.',''},...
            'SelectionMode','single','ListString',correlationLabels);
        
        if ~tf2
            break
        end
    
        % get the desired number of bins
        nBins = inputdlg('Number of histogram bins? (default 10)');
        nBins = str2double(nBins{1});
        
        if isempty(nBins)
            nBins = 10;
        end
        
        % get the array in question
        currCorr = corrs(iceAge).(listItems{corrIdx}+"Corrs");
        currPVals = corrs(iceAge).(listItems{corrIdx}+"P");
        
        % now get the histos of corr values
        h = histogram(currCorr(1,variableIdx,:),nBins);
        title("Distribution of corr coeffs. for "+listItems{corrIdx}+" vs. "...
            +correlationLabels(variableIdx)+" ("+iceType+")",'fontsize',14);
        
        % and p values
        figure
        histogram(currPVals(1,variableIdx,:),nBins);
        title("Distribution of P values for "+listItems{corrIdx}+" vs. "...
            +correlationLabels(variableIdx)+" ("+iceType+")",'fontsize',14);
        
        % and a scatterplot of corr vs. p
        figure
        scatter(currCorr(1,variableIdx,:),currPVals(1,variableIdx,:),'filled');
        title("Correlation vs. P values for "+listItems{corrIdx}+" vs. "...
            +correlationLabels(variableIdx)+" ("+iceType+")",'fontsize',14);
        xlabel('Correlation coefficient','fontweight','Bold','fontsize',14)
        ylabel('P value','fontweight','Bold','fontsize',14)
    end
    
    drawnow;
    
    waitfor(h);
    
    % do we want to go again?
    keepPlotting = questdlg('Get another set?','', 'Yes','No','Yes');
    % keepOpen = questdlg('Keep current plots open?','', 'Yes','No','No');
end
