% function coef=NAA_compensation_curve
path='D:\Neuronal_culture\NAA_Database\TxRed_10xSmaller_Exposure\';
% path='D:\Neuronal_culture\GCaMP_Stability_Cell_Density_Expression\'
list=dir([path,'*.mat']);


master_result=[];
count=1;
df_fpeak_med=[];
mCherry_med=[];
nsegment=[];
for i=1:length(list)
    fields=textscan(list(i).name,'%s','delimiter','_');
    if strcmp(fields{1}{3},'10dot1')
        load([path,list(i).name],'para_array','cell_list','summary');        
        mCherry_med(count)=median([cell_list.mCherry]);
        nsegment(count)=length(cell_list);
        df_fpeak_med(count,:)=summary.df_fpeak_med;
        count=count+1;        
    end
end



nsegment=nsegment';
mCherry_med=mCherry_med';

coef=[nsegment,ones(length(nsegment),1)]\df_fpeak_med;

ind=[3,5,9];
figure;
for i=1:3
    subplot(1,3,i)
    plot(nsegment,df_fpeak_med(:,ind(i)),'.');hold on;
    plot(nsegment,nsegment*coef(1,ind(i))+coef(2,ind(i)),'r')       
end
coef(1,5)
% save([path,'coef.xsg'],'coef');


% figure;plot(nsegment,