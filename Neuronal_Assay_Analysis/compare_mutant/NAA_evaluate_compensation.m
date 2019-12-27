% function coef=NAA_compensation_curve

path='D:\Neuronal_culture\NAA_Database\';
% path='D:\Neuronal_culture\NAA_compare_CNQXCPP\10dot1_doubleCNQXCPP\';
% path='D:\Neuronal_culture\NAA_compare_CNQXCPP\10dot1_10uMCNQXCPP\';

list=dir([path,'*10dot1_*.mat']);
fullname={};
platename={};
df_fpeak_med=[];
nsegment=[];
mCherry_med=[];
for i=1:length(list)
    fullname{end+1}=[path,list(i).name];
    fields=textscan(list(i).name,'%s','delimiter','_');
    platename{end+1}=fields{1}{1};
    
    load([path,list(i).name],'cell_list','summary');
    nsegment(end+1)=length(cell_list);
    df_fpeak_med(end+1,:)=summary.df_fpeak_med;    
end

nsegment=nsegment';
platename=platename(nsegment<100);
df_fpeak_med=df_fpeak_med(nsegment<100,:);
nsegment=nsegment(nsegment<100);
%%
coef=[nsegment,ones(length(nsegment),1)]\df_fpeak_med;
df_fpeak_med_comp=NAA_compensate(nsegment',df_fpeak_med',coef)';

ind=[3,5,9];
figure;
for i=1:3
    subplot(1,3,i)
    plot(nsegment,df_fpeak_med(:,ind(i)),'.');hold on;
    plot(nsegment,nsegment*coef(1,ind(i))+coef(2,ind(i)),'r')     
    ylim([0,max(df_fpeak_med(:,ind(i)))]);
    r=corrcoef(nsegment,df_fpeak_med(:,ind(i)));
    text(30,max(df_fpeak_med(:,ind(i)))*0.9,['r=',num2str(r(1,2))]);
    
end

figure;
coef2=[nsegment,ones(length(nsegment),1)]\df_fpeak_med_comp;
for i=1:3
    subplot(1,3,i)
    plot(nsegment,df_fpeak_med_comp(:,ind(i)),'.');hold on;   
    plot(nsegment,nsegment*coef2(1,ind(i))+coef2(2,ind(i)),'r')     
    ylim([0,max(df_fpeak_med(:,ind(i)))]);
end


%%
uni_plate=unique(platename);
figure;hold on;
variable=df_fpeak_med;
stim_idx=5;
ymax=2;
for i=1:length(uni_plate)
    idx=(strcmp(platename,uni_plate{i}));    
    g1=variable(idx,stim_idx);
    g2=variable(~idx,stim_idx);
    p=ranksum(g1,g2);   
    bar(i,median(g1),'facecolor',[1,1,1]*0.8);
    errorbar(i,median(g1),mad(g1));   
    text(i,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center')
    if p<0.01
        text(i,ymax*0.9,'*','HorizontalAlignment','center','color','r'); 
        text(i,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center','color','r')
    end    
    ylim([0,ymax]);
end

figure;hold on;
for i=1:length(uni_plate)
    idx=(strcmp(platename,uni_plate{i}));
    bar(i,median(nsegment(idx)));
end

%%
figure;hold on;
variable=df_fpeak_med_comp;
for i=1:length(uni_plate)
    idx=(strcmp(platename,uni_plate{i}));    
    g1=variable(idx,stim_idx);
    g2=variable(~idx,stim_idx);
    p=ranksum(g1,g2);   
    bar(i,median(g1),'facecolor',[1,1,1]*0.8);
    errorbar(i,median(g1),mad(g1));   
    text(i,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center')
    if p<0.01
        text(i,ymax*0.9,'*','HorizontalAlignment','center','color','r'); 
        text(i,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center','color','r')
    end    
    ylim([0,ymax]);
end

%%
cv_uncomp=std(df_fpeak_med)./mean(df_fpeak_med);
cv_comp=std(df_fpeak_med_comp)./mean(df_fpeak_med_comp);
% figure;plot(cv_uncomp,'.-');
% hold on;
% plot(cv_comp,'.-r');
figure;
bar([cv_uncomp([3,5,9])',cv_comp([3,5,9])']*100);