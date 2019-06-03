
clc
clear all
close all
 
tic

% javaaddpath('/Users/roarty/Documents/MATLAB/HJR_Scripts/radial_database/mysql-connector-java-5.1.6-bin.jar');

javaaddpath('/Users/roarty/Documents/MATLAB/HJR_Scripts/radial_database/mysql-connector-java-8.0.13/mysql-connector-java-8.0.13.jar')

 year.num=2018:2018;
 year.num=year.num';
 year.str=num2str(year.num);
 year.str=cellstr(year.str);

t1 = [year.str{1} '-6-1 00:00:00'];
t2 = [year.str{end} '-12-1 00:00:00'];


region='CARA';
site = {'FURA','CDDO','FARO','PYFC','MABO'};
site_label = {'FURA      ','CDDO      ','FARO      ','PYFC      ','MABO      '};
%site = {'NANT'};
pattType = 2; %2 = ideal; 3 = measured;
smoothFac = 1; %smoothing factor

switch pattType
    case 2
        pattTypestr='Ideal';
    case 3
        pattTypestr='Meas';
end


%Connect to MySQL cool_ais database
host = 'mysql1.marine.rutgers.edu';
user = 'coolops';
password = 'SjR9rM';
dbName = 'coolops';
jdbcString = sprintf('jdbc:mysql://%s/%s', host, dbName);
% jdbcDriver = 'com.mysql.jdbc.Driver';
jdbcDriver = 'com.mysql.cj.jdbc.Driver';
dbConn = database(dbName, user , password, jdbcDriver, jdbcString);


cmap = hsv(length(unique(site)));

x_tick_label=[];

x_tick=[datenum(year.num(1),1:12,1) datenum(year.num(end),1:12,1)];

x_tick_minor=[];

for ii=1:length(year.num)
    temp=datenum(year.num(ii),1:12,1);
    x_tick_minor=[x_tick_minor  temp];
end

ymin=0.5;
ymax=1.5;

for t = 1:length(site)
    getSiteId = ['SELECT id from hfrSites where site="' site{t} '"'];
    siteID = get(fetch(exec(dbConn, getSiteId)), 'Data'); siteID = siteID{1}; % get site ID number

    getVectors = ['SELECT TimeStamp,TableRows from hfrRadialFilesMetadata where Site=' num2str(siteID) ...
        ' and PatternType = ' num2str(pattType) ...
        ' and TimeStamp between ''' t1 ''' and ''' t2 ''''];

    vectors = get(fetch(exec(dbConn, getVectors)), 'Data');
    
    plot_handle(t)=subplot(length(unique(site)),1,t);
    
    grid on
    hold on
    ylim([ymin ymax])
    xlim([datenum(t1) datenum(t2)])
    ylabel(site(t),'fontsize',10,'rot',00,'HorizontalAlignment','right')
    
    set(gca,'xtick',x_tick)
    set(gca,'xticklabel',x_tick_label)
    
    set(gca,'ytick',[ ])
    
    try
        
    times = datenum(vectors(:,1), 'yyyy-mm-dd HH:MM:SS.0');
    numVecs = cell2mat(vectors(:,2));
    
    %% determine which files have at least 100 vectors in the file
    numVecsMin=numVecs>100;
    
    
    numVecsSmoothed = smooth(numVecs, smoothFac);
    h(t) = plot(times, numVecsMin, '.', 'color', 'k','MarkerSize',10);
    %text(times(end)+5,1000,num2str(round2(mean(numVecs),1)))
    
    
    catch
    end
    
    %set(gca,'yticklabel',[0 1000])

end

%% format the x axis on the bottom subplot
subplot(length(unique(site)),1,t)
hold on
set(gca,'xticklabel',datestr(x_tick,'mmm'),'fontsize',10)
set(gca,'xminortick','on')
% set(gca,'xtick',x_tick_minor)

% % specify the minor grid vector
% xg = x_tick_minor;
% % specify the Y-position and the height of minor grids
% yg = [ymin ymin+(ymax-ymin)*.1];
% xx = reshape([xg;xg;NaN(1,length(xg))],1,length(xg)*3);
% yy = repmat([yg NaN],1,length(xg));
% h_minorgrid = plot(xx,yy,'k');

%% add the title on the top subplot 
subplot(length(unique(site)),1,1)
title([pattTypestr ' Radial Vector Count ' year.str{1} ' to ' year.str{end}],'fontsize',12)
% title([pattTypestr ' Radial Vector Count ' year.str(1:4)],'fontsize',12)

% maximizeSubPlots(plot_handle)

%% create the output directory and filename
conf.Plot.Filename = ['Radial_Vector_Count_' region '_' pattTypestr '_' year.str{1} '_' year.str{end} '.png'];
conf.Plot.script='plotRadialVecsFromDB_PR.m';
% conf.Plot.print_path = '/Users/hroarty/COOL/01_CODAR/02_Collaborations/Puerto_Rico/20171130_Progress_Report/';
% conf.Plot.print_path = '/Users/hroarty/COOL/01_CODAR/02_Collaborations/Puerto_Rico/20180531_Progress_Report/';
conf.Plot.print_path = '/Users/roarty/COOL/01_CODAR/02_Collaborations/Puerto_Rico/20181205_Progress_Report/';

timestamp(1,[conf.Plot.Filename ' / ' conf.Plot.script])

print(1,'-dpng','-r300',[conf.Plot.print_path  conf.Plot.Filename])



toc
