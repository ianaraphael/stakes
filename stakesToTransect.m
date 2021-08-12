% stakesToTransect.m

% compare mosaic stakes measurement to transect GEM + magnaprobe measurements

% Ian Raphael
% 2020.04.15

% clean up
close all
clear

% get to the right dir
cd("/Users/"+getenv('USER')+"/Desktop/Stakes")
masterPath = genpath(pwd);
addpath(masterPath);

% get up-to-date version of thickness data
if ~exist("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat",'file')
    getThickness;
end

% get the transect path
GEMThicknessFilePath = "/Users/"+getenv('USER')+"/Desktop/Stakes/1. Data/3. Supporting Data/04_Transects/01-ice-thickness";

load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")

% get a list of the unique measurement days, add to struct
ITDs.date = unique(allStakes.measurementDate,'stable');

% for every measurement date
for i=1:length(ITDs(1).date)
    
    % put a stakes thickness ITD in the struct 
    ITDs(i).stakesITD = allStakes.thickness(allStakes.measurementDate == ITDs(1).date(i));
    
    % also just go ahead and do the snow thickness distrib now as well
    ITDs(i).stakesSTD = allStakes.snowThickness(allStakes.measurementDate == ITDs(1).date(i));
end


% remove all of the current dirs
rmpath(masterPath);

% navigate to the transect directory
cd(GEMThicknessFilePath)

% add all the subdirs
addpath(genpath(pwd))

% save the dir struct
surveyDir = dir;

% get the directory contents
surveyDirContents = string({surveyDir(:).name});


% for every stakes measurement date
for i=1:length(ITDs(1).date)
    
    % get the date as a string without the periods
    currDate = strrep(string(ITDs(1).date(i)),".","");
    
    % look through the directory to find a survey that matches the date
    surveyIndex = find(contains(surveyDirContents,strrep(string(ITDs(1).date(i)),".","")));
    
    % if we found at least one survey on that date
    if ~isempty(surveyIndex)
        
        % for every survey on that date
        for i2 = 1:length(surveyIndex)
            
            % descend into the dir
            cd(surveyDirContents(surveyIndex(i2)))
            
            % get the dir struct
            currDir = dir;

            % get the contents of the currDir
            currDirContents = string({currDir(:).name});

            % get the index for the thickness filename
            thicknessFileIndex = find(contains(currDirContents,"thickness.csv"));
            
            % if there is a file to get
            if ~isempty(thicknessFileIndex)
                
                % load that thickness file in
                currThicknessFile = readtable(currDirContents(thicknessFileIndex));

                % get the fields of the table
                currFields = fields(currThicknessFile);

                % get thicknesses from the 18MHz_hcp_i field
                currThicknesses = currThicknessFile.(string(currFields(contains(currFields,"18") ...
                    & contains(currFields,"_i"))));
                
                % if this is the first survey on that date
                if i2 == 1
                    ITDs(i).GEMITD = currThicknesses;
                else
                    % append them to the existing thicknesses for this date
                    ITDs(i).GEMITD = [ITDs(i).GEMITD;currThicknesses];
                end
            end
            
            % and cd back up into the parent directory
            cd ..
        end
    end
end

clearvars -except ITDs masterPath