function ROI_list = dF_based_segmentation(GCaMPbase, mCherry, dF, type, segmentation_threshold,threshold2)

global DEBUG; DEBUG=1;
%% active pixel based segmentation
ss=size(GCaMPbase);
reg=11;
cen=(reg+1)/2;
h2=zeros(reg,reg);
for i=1:reg
    for j=1:reg
        r=sqrt((i-cen)^2+(j-cen)^2);
        if r<=4
            h2(i,j)=1;
        end
    end
end
n1=sum(h2(:));
n2=sum(ones(size(h2(:))))-n1;
h2(h2==0)=-1*n1/n2;
%%

filt_map=imfilter(dF,h2,'symmetric');
maximal=local_maximal(filt_map).*filt_map;
peakvalue=maximal(maximal>0);

th = kmean1D_threshold(peakvalue, 0.25);

val=maximal(maximal>th);
[~,ind]=sort(val,'descend');
[row,col]=find(maximal>th);
row=row(ind);
col=col(ind);

if length(ind)>6000
    ROI_list=[];
    if ~isdeployed && ~isempty(DEBUG)
        if strcmpi(type, 'RCaMP96')
            overlay = NAA_create_overlay(mCherry, GCaMPbase);
        else
            overlay = NAA_create_overlay(GCaMPbase, mCherry);
        end
        figure;image(overlay);
    end
    return;
end

radius_neu=6;

radius_cell=7.5;

territory=zeros(ss(1:2));
territory_neu=zeros(ss(1:2));
territory_cell=zeros(ss(1:2));
for i=1:ss(1)
    for j=1:ss(2)
        dist=(col-j).^2+(row-i).^2;
        [mm,ind]=min(dist);
        territory(i,j)=ind;
        if sqrt(mm)<=radius_neu
            territory_neu(i,j)=ind;
        end
        if sqrt(mm)<=radius_cell
            territory_cell(i,j)=ind;
        end
    end
end
%%
%boundary_cell=false(size(territory_neu));
ss=size(GCaMPbase);
%% changed by Hod 05Feb2103
% se = strel('square',4);
se=strel('square',4);
ROI_list=[];
ROI=[];
area=zeros(1,length(col));
round_ind=zeros(size(area));

for i=1:length(col)
    
    BW=false(ss);
    ind=find(territory_neu==i);
    val=mCherry(ind);
    th=(max(val)-min(val))*0.25+min(val);
    BW(ind(val>th))=1;
    BW2=imclose(BW,se);
    BW2=imfill(BW2,'holes');
    %th=kmean1D_threshold(mCherry(ind),0.5);
    %nuc_list=ind(mCherry(ind)>th);
    nuc_list=find(BW2);
    nuc_border=find(bwperim(BW2,4));
    
    BW=false(ss);
    BW(ind(mCherry(ind)>th))=1;
    ind=find(territory_cell==i);
    val=GCaMPbase(ind);
    th=(max(val)-min(val))*0.25+min(val);
    BW(ind(val>th))=1;
    BW2=imclose(BW,se);
    BW2=imfill(BW2,'holes');
    %boundary=bwperim(BW2,4);
    %boundary_cell(boundary)=1;
 %% run shape-based segmentation
%  h=figure;
round_th=0.85;
[round_ area_]=cell_shaped_segmentation(BW2);
round_ind(i)=round_;
area(i)=area_;

pixel_list=find(BW2);
values=dF(pixel_list);
dF_values=sort(reshape(dF,[],1));
max_th=dF_values(round(0.97*length(dF_values)));


if (area(i)<25&&max(values)<max_th)
    continue
elseif (area(i)>70&&round_ind(i)<0.8)
    continue
elseif (max(values)>max_th&&round_ind(i)<0.8)
    continue
elseif round_ind(i)<round_th  
     continue
end
    
     cell_val=dF(ind(val>th));
     
    
    
    if length(pixel_list)>length(nuc_list)
        [row,col]=ind2sub(ss,pixel_list);
        ROI.nuc_list=nuc_list;
        ROI.pixel_list=pixel_list;
        ROI.center=[mean(row);mean(col)];
        ROI.npixel=length(pixel_list);
        
        ROI.GCaMP_total=mean(GCaMPbase(ROI.pixel_list));
        ROI.mCherry=mean(mCherry(ROI.nuc_list));
        
        %fcyto=GCaMPbase(setdiff(ROI.pixel_list,ROI.nuc_list));
        %th=myprctile(fcyto,60);
        
        ROI.GCaMP_nuc=mean(GCaMPbase(setdiff(ROI.nuc_list,nuc_border)));
        ROI.GCaMP_nucborder=mean(GCaMPbase(nuc_border));
        ROI.dF=mean(dF(ROI.pixel_list));
        ROI_list=[ROI_list,ROI]; %#ok<AGROW>
    end
end

%% remove ROI touching boundary
remove_ind=false(size(ROI_list));
for i=1:length(ROI_list)
    pixel_list=ROI_list(i).pixel_list;
    [row,col]=ind2sub(ss,pixel_list);
    if (min(row)==1) || (max(row)==ss(1)) ||(min(col)==1)|| (max(col)==ss(1))
        remove_ind(i)=1;
    end
end
ROI_list=ROI_list(~remove_ind);

%%  remove really dark cells likely from over segmentation

if ~isempty(segmentation_threshold)
    th = segmentation_threshold;
elseif strcmp(type, 'FRET') || strcmp(type, 'GCaMP96')
    th = 100;
elseif strcmpi(type, 'RCaMP96')
    th = 120;
else
    th = 60;
end

v1 = [ROI_list.dF];
v2=[ROI_list.mCherry];
disc1 = th;
disc2=str2double(threshold2);
remove_ind = (v1<disc1|v2<disc2);
dark_list = ROI_list(remove_ind);
ROI_list = ROI_list(~remove_ind);

figure
subplot(1,2,1)
overlay = NAA_create_overlay(GCaMPbase, mCherry);
NAA_displayROI(ROI_list, overlay);
title('Green and Red Channels Overlay')
subplot(1,2,2)
NAA_displayROI(ROI_list, dF);
title('dF Image')

% circ=zeros(21,21);
% for i=1:size(circ,1)
%     for j=1:size(circ,2)
%         if (((i-ceil(size(circ,1)/2))^2+(j-ceil(size(circ,2)/2))^2)<6^2)
%             circ(i,j)
% 

end