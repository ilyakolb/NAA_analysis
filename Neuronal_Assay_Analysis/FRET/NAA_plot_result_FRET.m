%path='D:\data\Neuronal Culture\Neurons - Made 2010-05-03\Neurons - Made 2010-05-03 Image 2010-05-24\Image0524_Plate0503_01_a5\Exp1\';
%load([path,'para_array.mat']);
% load para_array.mat
% load para_array_cherry.mat
function NAA_plot_result_FRET(type)


[name,path]=uigetfile('*.mat');
load([path,name])

if ~exist(type)
    type='Ratio';
end

switch type
    case 'Ratio'
        soma=para_arrayRatio;
        summary=summaryRatio;
    case 'CFP'
        soma=para_arrayCFP;
        summary=summaryCFP;
    case 'YFP'
        soma=para_arrayYFP;
        summary=summaryYFP;
end

% figure;
% 
ss=size(mCherry);
overlay=zeros([ss,3]);
MM=myprctile(mCherry,99.9);
mm=myprctile(mCherry,10);
overlay(:,:,1)=(mCherry-mm)/(MM-mm);
MM=myprctile(CFP_base,99.2);
mm=myprctile(CFP_base,10);
overlay(:,:,2)=(CFP_base-mm)/(MM-mm);
overlay(overlay>1)=1;overlay(overlay<0)=0;
% 
% subplot(2,2,1)
% image(overlay);axis image;
% subplot(2,2,2);
% NAA_displayROI(cell_list,overlay)
% subplot(2,2,3);
% NAA_displayROI(cell_list,zeros(size(overlay)));
% subplot(2,2,4);
% NAA_displayROI(cell_list,dr_rmap(:,:,9));
figure;
subplot(2,2,1);
imagesc(dr_rmap(:,:,1));axis image;
subplot(2,2,2);
imagesc(dr_rmap(:,:,3));axis image;
subplot(2,2,3);
imagesc(dr_rmap(:,:,5));axis image;
subplot(2,2,4);
imagesc(dr_rmap(:,:,9));axis image;
% figure;
% NAA_displayROI(cell_list,dr_rmap(:,:,5));
figure;
NAA_displayROI(cell_list,dr_rmap(:,:,9));
figure;
NAA_displayROI(cell_list,overlay)
%% response vs. #AP
nAP=[1,2,3,5,10,20,40,80,160]';
nAP_Pts=length(nAP);
nTrial=size(para_arrayRatio,1)/nAP_Pts;
fs=35;   %Hz
nTime=length(para_arrayRatio(1).df_f);
nROI=size(para_arrayRatio,2);

%%

df_fpeak=reshape([soma.df_fpeak],[nAP_Pts,nTrial,nROI]);

df_fpeak_mean=mean(df_fpeak,3);
df_fpeak_med=median(df_fpeak,3);
df_fpeak_std=std(df_fpeak,0,3);

%%

% figure;
% for i=1:length(nAP)
% subplot(3,3,i)
% hist(squeeze(df_fpeak(i,:,:)),20);
% 
% title([num2str(nAP(i)),'FP']);
% xlabel('df/f')
% 
% end

% %%
% df_f=reshape([soma.df_f],[nTime,nAP_Pts,nTrial,nROI]);
% 
% figure;
% for i=1:6
%     subplot(2,3,i);
%     plot(squeeze(df_f(:,i,1,:)),'color',[1,1,1]*0.6);
%     hold on;plot(squeeze(mean(df_f(:,i,1,:),4)),'linewidth',3);
%     plot(squeeze(median(df_f(:,i,1,:),4)),'r','linewidth',3)
%     xlim([1,105]);%ylim([-0.5,5.5])
%     title([num2str(nAP(i)),'FP']);
% end

%%
df_f=reshape([soma.df_f],[nTime,nAP_Pts,nTrial,nROI]);
figure;
idx=[1,3,5,9];

for i=1:4
    subplot(1,4,i);
    plot((1:nTime)/fs,squeeze(df_f(:,idx(i),1,:)),'color',[1,1,1]*0.6);
    hold on;
    plot((1:nTime)/fs,squeeze(median(df_f(:,idx(i),1,:),4)),'r','linewidth',3)
    xlim([0,6]);
    title([num2str(nAP(idx(i))),'FP']);
end

%%
figure;
plot((1:nTime)/fs,squeeze(df_f(:,5,1,:)),'color',[1,1,1]*0.6);
hold on;
plot((1:nTime)/fs,squeeze(mean(df_f(:,5,1,:),4)),'linewidth',3);
plot((1:nTime)/fs,squeeze(median(df_f(:,5,1,:),4)),'r','linewidth',3);
title([num2str(nAP(5)),'FP']);

figure;subplot(1,2,2);plot(nAP,squeeze(df_fpeak(:,1,:)),'color',[1,1,1]*0.6);
hold on;
errorbar(nAP,df_fpeak_mean(:,1),df_fpeak_std(:,1)/sqrt(nROI),'-o','linewidth',3)
errorbar(nAP,df_fpeak_med(:,1),df_fpeak_std(:,1)/sqrt(nROI),'-or','linewidth',3)
ylim([0,7]);xlim([0,nAP(end)])

subplot(1,2,1)
% plot((1:nTime)/fs,squeeze(mean(df_f(:,:,1,:),4)))
hold on;
plot((1:nTime)/fs,squeeze(median(df_f(:,:,1,:),4)))
legend('1 FP','2 FP','3 FP','5 FP','10 FP','20 FP','40 FP','80 FP','160 FP');

%%
% df_fmed=squeeze(median(df_f(:,:,1,:),4));
% th=0.5;
% figure;hold on;
% tbase=(1:nTime)/fs;
% color={'b','g','r','c','r','m','k','b','g'};
% for i=1:size(df_fmed,2)
%     trace=df_fmed(:,i);
%     ind=max(find(trace>th));
%     if ~isempty(ind)
%         plot(tbase-ind/fs,trace,color{i});
%     end
% end

%% decay time

% figure;hold on;
% plot(nAP,summary.decay_half_med,'ko-');


%% f0
% f0=[soma.f0];
% f0=reshape(f0,size(soma));
% figure;plot(f0,'b')
% hold on;plot(mean(f0,2),'r','linewidth',2);
% ylim([0,max(f0(:))]);
% title('f0');


