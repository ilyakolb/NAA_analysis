function [cell_list,dendrite_list]=NAA_segment_dye(filename)
tic
data=readTifStack(filename,1,69);
toc
data=data(:,:,2:end);
meanmap=mean(data,3);
ss=size(data);

%%  generate pixel masks based on response 
fmax=mean(data(:,:,61:68),3);
f0=mean(data(:,:,2:35),3)-100;
df=fmax-f0;



%%

[cell_list,ROImap]=segment_meth1(df);
save('Segmentation.mat','cell_list');


