load Segmentation.mat;
map=zeros(512,512);
boundary_ind=[];
for i=1:length(cell_list)
    pixel_list=cell_list(i).pixel_list;
    
    [I,J] = ind2sub([512,512],pixel_list);
    x=mean(I);
    y=mean(J);
    
    if (x>500)||(x<12)||(y>500)||(y<12)
        map(pixel_list)=2;
        boundary_ind=[boundary_ind,i];
    else
        map(pixel_list)=1;
    end
end

save('boundary_ind.mat','boundary_ind');