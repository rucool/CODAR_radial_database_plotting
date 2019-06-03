
clc
clear all
close all
 
tic

javaaddpath('/Users/roarty/Documents/GitHub/HJR_Scripts/Radial_Database/mysql-connector-java-5.1.6-bin.jar');

 year.num=2018:2018;
 year.str=num2str(year.num);

t1 = [year.str(1:4) '-6-1 00:00:00'];
t2 = [year.str(1:4) '-12-1 00:00:00'];% single year
% t2 = [year.str(end-4:end) '-12-31 00:00:00'];%multiple years

PattType = [2,3]; %2 = ideal; 3 = measured;
smoothFac = 10; %smoothing factor

%Connect to MySQL cool_ais database
host = 'mysql1.marine.rutgers.edu';
user = 'coolops';
password = 'SjR9rM';
dbName = 'coolops';
jdbcString = sprintf('jdbc:mysql://%s/%s', host, dbName);
jdbcDriver = 'com.mysql.jdbc.Driver';
dbConn = database(dbName, user , password, jdbcDriver, jdbcString);

regions={'01_PR'};

for jj=1:length(regions)
    
    n=regions{jj};

switch n
    case '01_PR'
        site = {'FURA','CDDO','FARO','PYFC','MABO'};
    
end

cmap = hsv(length(unique(site)));
cmap=[0 1 0;1 0 0]; % green, red


x_tick=datenum(year.num,6:12,1);
x_tick_label=[];
x_tick_minor=[];

for ii=1:length(year.num)
    temp=datenum(year.num(ii),1:4,1);
    x_tick_minor=[x_tick_minor  temp];
end

ymin=0;
ymax=2000;
y_interval=500;
   
    
for t = 1:length(site)
    
    plot_handle(t)=subplot(length(unique(site)),1,t);
    
    grid on
    box on
    hold on
    ylim([ymin ymax])
    xlim([datenum(t1) datenum(t2)])
    ylabel(site(t),'fontsize',10,'rot',00,'HorizontalAlignment','right')
    
    set(gca,'xtick',x_tick)
    set(gca,'xticklabel',x_tick_label)
    set(gca,'xminortick','on')
    set(gca,'ytick',ymin:y_interval:ymax,'fontsize',6)
    
    for kk=1:length(PattType)
        
        switch PattType(kk)
            case 2
                pattTypestr='Ideal';
            case 3
                pattTypestr='Meas';
        end
        
        getSiteId = ['SELECT id from hfrSites where site="' site{t} '"'];
        siteID = get(fetch(exec(dbConn, getSiteId)), 'Data'); siteID = siteID{1}; % get site ID number

        getVectors = ['SELECT TimeStamp,TableRows from hfrRadialFilesMetadata where Site=' num2str(siteID) ...
            ' and PatternType = ' num2str(PattType(kk)) ...
            ' and TimeStamp between ''' t1 ''' and ''' t2 ''''];

        vectors = get(fetch(exec(dbConn, getVectors)), 'Data');

       try

            times = datenum(vectors(:,1), 'yyyy-mm-dd HH:MM:SS.0');
            numVecs = cell2mat(vectors(:,2));

            %% determine which files have at least 100 vectors in the file
            numVecsMin=numVecs>100;


            numVecsSmoothed = smooth(numVecs, smoothFac);
        %     h(t) = plot(times, numVecsMin, '.', 'color', 'k','MarkerSize',10);%plot if the file exists
            h(kk) = plot(times, numVecs, '.', 'color', cmap(kk,:));%plot the number of vectors in the file
            %text(times(end)+5,1000,num2str(round2(mean(numVecs),1)))
       catch ME
           disp(ME)
       end
        
       clear times numVecs
    
    %set(gca,'yticklabel',[0 1000])

    end

end

%% format the x axis on the bottom subplot
subplot(length(unique(site)),1,t)
hold on
set(gca,'xticklabel',datestr(x_tick,'mmm'),'fontsize',10)
set(gca,'ytick',ymin:y_interval:ymax,'fontsize',6)
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
% title([pattTypestr ' Radial Vector Count ' year.str(1:4) ' to ' year.str(end-4:end)],'fontsize',12)
title([' Radial Vector Count Ideal (green) Measured (Red) ' year.str(1:4) ],'fontsize',12)

% maximizeSubPlots(plot_handle)

% timestamp(1,'plotRadialVecsFromDB_05.m')

%ht = legend (h,site,'Location','Best');

image_filename=['Radial_Vector_Count_' n '_' pattTypestr '_' year.str(1:4) '.png'];

 %% create the output directory and filename
conf.Plot.Filename = image_filename; 
conf.Plot.script='plotRadialVecsFromDB_PR)v2.m';
% conf.Plot.print_path = '/Users/roarty/COOL/01_CODAR/MARACOOS_II/20180201_2017_Reprocessing/20180524_Radial_Vector_Count_DB/';
% conf.Plot.print_path = '/Users/roarty/COOL/01_CODAR/MARACOOS_II/20180925_2018_Reprocessing/20181008_Radial_Vector_Count_DB/';
conf.Plot.print_path = '/Users/roarty/COOL/01_CODAR/02_Collaborations/Puerto_Rico/20181205_Progress_Report/';

timestamp(1,[conf.Plot.Filename ' / ' conf.Plot.script])

print(1,'-dpng','-r200',[conf.Plot.print_path  conf.Plot.Filename])

close all

end

toc
