function [mutant_data,mutant_data_norm,control_data,control_data_norm]=NAA_pile_mutants(string)
% function mutant_data=NAA_pile_mutants()
tic
% path='Z:\GECI Pipeline\NAA_result_db\';
% path='D:\Neuronal_culture\NAA_compare_mutant(01122011_for Janelia Symposium)\Compare mutants\';

% date_mcherry_change=datenum('20110328','yyyymmdd');

path='D:\Neuronal_culture\NAA_Database\';
% path='D:\Neuronal_culture\NAA_Database\New folder\';

if isempty(string)
    files=dir([path,'*.mat']);
elseif iscell(string)
    files=[];
    for i=1:length(string)
        files=[files;dir([path,'*',string{i},'*.mat'])];
    end
else     
    files=dir([path,'*',string,'*.mat']);
end
nwell=length(files);
master_result={};%cell(nwell,1);
construct={};%cell(nwell,1);
plate={};%cell(nwell,1);
fullname={};%cell(nwell,1);
h = waitbar(0,'Loading Data') ;
for i=1:nwell    
    S=load([path,files(i).name],'summary','cell_list','fmean','temperature1','temperature2','para_array');
%     S=load([path,files(i).name],'cell_list','fmean','bg','ephus_info','temperature1','temperature2','para_array');
    info=NAA_file_info(files(i).name);    
    
     
    if length(S.cell_list)>1
        master_result{end+1}=S;
        construct{end+1}=info.buffer;    
        plate{end+1}=info.plate;
        fullname{end+1}=[info.buffer];%,'_',info.plate];
    end
%     center=[S.cell_list.center];
%     distmat=squareform(pdist(center'));
%     n_nearby=sum(distmat<50)-1;
%     master_result{i}.n_nearby=n_nearby;
    waitbar(i/nwell)
end

close(h)
toc
%%
load([path,'coef.xsg'],'-mat');
unique_name=unique(fullname);
mutant_data=[];
for i=1:length(unique_name)    
    ind=find(strcmp(fullname,unique_name{i}));
    
    well_data=[master_result{ind}];
    summary=[well_data.summary];
    t1=reshape([well_data.temperature1],9,[]);
%     t1=[well_data.temperature2];
    SS=[];
    SS.construct=construct{ind(1)};
    
    SS.fullname=fullname{ind(1)};
    SS.nreplicate=length(ind);
    SS.df_fpeak_med=reshape([summary.df_fpeak_med],9,[]);
    
    SS.decay_half_med=reshape([summary.decay_half_med],9,[]);
    
    SS.rise_half_med=reshape([summary.rise_half_med],9,[]);
    SS.timetopeak_med=reshape([summary.timetopeak_med],9,[]);
    SS.temperature1=t1(1,:);
    
    factor=(29*-0.0633+2.495)./(SS.temperature1*-0.0633+2.495);
% factor=1;
    SS.decay_half_med_comp=SS.decay_half_med(5,:).*factor;
    
    SS.f0=reshape([summary.f0],9,[]);
    SS.f0=SS.f0(3,:);
    fmean_med=[];
    df_f_med=[];
    df_fnoise=[];
    for j=1:length(ind)
        SS.plate{j}=plate{ind(j)};
        c=textscan(SS.plate{j},'%s','delimiter','-');
        SS.date{j}=c{1}{2};
%         datenumber=datenum(SS.date{j},'yyyymmdd');
%         if datenumber>=date_mcherry_change
%             SS.mCherry(j)=mean([well_data(j).cell_list.mCherry]);
%             SS.mCherry_corrected(j)=0;
%         else
%             SS.mCherry(j)=mean([well_data(j).cell_list.mCherry])*0.236-95;
%             SS.mCherry_corrected(j)=1;
%         end
        SS.mCherry(j)=mean([well_data(j).cell_list.mCherry]);
        SS.nSegment(j)=length([well_data(j).cell_list]);     
        df_f=[well_data(j).para_array.df_f];
        df_f=reshape(df_f,size(df_f,1),9,[]);
        df_f_med=cat(3,df_f_med,median(df_f,3));
        
        df_fnoise=[df_fnoise,mean(squeeze(std(df_f(1:25,:,:))),2)];
        
        fmean=[well_data(j).fmean];
        fmean_med=cat(3,fmean_med,squeeze(median(fmean,3)));
        
    end
    SS.fmean_med=fmean_med;
    SS.df_f_med=df_f_med;
    SS.df_fpeak_med_comp=NAA_compensate(SS.nSegment,SS.df_fpeak_med,coef);   
    SS.df_fnoise=df_fnoise;
%     SS.df_fpeak_med_comp=SS.df_fpeak_med;  
    mutant_data=[mutant_data,SS];
end
    
% %%
% mutant_data_norm=mutant_data;
% unique_date=unique({mutant_data.date});
% control_ind=[];
% 
% for i=1:length(unique_date)
%     ctr_ind=find(strcmp({mutant_data_norm.date},unique_date{i}) & (strcmp({mutant_data_norm.construct},'10dot1')));    
%     control=mutant_data_norm(ctr_ind);   
%     all_ind=find(strcmp({mutant_data_norm.date},unique_date{i}));
%     for j=1:length(all_ind)
%         mutant_data_norm(all_ind(j)).df_fpeak_med=mutant_data_norm(all_ind(j)).df_fpeak_med ./ repmat(median([control.df_fpeak_med],2),[1,mutant_data_norm(all_ind(j)).nreplicate]);
%         mutant_data_norm(all_ind(j)).decay_half_med=mutant_data_norm(all_ind(j)).decay_half_med ./ repmat(median([control.decay_half_med],2),[1,mutant_data_norm(all_ind(j)).nreplicate]);
%         mutant_data_norm(all_ind(j)).rise_half_med=mutant_data_norm(all_ind(j)).rise_half_med ./ repmat(median([control.rise_half_med],2),[1,mutant_data_norm(all_ind(j)).nreplicate]);
%         mutant_data_norm(all_ind(j)).timetopeak_med=mutant_data_norm(all_ind(j)).timetopeak_med ./ repmat(median([control.timetopeak_med],2),[1,mutant_data_norm(all_ind(j)).nreplicate]);
%         mutant_data_norm(all_ind(j)).f0=mutant_data_norm(all_ind(j)).f0 / median(control.f0);
%         mutant_data_norm(all_ind(j)).mCherry=mutant_data_norm(all_ind(j)).mCherry / median(control.mCherry);
%         control_ind(all_ind(j))=ctr_ind;
%     end
%         
% end
% control_data=mutant_data(control_ind);
% control_data_norm=mutant_data_norm(control_ind);

end
