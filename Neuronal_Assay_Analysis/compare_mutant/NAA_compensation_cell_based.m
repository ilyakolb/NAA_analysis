% path='D:\Neuronal_culture\NAA_Database\';
path='D:\Neuronal_culture\NAA_compare_CNQXCPP\10dot1_doubleCNQXCPP\';
list=dir([path,'*.mat']);


para_pile=[];
cell_pile=[];
n_nearby_pile=[];
fmax_pile=[];
file_pile=[];
count=1;
for i=1:length(list)
    fields=textscan(list(i).name,'%s','delimiter','_');
    if strcmp(fields{1}{3},'10dot1')
        load([path,list(i).name],'para_array','cell_list','summary','df_fmap','GCaMPbase','mCherry','fmax');   
                        
                
        center=[cell_list.center];
        distmat=squareform(pdist(center'));
        n_nearby=sum(distmat<50)-1;
        
        n_nearby_pile=[n_nearby_pile,n_nearby];        
        para_pile=[para_pile,para_array];
        cell_pile=[cell_pile,cell_list];  
        fmax_pile=[fmax_pile,fmax];
        count=count+1;        
        
        file_pile=[file_pile;ones(length(para_array),1)*i];
     end
end
file_pile=file_pile';
n_nearby_pile_org=n_nearby_pile;
%%
stim_ind=5;
f0=[para_pile(1,:).f0];
mCherry=[cell_pile.mCherry];
df_fpeak=[para_pile(stim_ind,:).df_fpeak];
decay_half=[para_pile(stim_ind,:).decay_half];
npixel=[cell_pile.npixel];

%%
window_low=150;
window_high=200;
f0_file=[];
df_fpeak_file=[];
for i=1:length(list)
    ind1=find((file_pile==i)&(f0<window_high)&(f0>window_low));
    ind2=find((file_pile==i));
    f0_win(i)=mean(f0(ind1));
    f0_all(i)=mean(f0(ind2));
    df_fpeak_win(i)=mean(df_fpeak(ind1));    
    df_fpeak_all(i)=mean(df_fpeak(ind2));
end

figure;
plot(f0_win,df_fpeak_win,'.');
hold on;
plot(f0_all,df_fpeak_all,'.r');

figure;
plot([df_fpeak_all;df_fpeak_win])

%%
n_unique=unique(n_nearby_pile);
f0_bin_low=[0,100,200,300,400];
f0_bin_high=[100,200,300,400,500];
color=['r','g','b','k','c'];
figure;
for j=1:length(f0_bin_low)

    for i=1:length(n_unique)
        ind=find((n_nearby_pile==n_unique(i))&(f0<f0_bin_high(j)) & (f0>f0_bin_low(j)));
        mean(n_nearby_pile(ind))
        
        nbin(i)=length(ind);
        
        r_avg(i)=mean(df_fpeak(ind));
        r_sd(i)=std(df_fpeak(ind));
        r_sem(i)=r_sd(i)/sqrt(length(ind));
        
        mc_avg(i)=mean(mCherry(ind));
        mc_sd(i)=std(mCherry(ind));
        mc_sem(i)=mc_sd(i)/sqrt(length(ind));
        
        
        f0_avg(i)=mean(f0(ind));
        f0_sd(i)=std(f0(ind));
        f0_sem(i)=f0_sd(i)/sqrt(length(ind));        
    end
    subplot(1,2,1);
    errorbar(n_unique,r_avg,r_sem,'color',color(j)); hold on;xlim([0,10]);
    subplot(1,2,2);
    errorbar(n_unique,f0_avg,f0_sem); xlim([0,25]);ylim([0,max(f0_avg)]);hold on;    
end

%%

n_unique=unique(n_nearby_pile);
f0_bin_low=[0,100,200,300,400,500];
f0_bin_high=[100,200,300,400,500,3000];
color=['r','g','b','k','c','m'];
figure;
df_f=[para_pile(5,:).df_f];
for j=1:length(f0_bin_low)
    ind=find((f0<f0_bin_high(j)) & (f0>f0_bin_low(j)));
    length(ind)
    df_f_bin=median(df_f(:,ind),2);
    subplot(1,2,1);plot(df_f_bin,'color',color(j));hold on;
    subplot(1,2,2);plot(df_f_bin/max(df_f_bin),'color',color(j));hold on;
end





%%
n_unique=unique(n_nearby_pile);

for i=1:length(n_unique)
    ind=find(n_nearby_pile==n_unique(i));
    mean(n_nearby_pile(ind))
    
    nbin(i)=length(ind);
    
    r_avg(i)=mean(df_fpeak(ind));
    r_sd(i)=std(df_fpeak(ind));
    r_sem(i)=r_sd(i)/sqrt(length(ind));
    
    mc_avg(i)=mean(mCherry(ind));
    mc_sd(i)=std(mCherry(ind));
    mc_sem(i)=mc_sd(i)/sqrt(length(ind));
    
    
    f0_avg(i)=mean(f0(ind));
    f0_sd(i)=std(f0(ind));
    f0_sem(i)=f0_sd(i)/sqrt(length(ind));
    
end
figure;
subplot(1,4,1);errorbar(n_unique,r_avg,r_sem);  xlim([0,25]);ylim([0,max(r_avg)]);
subplot(1,4,2);errorbar(n_unique,mc_avg,mc_sem); xlim([0,25]);ylim([0,max(mc_avg)]);
subplot(1,4,3);errorbar(n_unique,f0_avg,f0_sem); xlim([0,25]);ylim([0,max(f0_avg)]);
subplot(1,4,4);plot(n_unique,nbin);


%%
f0_bw=100;
f0_bin_low=(0:4)*f0_bw;
f0_bin_high=(1:5)*f0_bw;
r_avg=[];
r_sd=[];
r_sem=[];
n_avg=[];
n_sd=[];
n_sem=[];
mc_avg=[];mc_sd=[];mc_sem=[];
f0_avg=[];
for i=1:length(f0_bin_low)
    ind=find((f0<f0_bin_high(i)) & (f0>f0_bin_low(i)));
    mean(n_nearby_pile(ind))
    
    r_avg(i)=mean(df_fpeak(ind));
    r_sd(i)=std(df_fpeak(ind));
    r_sem(i)=r_sd(i)/sqrt(length(ind));
    
    
    n_avg(i)=mean(n_nearby_pile(ind));
    n_sd(i)=std(n_nearby_pile(ind));
    n_sem(i)=n_sd(i)/sqrt(length(ind));
    
    mc_avg(i)=mean(mCherry(ind));
    mc_sd(i)=std(mCherry(ind));
    mc_sem(i)=mc_sd(i)/sqrt(length(ind));
    
    
    f0_avg(i)=mean(f0(ind));    
end
figure;hist(f0,100);
figure;
subplot(1,3,1);errorbar(f0_avg,r_avg,r_sem); ylim([0,max(r_avg)]);
subplot(1,3,2);errorbar(f0_avg,n_avg,n_sem); ylim([0,max(n_avg)]);
subplot(1,3,3);errorbar(f0_avg,mc_avg,mc_sem);ylim([0,max(mc_avg)]);


%%
npixel_bin_low=[80,100,120,140,160];
npixel_bin_high=[100,120,140,160,180];
r_avg=[];
r_sd=[];
r_sem=[];


for i=1:length(npixel_bin_low)
    ind=find((npixel<npixel_bin_high(i)) & (npixel>npixel_bin_low(i)));    
    
    r_avg(i)=median(df_fpeak(ind));
    r_sd(i)=std(df_fpeak(ind));
    r_sem(i)=r_sd(i)/sqrt(length(ind));
    
    n_avg(i)=mean(n_nearby_pile(ind));
    n_sd(i)=std(n_nearby_pile(ind));
    n_sem(i)=n_sd(i)/sqrt(length(ind));
    
    npixel_avg(i)=mean(npixel(ind));    
end
% figure;hist(f0,100);
figure;
subplot(1,3,1);
errorbar(npixel_avg,r_avg,r_sem); ylim([0,max(r_avg)]);
subplot(1,3,2);errorbar(npixel_avg,n_avg,n_sem); ylim([0,max(n_avg)]);