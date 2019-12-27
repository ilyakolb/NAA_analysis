function [cell_list,dendrite_list,bg_meanlowest5]=NAA_segment(filename)
tic
data=readTifStack(filename,1,51);
toc
data=data(:,:,2:end);
meanmap=mean(data,3);
ss=size(data);

%%  generate pixel masks based on response 
f0=mean(data(:,:,1:34),3);
f1=mean(data(:,:,40:50),3);

df_fmap=(f1-f0)./f0;
th=prctile(df_fmap(:),85);
mask_resp=df_fmap>th;

th1=prctile(f0(:),5);
bg_meanlowest5=mean(f0(f0(:)<th1));


%%
MM=prctile(f0(:),99);
mm=prctile(f0(:),1);
RGB=zeros(ss(1),ss(2),3);
RGB(:,:,1)=df_fmap;
RGB(:,:,2)=(f0-mm)/(MM-mm);
RGB(RGB>1)=1;RGB(RGB<0)=0;
% figure;image(RGB);axis image;

%%
[cell_list,ROImap]=segment_meth1(meanmap);

disp=zeros(ss(1:2));
disp(mask_resp(:))=1;
disp(ROImap>1)=2;

mask_dendrite=mask_resp&(ROImap==0);
dendrite_list.pixel_list=find(mask_dendrite);
dendrite_list.npixel=length(dendrite_list.pixel_list);
% figure;
% imagesc(mask_dendrite)


