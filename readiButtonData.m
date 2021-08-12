% readiButtonData.m

% read in the ibutton data and store it in an mFile

% Ian Raphael
% ian.th@dartmouth.edu
% 2021.06.23

clear
clc

% cd to our working directory
cd("/Users/"+getenv('USER')+"/Desktop/Stakes/1. Data/3. Supporting Data/MOSAiC iButton Data")
addpath(genpath(userpath));
addpath(genpath(pwd));

% get the directory struct
currDirectory = dir;

% trim it down to the files we actually need
currDirectory = currDirectory(contains(string({currDirectory.name})',"iButton",'ignorecase',true)...
    & contains(string({currDirectory.name})',".xlsx",'ignorecase',true));

% for every file
for i = 1:size(currDirectory,1)
   
    % get the filename
    currFilename = currDirectory(i).name;
    
    % read in the data as a table
    currFile = readtable(currFilename);
    
    % trim it down to just the measurements
    trimAfter = find(strcmp(currFile{:,1}, 'Reading'),1);
    trimmedFile = currFile(trimAfter+2:end,:);
    
    iButtons(i).stakeID = str2num(extractAfter(extractBefore(currFilename,"_"),'stake'));
    
    % first convert the whole date vector into datetimes
    holdDates = datetime(trimmedFile{:,1});
    
    % find all of the non nats
    nonNatIndices = find(~isnat(holdDates(:,1)));
    
    % switch their day and month
    holdMonths = holdDates(nonNatIndices).Month;
    holdDates(nonNatIndices).Month = holdDates(nonNatIndices).Day;
    holdDates(nonNatIndices).Day = holdMonths;
    
    % now find all the nats
    natIndices = find(isnat(holdDates(:,1)));
    
    % Now pull the corresponding table data into their own vector
    holdDates(natIndices,1) = datetime(trimmedFile{natIndices,1});
    
    % Now find all of the entries with dates < 100
    wrongYearIndices = find(holdDates.Year < 100);
    
    if ~isempty(holdDates(wrongYearIndices))
        % and add 2000 years to their date
        holdDates(wrongYearIndices).Year = holdDates(wrongYearIndices).Year...
            + 2000;
    end
    
    iButtons(i).date = holdDates;
    
%     % find the first NaT
%     firstNaT = find(isnat(holdDates(:,1)),1);
%     
%     % check whether the year is >= 2019, if so, set swap flag true to swap
%     % the day and month for the affected dates
%     holdDate = datetime(trimmedFile{firstNaT,1});
%     swapDayMonth = holdDate.Year >= 2019;
%     
%     % for every date entry
%     for i2 = 1:height(trimmedFile)
%         
%         % convert the date into a datetime
%         currDate = datetime(trimmedFile{i2,1});
%         
%         % if the date is < 100
%         if year(currDate) < 100
%             % add 2000 years
%             iButtons(i).date(i2,1) = currDate + calyears(2000);
%         elseif swapDayMonth
%             % we know that the month and day have been swapped. Put them 
%             % back.
%             iButtons(i).date(i2,1) = currDate;
%             iButtons(i).date(i2,1).Day = currDate.Month;
%             iButtons(i).date(i2,1).Month = currDate.Day;
%         end
%     end
    
    
    % if the temps aren't already doubles
    if iscell(trimmedFile{1,2})
        % convert them into doubles
        iButtons(i).temp = str2double(extractBefore(trimmedFile{:,2},"°C"));
    else
        % otherwise just stuff them in there
        iButtons(i).temp = trimmedFile{:,2};
    end
    
end

% save the data out to a .mat file
saveFilename = "iButtons_data";
save(saveFilename,'iButtons');