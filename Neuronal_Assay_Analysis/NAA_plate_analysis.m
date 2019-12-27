well_names={'A1','A2','A3','A4','A5','A6','B1','B2','B3','B4','B5','B6','C1','C2','C3','C4','C5','C6','D1','D2','D3','D4','D5','D6'};

master_result=cell(24,1);
for i=1:24
    file=dir(['*',well_names{i},'*.mat']);
    if ~isempty(file)
        S=load(file.name);
        master_result{i}=S;
%         center=[S.cell_list.center];
%         distmat=squareform(pdist(center'));
%         n_nearby=sum(distmat<50)-1;
%         master_result{i}.n_nearby=n_nearby;
    end
end
%% display raw images

figure
for i=1:24
    if ~isempty(master_result{i})
        subplot(4,6,i);
        overlay=NAA_create_overlay(master_result{i}.GCaMPbase,master_result{i}.mCherry);
        image(overlay);axis image;
    end
end
%% display segmentation
figure;
for i=1:24
    if ~isempty(master_result{i})
        subplot(4,6,i);
        NAA_displayROI(master_result{i}.cell_list);
        axis image;
    end
end
%% display df_fmap
figure;
stim_ind=3;
for i=1:24
    if ~isempty(master_result{i})
        subplot(4,6,i);
        h=fspecial('gaussian',5,1);
        map=mean(master_result{i}.df_fmap(:,:,stim_ind),3);
        map=filter2(h,map);
        imagesc(map);
        axis image;set(gca,'clim',[0,1]);
    end
end

%% display response curve
figure;
nAP=[1,2,3,5,10,20,40,80,160];
for i=1:24
    if ~isempty(master_result{i})
        subplot(4,6,i);
        df_fpeak=[master_result{i}.para_array.df_fpeak];
        df_fpeak=reshape(df_fpeak,size(master_result{i}.para_array));
        errorbar(nAP,mean(df_fpeak(1:9,:),2),std(df_fpeak(1:9,:),0,2)/sqrt(size(df_fpeak,2)));       
        xlim([0,160]);
        ylim([0,6]);
%         errorbar([1,2,3],mean(df_fpeak(1:3,:),2),std(df_fpeak(1:3,:),0,2)/sqrt(size(df_fpeak,2)));       
%         hold on;
%         errorbar([1,2,3],mean(df_fpeak(4:6,:),2),std(df_fpeak(4:6,:),0,2)/sqrt(size(df_fpeak,2)),'r');
%         ylim([0,4])
        
    end
end

%% display mean median traces
figure;
nTime=length(master_result{1}.para_array(1).df_f);
stim_ind=3;
for i=1:24
    if ~isempty(master_result{i})
        nTime=length(master_result{i}.para_array(1).df_f)
        nROI=size(master_result{i}.para_array,2);
        nStim=9;
        
        
        subplot(4,6,i);
        df_f=[master_result{i}.para_array.df_f];
        
        df_f=reshape(df_f,[nTime,nStim,nROI]);
        
        
        plot(mean(df_f(:,stim_ind,:),3));
        hold on;
        plot(median(df_f(:,stim_ind,:),3),'r')
        ylim([0,1])
        xlim([0,200]);
    end

end
%%
figure;
ncell=[];
df_fpeak_pile=[];
stim_ind=1;
for i=1:24    
    if ~isempty(master_result{i})
%         df_fpeak=[master_result{i}.para_array.df_fpeak];
%         df_fpeak=reshape(df_fpeak,size(master_result{i}.para_array));
%         cell_list=master_result{i}.cell_list;
%         center=[cell_list.center];
%         distmat=squareform(pdist(center'));
%         ncell_well=sum(distmat<50)-1;
%         ncell=[ncell,ncell_well];
%         
%         df_fpeak_pile=[df_fpeak_pile,df_fpeak];
        
        subplot(4,6,i);hold on;
        a=unique(master_result{i}.n_nearby);
        df_fpeak=[master_result{i}.para_array.df_fpeak];
        df_fpeak=reshape(df_fpeak,size(master_result{i}.para_array));
        n_nearby=master_result{i}.n_nearby;
        for j=1:length(a)
            ind=(n_nearby==a(j));
            plot(n_nearby(ind),df_fpeak(stim_ind,ind),'.')
            errorbar(a(j),mean(df_fpeak(stim_ind,ind),2),std(df_fpeak(stim_ind,ind))/sqrt(sum(ind)),'or');
            xlim([0,40]);
            ylim([0,3]);
           
        end
%         title([well_names{i},' (',num2str(size(df_fpeak,2)),'cells)'])
    end
end


%%
figure;
ncell=[];
df_fpeak_pile=[];
for i=1:24    
    if ~isempty(master_result{i})
       subplot(4,6,i);
       mCherry=[master_result{i}.cell_list.mCherry];
       
       GCaMP_total=[master_result{i}.cell_list.GCaMP_total];
       df_fpeak=[master_result{i}.para_array.df_fpeak];
       df_fpeak=reshape(df_fpeak,size(master_result{i}.para_array));
       
       ind=(mCherry<3000);
       
       nTime=length(master_result{i}.para_array(1).df_f);
       nROI=size(master_result{i}.para_array,2);
       nStim=9;
       
       
       df_f=[master_result{i}.para_array.df_f];
       df_f=reshape(df_f,[nTime,nStim,nROI]);
       low=mean(squeeze(df_f(:,5,ind)),2);
       high=mean(squeeze(df_f(:,5,~ind)),2);
%         
       plot(low/max(low),'r');
       hold on;
       plot(high/max(high),'b');
       
    
%        plot(low,'r');
%        hold on;
%        plot(high,'b');
%        
% 
%        plot(mCherry,df_fpeak(5,:),'.')
%        %plot(GCaMP_total,df_fpeak(5,:),'.')
%        xlim([0,8000]);ylim([0,1]);
    end
end

