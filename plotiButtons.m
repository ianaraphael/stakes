% plotiButtons.m

% plot iButton data

% Ian Raphael
% ian.th@dartmouth.edu
% 2021.06.23

% clean up
clear
close all

% cd to our working directory
cd("/Users/"+getenv('USER')+"/Desktop/Stakes");
addpath(genpath(userpath));
addpath(genpath(pwd));

% load the data
getThickness;
load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")
load iButtons_data
load dailyAverageEverything_2
load hourlyTemp

iceTypePlots = false; % get plots by ice type
sitePlots = false; % get plots by stakes site
allStakesPlots = true; % get plots for all stakes

kEffective_snow = 0.4; % snow thermal conductivity
kEffective_ice = 2.10; % ice thermal conductivity

latentHeatFusion = 240; % latent heat of fusion for ice (334 kJ/kg)
rhoIce = 900; % ice density (kg/m^3)

endDate = datenum(datetime('2020.04.01','InputFormat','yyyy.MM.dd'));

titleFontSize = 24;
subtitleFontSize = 16;
labelFontSize = 20;
legendFontSize = 14;
tickFontSize = 14;

indivStakes = unique(allStakes.stakeID,'stable');
indivSites = unique(allStakes.siteName,'stable');

fyiColor = 'r';
syiColor = 'b';


% get a figure
figure
hold on


% for all of the ibuttons
for i = 1:length(iButtons)
    
    % filter everything warmer than 5 ºC
    iButtons(i).temp(iButtons(i).temp > 5) = nan;
    
    % plot the data
    plot(iButtons(i).date, iButtons(i).temp,'.-');
end

legend("Stake "+ string([iButtons.stakeID]),...
    'fontsize', legendFontSize);
title('Snow/ice interface temperature time series',...
    'fontsize',titleFontSize);
xlabel('Time',...
    'fontsize',labelFontSize)
ylabel('Temperature (ºC)',...
    'fontsize',labelFontSize)
box on
grid on



%% compare interface temps to ice and snow thickness

snowThick = [];
iceThick = [];
interfaceTemp = [];
airTemp = [];
measurementDate = [];
stakeIDs = [];

interpSnowThick = [];
interpIceThick = [];
interpAirTemp = [];
interpMeasurementDate = [];
interpStakeIDs = [];
interpInterfaceTemp = [];

% for every ibutton
for i = 1:length(iButtons)
    
    % first truncate all of the dates
    dates = datestr(iButtons(i).date, 'yyyy.mm.dd');
    
    % then get the unique ones
    [indivDates, indices] = unique(dates, 'rows', 'stable');
    
    % convert them back into datetimes
    indivDates = datetime(indivDates,'inputformat','yyyy.MM.dd');
    
    % and go back in to get the temps
    indivTemps = iButtons(i).temp(indices);
    
    % get the matching stake's snow and ice thickness measurements
    currStakesIndices = find(allStakes.stakeID==iButtons(i).stakeID);
    currSnowThickness = allStakes.snowThickness(currStakesIndices);
    currIceThickness = allStakes.thickness(currStakesIndices);
    currStakesDates = allStakes.measurementDate(currStakesIndices);
    
    % get the intersection of the ibutton and stakes dates
    [commonDates,commonIdxIbuttons,commonIdxStakes] = intersect(indivDates,currStakesDates);
    
    % get the intersection of the daily air temps
    [~,commonIdxAirTemps,~] = intersect(dailyAverageEverything_2.measurementDate,...
        commonDates);
    
    % now add the ibutton temp, snow thickness, ice thickness to their
    % vectors
    snowThick = [snowThick;currSnowThickness(commonIdxStakes)];
    iceThick = [iceThick;currIceThickness(commonIdxStakes)];
    interfaceTemp = [interfaceTemp;indivTemps(commonIdxIbuttons)];
    airTemp = [airTemp;dailyAverageEverything_2.airTemp(commonIdxAirTemps)];
    measurementDate = [measurementDate;commonDates];
    
    % now get the interpolated values sampled at each of the ibutton dates
    interpSnowThick = [interpSnowThick;...
        interp1(commonDates,currSnowThickness(commonIdxStakes),iButtons(i).date)];
    interpIceThick = [interpIceThick;...
        interp1(commonDates,currIceThickness(commonIdxStakes),iButtons(i).date)];
    interpAirTemp = [interpAirTemp;...
        interp1(hourlyTemp.measurementDate,hourlyTemp.temp,...
        iButtons(i).date)];
    interpMeasurementDate = [interpMeasurementDate; iButtons(i).date];
    interpInterfaceTemp = [interpInterfaceTemp;iButtons(i).temp];
    
    % also save the stake id
    stakeIDs = [stakeIDs;repmat(iButtons(i).stakeID,length(commonDates),1)];
    interpStakeIDs = [interpStakeIDs;...
        repmat(iButtons(i).stakeID,length(iButtons(i).date),1)];
end

% % plot temp vs. ice thick
% figure
% scatter(iceThick,interfaceTemp,'o','filled');
% title('Snow/ice interface temperature vs. ice thickness',...
%     'fontsize',titleFontSize);
% xlabel('Ice thickness (cm)',...
%     'fontsize',labelFontSize)
% ylabel('Interface temperature (ºC)',...
%     'fontsize',labelFontSize)
% box on
% grid on
% h = lsline;
% h.Color = 'k';
% h.LineWidth = 1;

% % plot temp vs. snow thick
% figure
% scatter(snowThick,interfaceTemp,'o','filled');
% title('Snow/ice interface temperature vs. snow thickness',...
%     'fontsize',titleFontSize);
% xlabel('Snow thickness (cm)',...
%     'fontsize',labelFontSize)
% ylabel('Interface temperature (ºC)',...
%     'fontsize',labelFontSize)
% box on
% grid on
% h = lsline;
% h.Color = 'k';
% h.LineWidth = 1;

% plot temp vs. air temp
figure
scatter(airTemp,interfaceTemp,'o','filled');
title('Snow/ice interface temperature vs. air temperature',...
    'fontsize',titleFontSize);
xlabel('Air temperature (ºC)',...
    'fontsize',labelFontSize)
ylabel('Interface temperature (ºC)',...
    'fontsize',labelFontSize)
box on
grid on
h = lsline;
h.Color = 'k';
h.LineWidth = 1;

%% calculate heat fluxes from temp profiles

% get the heat flux through the snow for each measurement:
% temperature gradient*thermal conductivity =
% (tAir - tInterface/snowThickness)*snowDensity

snowHeatFlux = ((airTemp - interfaceTemp)./(snowThick/100))*kEffective_snow;
snow_interpHeatFlux = ((interpAirTemp - interpInterfaceTemp)./(interpSnowThick/100))*kEffective_snow;

iceHeatFlux = ((interfaceTemp + 1.8)./(iceThick/100))*kEffective_ice;
ice_interpHeatFlux = ((interpInterfaceTemp + 1.8)./(interpIceThick/100))*kEffective_ice;



%% get the implied flux based on ice growth

iceGrowth_heatFlux = [];
iceGrowth_stakeIDs = [];
iceGrowth_dates = [];
indivStakes = unique(stakeIDs,'stable');

iceDifference = [];

% for every stake
for i = 1:length(indivStakes)
    
    % get its measurements
    currIceThick = iceThick(stakeIDs == indivStakes(i));
    currDates = measurementDate(stakeIDs == indivStakes(i));
    
    % get the shifted difference of the ice thickness array
    currIceDifference = diff(currIceThick)/100;
    
    % and the date array difference
    currDateDifference = diff(datenum(currDates));
    
    % calculate the average heat flux
    currHeatFlux = -(rhoIce * latentHeatFusion * currIceDifference * 1000)...
        ./(currDateDifference*86400);
    
    iceGrowth_heatFlux = [iceGrowth_heatFlux;currHeatFlux];
    iceGrowth_stakeIDs = [iceGrowth_stakeIDs;repmat(indivStakes(i),length(currIceDifference),1)];
    iceGrowth_dates = [iceGrowth_dates;currDates(2:end)];
    iceDifference = [iceDifference;currIceDifference];
end



%% Plot stuff up

% truncate to endDate
snowHeatFlux = snowHeatFlux((datenum(measurementDate) < endDate));
snow_interpHeatFlux = snow_interpHeatFlux(datenum(interpMeasurementDate) < endDate);

iceHeatFlux = iceHeatFlux(datenum(measurementDate) < endDate);
ice_interpHeatFlux = ice_interpHeatFlux(datenum(interpMeasurementDate) < endDate);

iceGrowth_heatFlux = iceGrowth_heatFlux(datenum(iceGrowth_dates) < endDate);
iceGrowth_stakeIDs = iceGrowth_stakeIDs(datenum(iceGrowth_dates) < endDate);
iceGrowth_dates = iceGrowth_dates(datenum(iceGrowth_dates) < endDate);

snowThick = snowThick(datenum(measurementDate) < endDate);
iceThick = iceThick(datenum(measurementDate) < endDate);
interfaceTemp = interfaceTemp(datenum(measurementDate) < endDate);
airTemp = airTemp(datenum(measurementDate) < endDate);
stakeIDs = stakeIDs(datenum(measurementDate) < endDate);
measurementDate = measurementDate(datenum(measurementDate) < endDate);

interpSnowThick = interpSnowThick(datenum(interpMeasurementDate) < endDate);
interpIceThick = interpIceThick(datenum(interpMeasurementDate) < endDate);
interpAirTemp = interpAirTemp(datenum(interpMeasurementDate) < endDate);
interpStakeIDs = interpStakeIDs(datenum(interpMeasurementDate) < endDate);
interpInterfaceTemp = interpInterfaceTemp(datenum(interpMeasurementDate) < endDate);
interpMeasurementDate = interpMeasurementDate(datenum(interpMeasurementDate) < endDate);



% hist(snowHeatFlux)
% title('Heat flux distribution (snow)',...
%     'fontsize',titleFontSize);
% xlabel('Heat flux (W m^{-2)',...
%     'fontsize',labelFontSize)
% box on
% grid on
figure
scatter(snowHeatFlux,iceHeatFlux,'o','filled');
title('Snow grad heat flux vs. ice grad heat flux',...
    'fontsize',titleFontSize);
xlabel('ice grad heat flux (W m^{-2})',...
    'fontsize',labelFontSize)
ylabel('snow grad flux (W m^{-2})',...
    'fontsize',labelFontSize)
box on
grid on
h = lsline;
h.Color = 'k';
h.LineWidth = 1;

% xlim([-60 20])
% ylim([-60 20])

[b.snowGradVsIceGrad,~,~,~,stats.snowGradVsIceGrad] = regress(snowHeatFlux,[ones(length(iceHeatFlux),1),...
    iceHeatFlux]);

refline(1,0)

figure
scatter(iceThick,snowHeatFlux,'o','filled')
title('Heat flux vs. ice thickness',...
    'fontsize',titleFontSize);
xlabel('Ice thickness (cm)',...
    'fontsize',labelFontSize)
ylabel('Heat flux (W m^{-1} ºK^{-1})',...
    'fontsize',labelFontSize)
box on
grid on
h = lsline;
h.Color = 'k';
h.LineWidth = 1;


% get the unique ids
indivStakes = unique(interpStakeIDs,'stable');

% get a new figure
figure
hold on

% for every stake
for i = 1:length(indivStakes)
    
    % get the the indices for the stake
    currIndices = find(interpStakeIDs==indivStakes(i));
    
    % plot the heat flux time series
    h = plot(interpMeasurementDate(currIndices),snow_interpHeatFlux(currIndices),'.-');
    h.MarkerFaceColor = get(h,'Color');
    
end

% label the plot
title('Surface heat flux time series (snow calculated)',...
    'fontsize',titleFontSize);
xlabel('Date',...
    'fontsize',labelFontSize)
ylabel('Heat flux (W m^{-2})',...
    'fontsize',labelFontSize)
legend("Stake "+ string([iButtons.stakeID]),...
    'fontsize', legendFontSize);
box on
grid on


% get a new figure
figure
hold on

% for every stake
for i = 1:length(indivStakes)
    
    % get the the indices for the stake
    currIndices = find(interpStakeIDs==indivStakes(i));
    
    % plot the heat flux time series
    h = plot(interpMeasurementDate(currIndices),ice_interpHeatFlux(currIndices),'.-');
    h.MarkerFaceColor = get(h,'Color');
    
end

% label the plot
title('Surface heat flux time series (ice calculated)',...
    'fontsize',titleFontSize);
xlabel('Date',...
    'fontsize',labelFontSize)
ylabel('Heat flux (W m^{-2})',...
    'fontsize',labelFontSize)
legend("Stake "+ string([iButtons.stakeID]),...
    'fontsize', legendFontSize);
box on
grid on

%% compare bias in ice calculated vs. snow calculated heat fluxes to snow thickness

% get the bias
fluxBias = (snow_interpHeatFlux - ice_interpHeatFlux);

% scatter the vs the snow thickness
figure
scatter(interpSnowThick,fluxBias,[],datenum(interpMeasurementDate),'o','filled')
title('Flux bias vs. snow thickness',...
    'fontsize',titleFontSize);
xlabel('Snow thickness (cm)',...
    'fontsize',labelFontSize)
ylabel('Flux bias (W m^{-2})',...
    'fontsize',labelFontSize)

box on
grid on
h = lsline;
h.Color = 'k';
h.LineWidth = 1;
col = colorbar;
datetick(col,'y')
% 
% [b,~,~,~,stats] = regress(fluxBias,[ones(length(interpSnowThick),1),...
%     interpSnowThick]);

%% plot the ice growth calculated heat flux

% get a list of individual stakes
indivStakes = unique(iceGrowth_stakeIDs,'stable');

% get a figure
figure
hold on

% for every stake
for i=1:length(indivStakes)
    
   % plot the heat flux against the date
   h = plot(iceGrowth_dates(iceGrowth_stakeIDs == indivStakes(i)),...
       iceGrowth_heatFlux(iceGrowth_stakeIDs==indivStakes(i)),'-o');
   h.MarkerFaceColor = get(h,'Color');
end

% label and adjust figure
title('Average heat flux due to ice growth',...
    'FontSize',titleFontSize,...
    'FontWeight','bold')
xlabel('Date','FontSize',labelFontSize)
ylabel('Heat flux (W m^{-2}','FontSize',labelFontSize)
legend(string(indivStakes),'fontsize',legendFontSize)

% copy the ice and snow calculated heat fluxes
iceHeatFlux_truncated = iceHeatFlux;
snowHeatFlux_truncated = snowHeatFlux;
stakeIDs_truncated = stakeIDs;
snowThick_truncated = snowThick;

% for every stake
for i = 1:length(indivStakes)
    
    % find the first occurrence of that stake in the stake IDs array
    deleteIdx = find(stakeIDs_truncated == indivStakes(i),1);
    
    % delete that row out of both arrays
    snowThick_truncated(deleteIdx) = []; 
    iceHeatFlux_truncated(deleteIdx) = [];
    snowHeatFlux_truncated(deleteIdx) = [];
    stakeIDs_truncated(deleteIdx) = [];
    
end

% plot ice growth calculated vs. the snow temp gradient calculated heat flux
figure
scatter(iceGrowth_heatFlux, snowHeatFlux_truncated,'o','filled')
title('Heat flux calculated from ice growth vs. heat flux calculated from snow temp gradient',...
    'fontsize',titleFontSize);
xlabel('Ice growth heat flux (W m^{-2})',...
    'fontsize',labelFontSize)
ylabel('Snow gradient heat flux(W m^{-2})',...
    'fontsize',labelFontSize)
box on
grid on
h = lsline;
h.Color = 'k';
h.LineWidth = 1;

refline(1,0);

[b.iceGrowthVsSnowGrad,~,~,~,stats.iceGrowthVsSnowGrad] = regress(iceGrowth_heatFlux,[ones(length(snowHeatFlux_truncated),1),...
    snowHeatFlux_truncated]);


% plot ice growth calculated vs. the ice temp gradient calculated heat flux
figure
scatter(iceGrowth_heatFlux, iceHeatFlux_truncated,'o','filled')
title('Heat flux calculated from ice growth vs. heat flux calculated from ice temp gradient',...
    'fontsize',titleFontSize);
xlabel('Ice growth heat flux (W m^{-2})',...
    'fontsize',labelFontSize)
ylabel('Ice gradient heat flux(W m^{-2})',...
    'fontsize',labelFontSize)
box on
grid on
h = lsline;
h.Color = 'k';
h.LineWidth = 1;

refline(1,0);

[b.iceGrowthVsIceGrad,~,~,~,stats.iceGrowthVsIceGrad] = regress(iceGrowth_heatFlux,[ones(length(iceHeatFlux_truncated),1),...
    iceHeatFlux_truncated]);

% plot ice growth heat flux vs snow thickness
figure
scatter(snowThick_truncated,iceGrowth_heatFlux,'o','filled');
title('Heat flux calculated from ice growth vs. snow thickness',...
    'fontsize',titleFontSize);
xlabel('Snow thickness (cm)',...
    'fontsize',labelFontSize)
ylabel('Ice gradient heat flux(W m^{-2})',...
    'fontsize',labelFontSize)
box on
grid on
h = lsline;
h.Color = 'k';
h.LineWidth = 1;


%% get the avg heat flux for each stake for a specific day

% define the date
pickDate = datetime('2020.01.24','inputformat','yyyy.MM.dd');

% get all of the measurements that match that date
snow_interpHeatFlux_singleDay = snow_interpHeatFlux(...
    (interpMeasurementDate.Month == pickDate.Month) &...
    (interpMeasurementDate.Day == pickDate.Day) &...
    (interpMeasurementDate.Year == pickDate.Year));

% and their associated IDs
interpStakeIDs_singleDay = interpStakeIDs(...
    interpMeasurementDate.Month == pickDate.Month &...
    interpMeasurementDate.Day == pickDate.Day &...
    interpMeasurementDate.Year == pickDate.Year);

% get the indiv stakes
indivStakes =  unique(interpStakeIDs_singleDay,'stable');

snow_interpHeatFlux_singleDay_avg = nan(length(indivStakes),1);

% now for every stake
for i=1:length(indivStakes)
    
    % get the average of the day's fluxes
    snow_interpHeatFlux_singleDay_avg(i) = mean(snow_interpHeatFlux_singleDay(...
        interpStakeIDs_singleDay == indivStakes(i)),'omitnan');
end
    