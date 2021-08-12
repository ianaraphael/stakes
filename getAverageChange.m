% getPeriodChange.m

% Function for getting the average rate of growth/melt of the ice surface,
% ice bottom, and total thickness over a time period.

% User can specify:
% The desired time period
% TODO: The desired site

% Returns a struct containing:
    % An array containing rate of surface change over the period for every stake
    % An array containing rate of bottom change over the period for every stake
    % An array containing rate total thickness change over the period for every stake

    % An array containing average rate of surface change over the period for each site
    % An array containing average rate of bottom change over the period for each site
    % An array containing average rate of thickness change over the period for each site

% Function inputs are:
    % 'allStakes_timeSeries_raw.m'
    % (Optional) a vector of matlab datenums defining the period of
        % interest, with format [startDate endDate]
        % if this variable is not passed, user will be able to define
        % dates through a GUI interface
        
% Ian Raphael
% ian.th@dartmouth.edu
% Last updated 2020.11.02

function values = getPeriodChange(allStakes,period)


%% Get period dates

% if the user is not passing dates via vector
if ~exist('period')
    
    % get them via gui
    startDate = datenum(getDate('Start'),'yyyy.MM.dd');
    endDate = datenum(getDate('End'),'yyyy.MM.dd');
    
    % if (while) the end date is before or on start date
    while (startDate >= endDate)
        % ask the user to update the dates
        clc
        fprintf('Selected end date falls on or before start date.\nPlease reselect desired period.\n');
        startDate = datenum(getDate('Start'),'yyyy.MM.dd');
        endDate = datenum(getDate('End'),'yyyy.MM.dd');
    end
    
% otherwise    
else
    % get the from the vector they passed
    startDate = period(1);
    endDate = period(2);
end


%% Get changes

% get the indices for all of the stakes that satisfy

% get the beginning surface height

% get the beginning bottom height

% get the end surface height

% get the end bottom height

% get the beginning thickness

% get the end thickness












% GUI for getting user input dates
function returnDate = getDate(startOrEnd)
fig = uifigure('Name',["Set "+startOrEnd+" date"],'Position',[340 400 415 300]);
d = uidatepicker(fig,'DisplayFormat','yyyy.MM.dd',...
    'Position',[130 190 150 22],...
    'Value',NaT,...
    'ValueChangedFcn', @datechange);

    function datechange (src,event)
        newdate = char(event.Value);
        msg = ['Set ' startOrEnd ' date to ' newdate '?'];
        % Confirm new date
        selection = uiconfirm(fig,msg,'Confirm Date');
        
        
        if (strcmp(selection,'OK'))
           returnDate = newdate;
           close(fig)
        end
    end
    waitfor(fig)
end
end







