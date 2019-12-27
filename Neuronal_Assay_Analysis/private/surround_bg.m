function [bg1,bg2]=surround_bg(mean_map,pixel_list)
%estimate background as the average intensity of surrounding pixel
    [I,J]=ind2sub(size(mean_map),pixel_list);
    Imin=min(I)-2;Jmin=min(J)-2;  
    Imax=max(I)+2;Jmax=max(J)+2;

    surround=zeros(size(mean_map));
    surround(Imin:Imax,Jmin:Jmax)=1;
    surround(pixel_list)=0;
    
    surr=mean_map(surround==1);
    surr=sort(surr);
    bg1=mean(surr);
    bg2=mean(surr(1:round(length(surr)/4)));
%     figure
%     imagesc(surround);