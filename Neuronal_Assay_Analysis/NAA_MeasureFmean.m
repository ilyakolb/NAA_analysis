function [fmean,df_fmap,bg]=NAA_MeasureFmean(filenames,ROI_list,method,mCherry)

if ~exist('method')
    method='Local';  %default use local method
end
nFiles=length(filenames);
nROI=length(ROI_list);
info = imfinfo(filenames{1},'tif');
nTime=length(info)-1;

fmean=zeros(nTime,nFiles,nROI);
% bg_situ=[];
df_fmap=[];
bg=zeros(length(filenames),1);
for i=1:length(filenames)
    if strcmp(method,'Local')
        %fprintf('NAA_MeasureFmean: Using the Local code \n');        
        data=readTifStack(filenames{i});    
    elseif strcmp(method,'Network');
        %fprintf('NAA_MeasureFmean: Using the Network code \n');
        tmpFile = fullfile(pwd, 'tempMeasureFmean.tif');
        copyfile(filenames{i}, tmpFile);
        data=readTifStack(tmpFile);
        delete(tmpFile);
    end
    data=data(:,:,2:end);
    
     
    
%     GCaMPbase=mean(data(:,:,2:25),3);
%     ss=size(mCherry);
%     overlay=zeros([ss,3]);
%     MM=myprctile(mCherry,99.9);
%     mm=myprctile(mCherry,10);
%     overlay(:,:,1)=(mCherry-mm)/(MM-mm);
%     MM=myprctile(GCaMPbase,99.2);
%     mm=myprctile(GCaMPbase,10);
%     overlay(:,:,2)=(GCaMPbase-mm)/(MM-mm);
%     overlay(overlay>1)=1;overlay(overlay<0)=0;
    
    ss=size(data);
    data=reshape(data,[],ss(3)); 
%     temp=reshape(data,ss);
    for j=1:length(ROI_list)   
        
        if isfield(ROI_list,'dF_coordinates')
            fmean(:,i,j)=mean(data(ROI_list(j).dF_coordinates,:))';
        else
            fmean(:,i,j)=mean(data(ROI_list(j).pixel_list,:))';
        end
%         if i>6
%             BW=zeros(ss(1:2));
%             BW(ROI_list(j).pixel_list)=1;
%             STATS = regionprops(BW, 'boundingBox');
%             bbox=STATS.BoundingBox;
%             bgmap=zeros(ss(1:2));fmeanmap=zeros(ss(1:2));umap=zeros(ss(1:2));
%             
%             
%             f=data(ROI_list(j).pixel_list,:);
%             bg_detail=bg_est(double(f),1);
%             bg_situ=[bg_situ,bg_detail];
%             
%             fm=mean(f(:,1:25),2);
%             bgmap(ROI_list(j).pixel_list)=bg_detail.bgmap;
%             fmeanmap(ROI_list(j).pixel_list)=fm;
%             umap(ROI_list(j).pixel_list)=bg_detail.u;
%             
%             block=temp(floor(bbox(2)):(floor(bbox(2))+bbox(4)),floor(bbox(1)):(floor(bbox(1))+bbox(3)),:);
%             figure;
%             subplot(2,3,1);
%             imagesc(overlay);axis equal;axis([bbox(1),bbox(1)+bbox(3),bbox(2),bbox(2)+bbox(4)]);
%             subplot(2,3,2);
%             imagesc(bgmap);axis equal;axis([bbox(1),bbox(1)+bbox(3),bbox(2),bbox(2)+bbox(4)]);set(gca,'clim',[min(fm),max(fm)]);title('bgmap')%set(gca,'clim',[min(bg_detail.bgmap),max(bg_detail.bgmap)]);
%             subplot(2,3,3);
%             imagesc(fmeanmap);axis equal;axis([bbox(1),bbox(1)+bbox(3),bbox(2),bbox(2)+bbox(4)]);set(gca,'clim',[min(fm),max(fm)]);title('fmeanmap')
%             subplot(2,3,4);
%             imagesc(umap);axis equal;axis([bbox(1),bbox(1)+bbox(3),bbox(2),bbox(2)+bbox(4)]);set(gca,'clim',[min(bg_detail.u),max(bg_detail.u)]);title('umap')
%             subplot(2,3,5);
%             f1=mean(f)-100;f10=mean(f1(1:25));
%             f2=mean(f)-mean(bg_detail.bgmap);f20=mean(f2(1:25));
%             plot((f1-f10)/f10,'b');
%             hold on;
%             plot((f2-f20)/f20,'r');                    
    end            
    data=reshape(data,ss);
    if isfield(ROI_list,'dF_coordinates')
        base=mean(data(:,:,1:135),3); % OLD
        % IK MODIFIED 12/2/19: this should eliminate negative f0 values
        % problem was that when bleaching is really high, background looks
        % to be really high too
        % base=mean(data(:,:,350:390 ),3); % right before first stim
    else
        base=mean(data(:,:,1:25),3);
    end
    th=myprctile(base(:),5);
    bg(i)=mean(base(base<th));
    
    trace=squeeze(mean(fmean(:,i,:),3));
    if isfield(ROI_list,'dF_coordinates')
        [M,ind]=max(trace(170:550));
    else
        [M,ind]=max(trace(26:120));
    end
    resp=mean(data(:,:,(ind+25)+(-5:5)),3);
    df_fmap=cat(3,df_fmap,(resp-base)./(base-90));
end
