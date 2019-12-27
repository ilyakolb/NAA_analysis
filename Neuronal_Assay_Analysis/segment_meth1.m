function [ROI_list,ROImap]=segment_meth1(map)

%% high pass 
ss=size(map);
h = fspecial('gaussian', 50, 10);
smooth=imfilter(map,h,'symmetric');

result1=map-smooth;



%% threshold
m=mean(result1(:));
sd=std(result1(:));
bw=result1>(m+0.5*sd);
% figure;
% imagesc(bw);

%% distance transform
D = bwdist(~bw);
% figure;
% imagesc(D)
%% watershed 
D1 = -D;
D1(~bw) = -Inf;


L = watershed(D1);
ROI_list=[];
ROImap=zeros(ss(1:2));
for i=1:max(L(:))
    pixel_list=find(L==i);
    if (max(D(pixel_list))>4  && length(pixel_list)>10)
        ROI.pixel_list=pixel_list;
        ROI.npixel=length(pixel_list);
        ROI.mCherry=0;
        ROI_list=[ROI_list,ROI];
        ROImap(pixel_list)=i;
        
    end    
end

if ~isdeployed
    %% display
    % figure;imagesc(result1)

    MM=prctile(map(:),99);
    mm=prctile(map(:),1);

    RGB=zeros(ss(1),ss(2),3);
    RGB(:,:,1)=ROImap>0;
    RGB(:,:,2)=(map-mm)/(MM-mm);
    RGB(RGB>1)=1;RGB(RGB<0)=0;
    figure;image(RGB);axis image;
end
