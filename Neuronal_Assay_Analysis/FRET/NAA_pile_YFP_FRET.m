% title={'Plate','Well','ROI#','F0','df_fpeak (1AP)','df_fpeak(2AP)','df_fpeak(3AP)','df_fpeak(5AP)','df_fpeak (10AP)','df_fpeak(20AP)','df_fpeak(40AP)','df_fpeak(80AP)','df_fpeak(160AP)','decay half (10AP)','decay half (160AP)'};
xlstitle={'Plate','Well','construct','ROI#','mCherry','F0','Fmax','norm F0','dff(1AP)','dff(2AP)','dff(3AP)','dff(5AP)','dff(10AP)','dff(20AP)','dff(40AP)','dff(80AP)','dff(160AP)','drr(max)','ES50','DT1/2(10AP)','RT1/2(10AP)','tpeak(10AP)','DT1/2(160AP)','T1','T2'};

M=xlstitle;

files=dir('*.mat');
data_size=0;%length(files);
nAP=[1,2,3,5,10,20,40,80,160];
for i=1:length(files);
    load(files(i).name,'para_arrayYFP','summaryYFP','cell_list','temperature1','temperature2','fmax');    
    para_array=para_arrayYFP;
    summary=summaryYFP;
    [tok,remain]=strtok(files(i).name,'_');
    plate=tok;
    [tok,remain]=strtok(remain,'_');
    well=tok;
    [tok,remain]=strtok(remain,'_');
    construct=tok;
    nROI=length(cell_list);
    if nROI>1
        ES50=NAA_get_es50(summary.df_fpeak_med,nAP);
        f0=[para_array(2,:).f0];
        
        if ~exist('fmax')
            fmax=zeros(size(cell_list));
            dff_max=zeros(size(cell_list));
        else
            if ~isempty(fmax)
                dff_max=(fmax-f0)./f0;
            else
                fmax=zeros(size(cell_list));
                dff_max=zeros(size(cell_list));
            end
        end
        entry={plate,well,construct,nROI,mean([cell_list.mCherry]),summary.f0(2),median(fmax),summary.f0(2)/mean([cell_list.mCherry]),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),summary.df_fpeak_med(5),summary.df_fpeak_med(6),summary.df_fpeak_med(7),summary.df_fpeak_med(8),summary.df_fpeak_med(9),median(dff_max),ES50,summary.decay_half_med(5),summary.rise_half_med(5),summary.timetopeak_med(5),summary.decay_half_med(9),temperature1(1),temperature2(1)};
    
%     entry={plate,well,nROI,summary.f0(1),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),summary.df_fpeak_med(5),summary.df_fpeak_med(6),summary.df_fpeak_med(7),summary.df_fpeak_med(8),summary.df_fpeak_med(9),summary.decay_half_med(5),summary.decay_half_med(9)};
        M=[M;entry];
        data_size=data_size+1;
    end
    clear fmax;
end

name=unique({M{2:end,3}});
M1=M;
M=M1(1,:);
for i=1:length(name)
    ind=strcmp({M1{1:(data_size+1),3}},name{i});
    M=[M;M1(ind,:)];
end

M=[M;cell(3,size(M,2))];

for i=1:length(name)
    ind=strcmp({M{1:(data_size+1),3}},name{i});
    entry={name{i},M{2,1},sum(ind),};
    for j=4:25
        entry{j}=median([M{ind,j}]);
    end
    M=[M;entry];
end
M=[M;cell(3,size(M,2))];
for i=1:length(name)
    ind=find(strcmp({M{1:(data_size+1),3}},name{i}));
    entry={[],[],[name{i},'_SEM']};
    for j=4:25
        entry{j}=std([M{ind,j}])/sqrt(length(ind));        
    end
    M=[M;entry];
end
M1=[M(:,1:18),cell(size(M,1),1),M(:,19:end)];
xlswrite(['NAA_result_',plate,'YFP.xls'],M1);

% NAA_display_Plate;

% %%
% 
% xlstitle={'construct','ROI#','mCherry','F0','norm F0','df_fpeak(3AP)','df_fpeak (10AP)','df_fpeak(160AP)','decay half (10AP)','peak time(10AP)','temperature1'};
% 
% M2=xlstitle;
% 
% for i=1:length(name)
%     ind=strcmp({M{1:(data_size+1),3}},name{i});
%     entry={[],[],name{i}};
%     for j=1:22
%         entry{j}=median([M{ind,j}]);
%     end
%     M=[M;entry];
% end
% M=[M;cell(3,size(M,2))];
% for i=1:length(name)
%     ind=strcmp({M{1:(data_size+1),3}},name{i});
%     entry={[],[],[name{i},'_SEM']};
%     for j=4:22
%         entry{j}=std([M{ind,j}])/sqrt(length(ind));        
%     end
%     M=[M;entry];
% end
% 
% xlswrite(['NAA_result_',plate,'.xls'],M);
