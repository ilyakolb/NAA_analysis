% base_dir=uipickfiles;
% 
% 
% %%
% valid_dir=[];
% for i=1:length(base_dir)
%     plate_dir=dir([base_dir{i},filesep,'P*']);
%     for j=1:length(plate_dir)
%         files=dir([base_dir{i},filesep,plate_dir(j).name,filesep,'imaging',filesep,'results',filesep,'*Summary.mat']);
%         if length(files)>6
%             temp.plate_name=plate_dir(j).name;
%             temp.base_dir=base_dir{i};
%             temp.full_dir=[base_dir{i},filesep,plate_dir(j).name,filesep,'imaging',filesep,'results'];
%             temp.nfile=length(files);
%             valid_dir=[valid_dir,temp];
%         end
%     end
% end

    
%%

well_names={'A1','A2','A3','A4','A5','A6','B1','B2','B3','B4','B5','B6','C1','C2','C3','C4','C5','C6','D1','D2','D3','D4','D5','D6'};

for k=1:length(valid_dir)
    
    master_result=cell(24,1);
    for i=1:24
        file=dir([valid_dir(k).full_dir,filesep,'*',well_names{i},'_*.mat']);
        if ~isempty(file)
            S=load([valid_dir(k).full_dir,filesep,file(1).name],'GCaMPbase','mCherry','cell_list');
            master_result{i}=S;
            center=[S.cell_list.center];
            distmat=squareform(pdist(center'));
            n_nearby=sum(distmat<50)-1;
            master_result{i}.n_nearby=n_nearby;
        end
    end
    

    h=figure('position',[1,1,1600,1200]);
    for i=1:24
        if ~isempty(master_result{i})
            subplot(4,6,i);
            overlay=NAA_create_overlay(master_result{i}.GCaMPbase,master_result{i}.mCherry);
            image(overlay);axis image;
            title([well_names{i},' Cavg= ',num2str(mean(master_result{i}.n_nearby),'%0.1f'),' Cmax= ',num2str(max(master_result{i}.n_nearby))]);
        end
    end
    
    saveppt('junk.ppt',valid_dir(k).plate_name);
    delete(h);
    
end