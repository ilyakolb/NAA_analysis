function [fmeanCFP,fmeanYFP,dff_CFP,dff_YFP,bgCFP,bgYFP,baseCFP,baseYFP,respCFP,respYFP]=NAA_MeasureFmeanFRET(filenames,ROI_list,topbox,botbox,method)

if ~exist('method', 'var')
    method='Local';  %default use local method
end
nFiles=length(filenames);
nROI=length(ROI_list);
info = imfinfo(filenames{1},'tif');
nTime=length(info)-1;

fmeanCFP=zeros(nTime,nFiles,nROI);
fmeanYFP=zeros(nTime,nFiles,nROI);

bgCFP=zeros(length(filenames),1);
bgYFP=zeros(length(filenames),1);
dff_CFP=[];
dff_YFP=[];
baseCFP=[];
baseYFP=[];
respCFP=[];
respYFP=[];
for i=1:length(filenames)
    if strcmp(method,'Local')
        data = readTifStack(filenames{i});    
    elseif strcmp(method,'Network');
        tmpFile = fullfile(pwd, 'tempMeasureFmean.tif');
        copyfile(filenames{i}, tmpFile);
        data = readTifStack(tmpFile);
        delete(tmpFile);
    end
    data=data(:,:,2:end);
    
    CFP=NAA_get_subimage(data,topbox);
    YFP=NAA_get_subimage(data,botbox);
    
          
    ss=size(CFP);
    CFP=reshape(CFP,[],ss(3)); 
    YFP=reshape(YFP,[],ss(3));
    for j=1:length(ROI_list)         
        fmeanCFP(:,i,j)=mean(CFP(ROI_list(j).pixel_list,:))';                    
        fmeanYFP(:,i,j)=mean(YFP(ROI_list(j).pixel_list,:))';                    
    end            
    CFP=reshape(CFP,ss);
    base=mean(CFP(:,:,1:25),3);
    th=myprctile(base(:),5);
    bgCFP(i)=mean(base(base<th));    
    trace=squeeze(mean(fmeanCFP(:,i,:),3));
    [~,ind]=min(trace(26:120));
    resp=mean(CFP(:,:,(ind+25)+(-3:3)),3);
    dff_CFP=cat(3,dff_CFP,(resp-base)./(base-90));
    baseCFP=cat(3,baseCFP,base);
    respCFP=cat(3,respCFP,resp);
    
    
    YFP=reshape(YFP,ss);
    base=mean(YFP(:,:,1:25),3);
    th=myprctile(base(:),5);
    bgYFP(i)=mean(base(base<th));    
    trace=squeeze(mean(fmeanYFP(:,i,:),3));
    [~,ind]=max(trace(26:120));
    resp=mean(YFP(:,:,(ind+25)+(-3:3)),3);
    dff_YFP=cat(3,dff_YFP,(resp-base)./(base-90));
    baseYFP=cat(3,baseYFP,base);
    respYFP=cat(3,respYFP,resp);
end
