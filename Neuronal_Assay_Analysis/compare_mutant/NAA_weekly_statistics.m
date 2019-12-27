string='20110829';
% file_str='';
file_str=string;


saveflag=1;
% string={'_10dot30_'};
% string={'20110627*_10dot1_','_10dot352_','_10dot354_','_10dot357_','_10dot359_','_10dot361_','_10dot362_'};
% string={'_10dot29_','_10dot212_','_10dot278_','_10dot264_','_10dot261_','_10dot276_','10dot347_','_10dot321_','_10dot326_','_10dot335_','_10dot403_'};
% string={'*'};
mutant=NAA_pile_mutants(string);

control=NAA_pile_mutants('_10dot1_');
%% sort mutant according to GECI numbering
construct_num=zeros(length(mutant),1);
for i=1:length(mutant)
    temp=mutant(i).construct;
    construct_num(i)=str2num(temp(6:end));
end
[n,ix]=sort(construct_num);
mutant=mutant(ix);
construct={mutant.construct};
%% p_values 
p_array=zeros(length(mutant),9);
amp_array=zeros(length(mutant),9);
entry_p=cell(length(mutant),14);
entry_amp=cell(length(mutant),14);    
title_text={'','1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP','','decay_10FP','','nrep'};

for i=1:length(mutant)
    entry_p{i,1}=mutant(i).construct;
    entry_amp{i,1}=mutant(i).construct;
    for stim_ind=1:9
        g1=control.df_fpeak_med_comp(stim_ind,:);
        g2=mutant(i).df_fpeak_med_comp(stim_ind,:);
        [p,h] = ranksum(g1,g2);
        if median(g2)>median(g1)
            p_array(i,stim_ind)=log10(p)*-1;  %mutant larger
        else
            p_array(i,stim_ind)=log10(p);  %mutant smaller
        end
        
        if median(g2)>median(g1)
            entry_p{i,stim_ind+1}=p;
        else
            entry_p{i,stim_ind+1}=p*-1;
        end
        entry_amp{i,stim_ind+1}=median(g2)/median(g1);
    end

    %% decay 
    g1=[control.decay_half_med_comp];
    g2=[mutant(i).decay_half_med_comp];
    [p,h]=ranksum(g1,g2);
    entry_p{i,12}=p;
    entry_amp{i,12}=median(g2)/median(g1);
    entry_amp{i,14}=length(g2);
    
end
%%
if saveflag
    xlswrite(['report_',file_str,'.xls'],[title_text;entry_p],'p_value');
    xlswrite(['report_',file_str,'.xls'],[title_text;entry_amp],'amplitude');
end
%% amplitude color coded
amp_ratio=cell2mat(entry_amp(:,2:10))';
decay_ratio=cell2mat(entry_amp(:,12))';

handle=figure('position',[100,100,1200,800]);
ax1=axes('position',[0.1,0.15,0.8,0.5]);
amp_ratio(amp_ratio<=0)=0.001;
    
imagesc(log2(amp_ratio));
set(gca,'clim',[-2,2]);
set(gca,'YTickLabel',{'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'});
set(gca,'XTick',[]);
title('dF/F (relative to GCaMP3)');
for i=1:length(mutant)
    text(i,10.5,mutant(i).construct,'Rotation',90,'HorizontalAlignment','center')
end
colorbar;


ax2=axes('position',[0.1,0.74,0.8,0.06]);
imagesc(log2(decay_ratio));
set(gca,'clim',[-2,2]);
set(gca,'XTick',[]);
set(gca,'YTick',1);
set(gca,'YTickLabel','10FP');
title('Half Decay Time at 10FP (normalized to GCaMP3)');
colorbar;

%% normalized f0
norm_f0=zeros(size(mutant),1);
for i=1:length(mutant)
    mCherry=mutant(i).mCherry;
    f0=mutant(i).f0;
    norm_f0(i)=median(f0./mCherry);
end
norm_f0=norm_f0/norm_f0(1);

%handle=figure('position',[100,100,1200,800]);
ax3=axes('position',[0.1,0.88,0.8,0.06]);

imagesc(log2(norm_f0));
set(gca,'clim',[-2,2]);
set(gca,'YTick',1);
title('Baseline Brightness (normalized by mCherry expression, relative to GCaMP3)');
set(gca,'YTickLabel',{'norm_f0'});
set(gca,'XTick',[]);
colorbar;
if saveflag
    saveppt(['report_',file_str,'.ppt'])
    close(handle)
end

%% bar plot amplitudes response
stim_identity={'1AP','2AP','3AP','5AP','10AP','20AP','40AP','80AP','160AP'};

for stim_ind=1:9%[3,5,9]
    handle=figure('position',[100,100,1200,800]);
    hold on;
    g1=[control.df_fpeak_med_comp(stim_ind,:)];
    ymax=median(g1)*7;
    X=g1;
    text(1,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center')
    group=zeros(size(g1));
    hitname={'GCaMP3'};
    pval=[];
    amp=[];
    for i=1:length(mutant)
        g2=mutant(i).df_fpeak_med_comp(stim_ind,:);
        [p,h] = ranksum(g1,g2);
        pval(i)=p;
        amp(i)=median(g2)/median(g1);
        X=[X,g2];
        group=[group,ones(size(g2))*i];
        hitname{end+1}=mutant(i).construct;
    end
    
    boxplot(X,group,'symbol','','labels',hitname,'plotstyle','compact');
    hold on;plot([1,length(mutant)+1],median(g1)*[1,1],':k');hold on;
    title(stim_identity{stim_ind});
    ylim([0,ymax]);
    ylabel('dF/F')
    
    for i=1:length(mutant)
        text(i+1,ymax*0.95,['(n=',num2str(mutant(i).nreplicate),')'],'HorizontalAlignment','center')
        if amp(i)>1
            if pval(i)<0.001
                text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color','r');
            elseif pval(i)<0.01
                text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color',[1,0.5,0]);
            elseif pval(i)<0.05
                text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color',[1,0.75,0]);
            end
        else
            if pval(i)<0.001
                text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color','b');
            elseif pval(i)<0.01
                text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color',[0,0.5,1]);
            elseif pval(i)<0.05
                text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color',[0,1,1]);
            end
        end
        if pval(i)>=0.05
            text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center');
        end
    end
    if saveflag
    saveppt(['report_',file_str,'.ppt'])
    close(handle)
    end
end



%% decay

fast_ind=[];
p_array_decay=zeros(length(mutant),1);
amp_array_decay=zeros(length(mutant),1);
g1=[control.decay_half_med_comp];

for i=1:length(mutant)
    g2=mutant(i).decay_half_med_comp;
    [p,h] = ranksum(g1,g2);
    if median(g2)<median(g1)
        p_array_decay(i)=log10(p)*-1;  %mutant faster
        if p<0.01
            amp_array(i)=median(g1)/median(g2);
        end
    else
        p_array_decay(i)=log10(p);  %mutant slower
        if p<0.01
            amp_array(i)=median(g2)/median(g1);
        end
    end
end
%%

handle=figure('position',[100,100,1200,800]);
ax1=axes('position',[0.1,0.2,0.8,0.5]);
imagesc(p_array');
set(gca,'clim',[-3,3]);
set(gca,'YTickLabel',{'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'});
set(gca,'XTick',[]);
title('response dF/F, p values');
for i=1:length(mutant)
    text(i,10.5,mutant(i).construct,'Rotation',90,'HorizontalAlignment','center')
end
colorbar;
ax2=axes('position',[0.1,0.75,0.8,0.06]);
imagesc(p_array_decay');
title('decay time (10FP), p values');
set(gca,'clim',[-3,3]);
set(gca,'XTick',[]);
colorbar;

if saveflag
saveppt(['report_',file_str,'.ppt']);
close(handle);
end
%%  box plot for decay amplitude
decay_array=zeros(length(mutant),1);
for i=1:length(mutant)
    decay_array(i)=median(mutant(i).decay_half_med_comp);
end

ymax=2;
handle=figure('position',[100,100,1200,800]);hold on;
g1=[control.decay_half_med_comp];
text(1,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center')
ylabel('decay time (s)');
group=zeros(size(g1));
hitname={'GCaMP3'};
pval=[];
amp=[];
X=g1;
group=zeros(size(g1));
for i=1:length(mutant)
    g2=mutant(i).decay_half_med_comp;
    [p,h] = ranksum(g1,g2);
    pval(i)=p;
    amp(i)=median(g1)/median(g2);
    X=[X,g2];
    group=[group,ones(size(g2))*i];
    hitname{end+1}=mutant(i).construct;
end
boxplot(X,group,'symbol','','labels',hitname,'plotstyle','compact');
ylim([0,ymax]);
plot([1,length(mutant)+1],median(g1)*[1,1],':k');hold on;

for i=1:length(mutant)
    text(i+1,ymax*0.95,['(',num2str(mutant(i).nreplicate),')'],'HorizontalAlignment','center')
    if amp(i)>1
        if pval(i)<0.001
            text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color','r');
        elseif pval(i)<0.01
            text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color',[1,0.5,0]);
        elseif pval(i)<0.05
            text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color',[1,0.75,0]);
        end
    else
        if pval(i)<0.001
            text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color','b');
        elseif pval(i)<0.01
            text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color',[0,0.5,1]);
        elseif pval(i)<0.05
            text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center','color',[0,1,1]);
        end
    end
    if pval(i)>=0.05
        text(i+1,ymax*0.9,['(p=',num2str(pval(i),'%0.3f'),')'],'HorizontalAlignment','center');
    end
end
if saveflag
saveppt(['report_',file_str,'.ppt'])
end