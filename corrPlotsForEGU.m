% corrPlotsForEGU.m

% correlate rates of change in stakes data environmental variables over the
% time period of change

% Ian Raphael
% ian.th@dartmouth.edu
% 2021.04.27

close all
clear

cd("/Users/"+getenv('USER')+"/Desktop/Stakes")
addpath(genpath(userpath));
addpath(genpath(pwd));

% get up-to-date version of thickness data
getThickness;
   
% load in the thickness data
load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")

% load in daily avg of environmental vars
load dailyAverageEverything_2.mat

dailyAverageEverything = dailyAverageEverything_2;

% define last day of growth season
growthEnd = datetime(20200626,'ConvertFrom','yyyymmdd');

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
correlationUnits = ["cm day^{-1}" "ºC" "W m^{-2}" "ºC" "m s^{-1}" "cm" "cm"];

% delete our copy
clear dailyAverageEverythingCopy

% set snow thickness to nan where it's equal to zero so that it doesn't
% influence fits
allStakes.snowThickness(allStakes.snowThickness == 0) = nan; 

% for each ice type
for i = 1:2
    
    % allocate matrices to hold the average corrs across all stakes of this type
    corrs(i).growthSnowCorrs = [];
    corrs(i).growthSurfCorrs = [];
    corrs(i).growthBottomCorrs = [];
    corrs(i).growthTotalCorrs = [];
    corrs(i).growthSnowP = [];
    corrs(i).growthSurfP = [];
    corrs(i).growthBottomP = [];
    corrs(i).growthTotalP = [];
    
    corrs(i).meltSnowCorrs = [];
    corrs(i).meltSurfCorrs = [];
    corrs(i).meltBottomCorrs = [];
    corrs(i).meltTotalCorrs = [];
    corrs(i).meltSnowP = [];
    corrs(i).meltSurfP = [];
    corrs(i).meltBottomP = [];
    corrs(i).meltTotalP = [];
    
    corrs(i).growthSnowChangeRates = [];
    corrs(i).growthSurfChangeRates = [];
    corrs(i).growthBottomChangeRates = [];
    corrs(i).growthTotalChangeRates = [];
    
    corrs(i).meltSnowChangeRates = [];
    corrs(i).meltSurfChangeRates = [];
    corrs(i).meltBottomChangeRates = [];
    corrs(i).meltTotalChangeRates = [];
    
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
        currTotalChangeRate = allStakes.thicknessChangeRate(currStakeIndices(2:end));
        
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
            
            
           
        end
        % append the change rates to the running vector
        corrs(i).growthBottomChangeRates = [corrs(i).growthBottomChangeRates;currBottomChangeRate(growthIndices)];
        
        
        if (length(find(~isnan(currTotalChangeRate(growthIndices))))>2)
            
            [currTotalCorr,currTotalP] = corrcoef([currTotalChangeRate(growthIndices)...
                currAvgEnvVars(growthIndices,:)],'Rows','complete');
            
            corrs(i).growthTotalCorrs = cat(3, corrs(i).growthTotalCorrs, currTotalCorr);
            corrs(i).growthTotalP = cat(3, corrs(i).growthTotalP, currTotalP);
            
        end
        % append the change rates to the running vector
        corrs(i).growthTotalChangeRates = [corrs(i).growthTotalChangeRates;currTotalChangeRate(growthIndices)];

        
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
        
        if (length(find(~isnan(currTotalChangeRate(meltIndices))))>2)
            
            [currTotalCorr,currTotalP] = corrcoef([currTotalChangeRate(meltIndices)...
                currAvgEnvVars(meltIndices,:)],'Rows','complete');
            
            corrs(i).meltTotalCorrs = cat(3, corrs(i).meltTotalCorrs, currTotalCorr);
            corrs(i).meltTotalP = cat(3, corrs(i).meltTotalP, currTotalP);
            
        end
        % append the change rates to the running vector
        corrs(i).meltTotalChangeRates = [corrs(i).meltTotalChangeRates;currTotalChangeRate(meltIndices)];

    end
    
    % set snow change rates to nan where equal to zero so that it doesn't
    % influence fits
    corrs(i).meltSnowChangeRates(corrs(i).meltSnowChangeRates==0) = nan;
    corrs(i).growthSnowChangeRates(corrs(i).growthSnowChangeRates==0) = nan;
    
    % get correlations for the aggregate measurements of each type
    [corrs(i).masterMeltSnowCorr,corrs(i).masterMeltSnowP] = corrcoef([corrs(i).meltSnowChangeRates...
        corrs(i).meltEnvVars],'Rows','complete');
    [corrs(i).masterMeltSurfCorr,corrs(i).masterMeltSurfP] = corrcoef([corrs(i).meltSurfChangeRates...
        corrs(i).meltEnvVars],'Rows','complete');
    [corrs(i).masterMeltBottomCorr,corrs(i).masterMeltBottomP] = corrcoef([corrs(i).meltBottomChangeRates...
        corrs(i).meltEnvVars],'Rows','complete');
    [corrs(i).masterMeltTotalCorr,corrs(i).masterMeltTotalP] = corrcoef([corrs(i).meltTotalChangeRates...
        corrs(i).meltEnvVars],'Rows','complete');
    
    [corrs(i).masterGrowthSnowCorr,corrs(i).masterGrowthSnowP] = corrcoef([corrs(i).growthSnowChangeRates...
        corrs(i).growthEnvVars],'Rows','complete');
    [corrs(i).masterGrowthSurfCorr,corrs(i).masterGrowthSurfP] = corrcoef([corrs(i).growthSurfChangeRates...
        corrs(i).growthEnvVars],'Rows','complete');
    [corrs(i).masterGrowthBottomCorr,corrs(i).masterGrowthBottomP] = corrcoef([corrs(i).growthBottomChangeRates...
        corrs(i).growthEnvVars],'Rows','complete');
    [corrs(i).masterGrowthTotalCorr,corrs(i).masterGrowthTotalP] = corrcoef([corrs(i).growthTotalChangeRates...
        corrs(i).growthEnvVars],'Rows','complete');
    
end



% get the list of fields
listItems = fields(corrs);
listItems = "Aggregate " + extractAfter(listItems(contains(listItems,'master')&~contains(listItems,'P')),'master');


% for every ice type
for iceAge = 1:2
    
    if iceAge == 1
        iceType = "FYI";
    else
        iceType = "SYI";
    end
    % for every interface
    for corrIdx = 1:length(listItems)
        
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
        
        % for every variable
        for variable = 1:length(correlationLabels)-1
            
            currEnvVar = currAggEnvVars(:,variable);
            
            titleString = season+" season "+lower(interface)+" "+"change rate ("+iceType...
                +") vs. "+correlationLabels(variable+1);
            yLabelString = "Change rate (cm day^{-1})";
            xLabelString = correlationLabels(variable+1)+" ("+correlationUnits(variable+1)+")";
            
            % plot the correlation
            h=figure;
            set(h,'units','normalized','position',[0.1 0.1 0.4 0.6]); %Set the size of the drawing window
            set(h,'color','w'); %Set the background of the drawing window to white
            color_point=[0.02,0.71,0.29]; %Set the color of the point,Three numbers respectively[R G B]Weight based on0~1Between
            g=gramm('x',currEnvVar,'y',currAggChangeRates); %Specify the values ​​of the horizontal axis x and the vertical axis y, and create a gramm drawing object
            g.geom_point(); %Draw a scatter plot
            g.stat_glm(); %Draw lines and confidence intervals based on scatter plots
            g.set_names('x',xLabelString,'y',yLabelString); %Set the title of the axis
            g.set_text_options('base_size' ,18,'label_scaling' ,1.2);%Set the font size, the base font size base_size is set16, the title font size of the axis is set to the base font size1.2Times
            g.set_color_options('map',color_point); %Set the color of the point
            g.set_title(titleString);%Set the total title name
            g.draw(); %After setting the above properties, start drawing
            set(0,'ShowHiddenHandles','on')
            set(findobj(gcf,'Type','text'),'Interpreter','tex')
            

            % get the correlation coefficient and p val
            rVal = currCorr(1,variable+1);
            pVal = currPVals(1,variable+1);
            
            if ~isnan(rVal)
                rVal = "r = "+string(rVal);
            else
                rVal = "";
            end
            
            % set the pVal to a string
            if pVal <= 0.01
                pVal = "p < 0.01";
            elseif pVal <= 0.05
                pVal = "p < 0.05";
            else
                pVal = "p > 0.05";
            end
            
            % build a string
            corrString = {rVal pVal};
           
            text(0.6,0.8,...
                corrString,'Units','Normalized','Parent',g.facet_axes_handles(1),...
                'FontName','Courier',...
                'FontSize',14,...
                'FontWeight','bold',...
                'BackgroundColor','w',...
                'EdgeColor','k');
            pause
            
            % if the figure exists
            if ishandle(h)
                
                % save it
                g.export('file_name',titleString+".pdf",...
                'export_path','/Users/f001ymh/Desktop/Stakes/EGU Stakes/Figures',...
                'file_type','pdf',...
                'width',10,...
                'height',10,...
                'units', 'inches');
            
                % 
                
            end
        end
    end
end


