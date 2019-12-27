well_names={'A1','A2','A3','A4','A5','A6','B1','B2','B3','B4','B5','B6','C1','C2','C3','C4','C5','C6','D1','D2','D3','D4','D5','D6'};
    
master_result=cell(24,1);
    for i=1:24
        file=dir(['*',well_names{i},'_*.mat']);
        if ~isempty(file)
            a=textscan(file.name,'%s','delimiter','_');
            plate_name=a{1}{1};
            S=load([file(1).name],'CFP_base','mCherry','cell_list','summaryRatio','dr_rmap');
            master_result{i}=S;
%             center=[S.cell_list.center];
%             distmat=squareform(pdist(center'));
%             n_nearby=sum(distmat<50)-1;
%             master_result{i}.n_nearby=n_nearby;
        end
    end
    
%%

h1=figure('position',[1,1,1600,1200]);


for i=1:24
    if ~isempty(master_result{i})
        subplot(4,6,i);
        overlay=NAA_create_overlay(master_result{i}.CFP_base,master_result{i}.mCherry);
        image(overlay);axis image;
        title([well_names{i},' dff10=',num2str(master_result{i}.summaryRatio.df_fpeak(5),'%0.2f')]);
    end
end

saveppt([plate_name,'.ppt'],plate_name);
delete(h1);

nAP=[1,2,3,5,10,20,40,80,160];
clim_high=[0.3,0.5,0.7,0.9,1.5,3,4,6,7];
for k=1:length(nAP)

    
    h2=figure('position',[1,1,1600,1200]);
    for i=1:24
        if ~isempty(master_result{i})
            subplot(4,6,i);
            imagesc(master_result{i}.dr_rmap(:,:,k));axis image;set(gca,'clim',[0,clim_high(k)]);
            title([well_names{i},'  ',num2str(nAP(k)),'FP']);
        end
    end
    saveppt([plate_name,'.ppt'],plate_name);
    delete(h2);


end
