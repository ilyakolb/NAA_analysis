
%%

coef=[];
nuc_ratio=[];

path='D:\Neuronal_culture\NAA_Database\';
% string={'20101213*_10dot1_','20101220*_10dot1_','20110613*_10dot1_'};
string={'_10dot29_'}

file=[];
for i=1:length(string)
    file=[file;dir([path,'*',string{i},'*'])];
end
% filename='P1-20101213_Well01-A1_10dot1_Summary.mat';
ncell=[];
for k=1:length(file)
%     load([path,filename]);
    load([path,file(k).name]);
    ss=size(GCaMPbase);
    ncell=[ncell,length(cell_list)];
    for i=1:length(cell_list)
        [II,JJ]=ind2sub(ss,cell_list(i).nuc_list);
        center=round([mean(II),mean(JJ)]);
        
        BW=zeros(512,512);
        BW(cell_list(i).nuc_list)=1;
        
        se = strel('disk',1);
        BW=imerode(BW,se);
        cell_list(i).nuc_list=find(BW);
        B_nuc=bwperim(BW,4);
        
        BW=zeros(512,512);
        BW(cell_list(i).pixel_list)=1;
        B_cell=bwperim(BW,4);
        Broi=B_nuc|B_cell;
        
        rgb=zeros(21,21,3);
        if center(1)>10 && center(1)<500 && center(2)>10 && center(2)<500
            Gnuc=mean(GCaMPbase(cell_list(i).nuc_list));
            cyto=setdiff(cell_list(i).pixel_list,cell_list(i).nuc_list);
            Gcyto=mean(GCaMPbase(cyto));
            nuc_ratio=[nuc_ratio,Gnuc/Gcyto];
            
            blockG=GCaMPbase(center(1)+(-10:10),center(2)+(-10:10));
            blockR=mCherry(center(1)+(-10:10),center(2)+(-10:10));
            Broi=Broi(center(1)+(-10:10),center(2)+(-10:10));
            
            corr1=corrcoef(blockG(:),blockR(:));
            coef=[coef,corr1(1,2)];
            
            if 0%nuc_ratio(end)>1.1
                
                
                
                figure;subplot(2,2,1);imagesc(blockG);hold on;plot(11,11,'x');axis image;
                subplot(2,2,2);imagesc(blockR);hold on;plot(11,11,'x');axis image;
                
                rgb(:,:,1)=normImage(blockR);
                rgb(:,:,2)=normImage(blockG);
                
                subplot(2,2,3);image(rgb);axis image;
                rgb=reshape(rgb,[],3);
                rgb(Broi,:)=1;
                rgb=reshape(rgb,[21,21,3]);
                subplot(2,2,4);image(rgb);axis image;
                
                title([num2str(coef(end)),' ',num2str(Gnuc/Gcyto)]);
            end
        end
    end

end
percent=sum(nuc_ratio>1.1)/length(nuc_ratio)
figure;hist(nuc_ratio,0.7:0.02:1.8);