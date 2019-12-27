
control=NAA_pile_mutants('_10dot1_');
%%
string='20110801';

[mutant_data]=NAA_pile_mutants(string);


%%
construct={mutant_data.construct};
% ctr_ind=strcmp(construct,'10dot1');
% control=mutant_data(ctr_ind);
% mutant=mutant_data(~ctr_ind);
% num=[];
mutant=mutant_data;
for i=1:length(mutant)
    temp=mutant(i).construct;
    num(i)=str2num(temp(6:end));
end
[n,ix]=sort(num);
mutant=mutant(ix);
%%
df_fpeak=[control.df_fpeak_med];
df_fpeak_comp=[control.df_fpeak_med_comp];
df_fpeak_nocomp=[control.df_fpeak_med];
decay_comp=[control.decay_half_med_comp];
figure;subplot(1,2,1);
plot(df_fpeak_comp(5,:),'.');
cv_comp=std(df_fpeak_comp(5,:))/mean(df_fpeak_comp(5,:));
title(['cv comp=',num2str(cv_comp)]);

subplot(1,2,2);
plot(df_fpeak_nocomp(5,:),'.');
cv_nocomp=std(df_fpeak_nocomp(5,:))/mean(df_fpeak_nocomp(5,:));
title(['cv nocomp=',num2str(cv_nocomp)]);
comp=df_fpeak_comp(5,:);

nwell=size(df_fpeak_comp,2);
%%
p_array=zeros(length(mutant),9);
amp_array=zeros(length(mutant),9);
for stim_ind=1:9
    g1=df_fpeak_comp(stim_ind,:);
%     g1=df_fpeak(stim_ind,:);
    for i=1:length(mutant)        
        g2=mutant(i).df_fpeak_med_comp(stim_ind,:);
%         g2=mutant(i).df_fpeak_med(stim_ind,:);
        [p,h] = ranksum(g1,g2);
        p=p;
        if median(g2)>median(g1)
            p_array(i,stim_ind)=log10(p)*-1;  %mutant larger
            if p<0.01
                amp_array(i,stim_ind)=median(g2)/median(g1);
            end
        else
            p_array(i,stim_ind)=log10(p);  %mutant smaller
        end
    end
end
   
test_array=zeros(size(p_array));
test_array(p_array(:)>2)=1;
test_array(p_array(:)>3)=2;
test_array(p_array(:)<-2)=-1;
test_array(p_array(:)<-3)=-2;

significant=sum(test_array>0,2);
sig_array=test_array(significant>2,:);
sig_amp_array=amp_array(significant>2,:);
%%
figure;imagesc(test_array');
set(gca,'YTickLabel',{'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'});
set(gca,'XTick',[]);

for i=1:length(mutant)
    text(i,10.2,mutant(i).construct,'Rotation',90,'HorizontalAlignment','center')
end
% xlswrite('test.xls',sign(p_array).*10.^(-1*abs(p_array)));
% set(gca,'XTickLabel',{mutant.construct});

%%
figure;imagesc(sig_array');
set(gca,'clim',[-2,2]);
set(gca,'YTickLabel',{'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'});
set(gca,'XTick',[]);
sig_mutant=mutant(significant>2);
for i=1:length(sig_mutant)
    text(i,10,sig_mutant(i).construct,'HorizontalAlignment','center')
    text(i,10.5,['(n=',num2str(sig_mutant(i).nreplicate),')'],'HorizontalAlignment','center')
end

%%
figure;imagesc(sig_amp_array');
set(gca,'clim',[0,3]);
set(gca,'YTickLabel',{'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'});
set(gca,'XTick',[]);
sig_mutant=mutant(significant>2);
for i=1:length(sig_mutant)
    text(i,10,sig_mutant(i).construct,'HorizontalAlignment','center')
    text(i,10.5,['(n=',num2str(sig_mutant(i).nreplicate),')'],'HorizontalAlignment','center')
end

%%
figure;hold on;
for i=1:length(sig_mutant)
    df_f=median(sig_mutant(i).df_fpeak_med_comp,2);
    plot([1,2,3,5,10,20,40,80,160],df_f);
end

%%
stim_ind=5;
ymax=2;
figure;hold on;
g1=df_fpeak_comp(stim_ind,:);
X=g1;
text(1,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center')
group=zeros(size(g1));
hitname={'GCaMP3'};
pval=[];
for i=1:length(sig_mutant)
    g2=sig_mutant(i).df_fpeak_med_comp(stim_ind,:)
    [p,h] = ranksum(g1,g2);
    pval(i)=p;
    X=[X,g2];
    group=[group,ones(size(g2))*i];
    hitname{end+1}=sig_mutant(i).construct;
end
boxplot(X,group,'symbol','','labels',hitname);
ylim([0,ymax]);

for i=1:length(sig_mutant)
    text(i+1,ymax*0.95,['(n=',num2str(sig_mutant(i).nreplicate),')'],'HorizontalAlignment','center')
    
    if pval(i)<0.01
        text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.4f'),')'],'HorizontalAlignment','center','color','r')
    else
        text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.4f'),')'],'HorizontalAlignment','center');
    end
end


%%
stim_ind=5;
ymax=2;
figure;hold on;
g1=df_fpeak_comp(stim_ind,:);
bar(0,median(g1),'facecolor',[1,1,1]*0.8);
errorbar(0,median(g1),std(g1)/length(g1));
text(0,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center')
hitcount=0;
hitname={'GCaMP3'};
for i=1:length(mutant)
    g2=mutant(i).df_fpeak_med_comp(stim_ind,:);
    [p,h] = ranksum(g1,g2);
    if p<0.02 
        if median(g2)>median(g1)
            hitcount=hitcount+1;
            bar(hitcount,median(g2),'facecolor',[1,1,1]*0.8);
            errorbar(hitcount,median(g2),std(g2)/length(g2));
            text(hitcount,ymax*0.95,['(',num2str(length(g2)),')'],'HorizontalAlignment','center');
            text(hitcount,ymax*0.9,['(p=',num2str(p,'%0.3f'),')'],'HorizontalAlignment','center')
            hitname{end+1}=mutant(i).construct;
        end
    end
end
ylim([0,ymax]);
set(gca,'XTick',0:hitcount)
set(gca,'XTickLabel',hitname);

%% decay

fast_ind=[];

for i=1:length(mutant)
    [p,h] = ranksum(decay_comp,mutant(i).decay_half_med_comp);
    if p<0.01 
        if median(mutant(i).decay_half_med_comp)<median(decay_comp)
            fast_ind=[fast_ind,i];
            disp([mutant(i).construct,mutant(i).plate,'_',num2str(i),'_',num2str(median(mutant(i).decay_half_med_comp))])
        end
    end
end

%%
ind=[22,49,51,54];

figure;plot(df_fpeak_med(5,:),decay_comp,'.');hold on;
color=['r','g','k','m','c'];
str={'10dot1'};
for k=1:length(ind)
   plot(mutant(ind(k)).df_fpeak_med(5,:),mutant(ind(k)).decay_half_med_comp,'.','color',color(k));
   str{k+1}=mutant(ind(k)).construct;
end
legend(str)