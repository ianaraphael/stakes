% qa_snow.m

% Plots snow surface for all stakes in selected plot. Allows gui click
% to select suspicious points. Saves points out to text file.
% Intended for QA/QC process.

% Ian Raphael
% ian.th@dartmouth.edu
% 2021.03.08

clear
close all


cd("/Users/"+getenv('USER')+"/Desktop/Stakes")

addpath(genpath(pwd));

getThickness;

load("allStakes_timeSeries_withThicknessAndChange_QA_"+date+".mat")

titleFontSize = 20;
subtitleFontSize = 16;
labelFontSize = 14;
legendFontSize = 12;

% choose site to plot
% 1 - Bow Stakes/dart_stakes_clu_1
% 2 - Stakes 2/dart_stakes_clu_2
% 3 - Stakes 3/dart_stakes_clu_3
% 4 - Stakes 1/dart_stakes_clu_4
% 5 - MET Stakes/dart_stakes_clu_5
% 6 - Ridge Ranch/dart_stakes_clu_6
% 7 - Runaway Stakes/dart_stakes_clu_7
% 8 - Miss Stakes/dart_stakes_clu_8
% 9 -
% 9 - Return of the MET Stakes/dart_stakes_clu_10
% 10 - Drone Bones/dart_stakes_clu_11
% 11 - Reunion Stakes/dart_stakes_clu_12
% 12 - Beanpole Stakes/dart_stakes_clu_13
% 14 -

site = 13;

% get all of the individual sites
indivSites = unique(allStakes.siteName,'stable');

ax=gobjects(2,1);

% get the individual stakes
indivStakes = unique(allStakes.stakeID(allStakes.siteName == indivSites(site)));

% get a figure
f = figure;
t = tiledlayout(1,1);
qaData.susPoints = [];
qaData.siteName = indivSites(site);
guidata(f,qaData);

% title the figure
title(qaData.siteName,'FontSize',titleFontSize);

% get the first tile
nexttile;
hold on

ax(1) = gca;
ax(1).LineStyleOrder = {'-o','-s','-^'};

% for every stake
for i2 = 1:length(indivStakes)
    
    % plot the bottom measurement
    l = plot(datenum(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2))),...
        allStakes.snowSurfaceMeasurement(allStakes.stakeID==indivStakes(i2)),'tag',sprintf('stake %d',indivStakes(i2)));
    l.MarkerFaceColor = l.Color;
end

datacursormode on
dcm = datacursormode(gcf);
set(dcm,'UpdateFcn',@myupdatefcn);

datetick('x','mmm dd');

grid on
box on

% do some titling
title('Relative snow surface position','FontSize',subtitleFontSize);
ylabel('Position (cm)','FontSize',subtitleFontSize,'FontWeight','Bold')
xlabel('Date','FontSize',subtitleFontSize,'FontWeight','Bold')
legend(string(indivStakes),'FontSize',legendFontSize,'Location','eastoutside');
% 
% % get another tile
% nexttile;
% hold on
% 
% ax(2) = gca;
% ax(2).LineStyleOrder = {'-o','-s','-^'};
% 
% % for every stake
% for i2 = 1:length(indivStakes)
%     
%     % plot the bottom change rate
%     l = plot(datenum(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2))),...
%         allStakes.bottomChangeRate(allStakes.stakeID==indivStakes(i2)));
%     l.MarkerFaceColor = l.Color;
% end
% 
% grid on
% box on
% 
% datetick('x','mmm dd');
% 
% title('Bottom growth/melt rate','FontSize',subtitleFontSize);
% ylabel('Rate of growth/melt (cm d^{-1})','FontSize',labelFontSize,'FontWeight','Bold')
% xlabel('Date','FontSize',labelFontSize,'FontWeight','Bold')
% legend(string(indivStakes),'FontSize',legendFontSize,'Location','eastoutside');
% 
% 
% % plot a refline
% hline = plot([datenum(min(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))-5)...
%     datenum(max(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))+5)],[0 0]);
% hline.Color = 'k';
% hline.LineWidth = 0.75;
% hline.LineStyle = '-.';
% hline.Marker = 'none';
% uistack(hline,'bottom');
% 
% 
% set(get(get(hline,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');

% xlim(ax,[datenum(min(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))-5)...
%     datenum(max(allStakes.measurementDate(allStakes.stakeID==indivStakes(i2)))+5)]);

waitfor(msgbox('Are you done yet?'));
qaData = guidata(f);

writematrix(qaData.susPoints,pwd+"/1. Data/"+"qaPointsTop_"+replace(qaData.siteName,"/","-")+"-"+string(date)+".csv");


function txt = myupdatefcn(src,event)

qaData = guidata(src);

pos = get(event,'Position');
dts = string(get(event.Target,'Tag'));

if strcmp(questdlg('Keep data point from stake '+dts+'?'),'Yes')==0
    return
end

txt = [dts,string(datetime(pos(1),'ConvertFrom','datenum')),string(inputdlg('Measurement note: '))];

qaData.susPoints = [qaData.susPoints;txt];

%qaData.susPoints(:,1:2) = [qaData.susPoints(:,1:2);txt];
%qaData.susPoints(:,3) = [qaData.susPoints(:,3);note];
guidata(src,qaData)
qaData.susPoints

end
