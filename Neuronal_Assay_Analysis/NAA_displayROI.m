function roiImage = NAA_displayROI(ROI_list,refim)

if nargin==1
    ss=[512,512];    
elseif nargin==2    
    ss=size(refim);    
end
    
if exist('refim', 'var')
    flag=0;
    if ndims(refim)==2
        MM=myprctile(refim,99.3);
        mm=myprctile(refim,1);
        refim=round((refim-mm)/(MM-mm)*255);
        refim(refim>255)=255;
        refim(refim<0)=0;
        map=jet(256);
        refim=ind2rgb(refim,map);
        flag=0;
    end
    ss=size(refim);
    refim=reshape(refim,[],3);
    for i=1:length(ROI_list)
        BW=false(ss(1:2));
        BW(ROI_list(i).pixel_list)=1;
        B = bwperim(BW,4);
        if flag
            refim(B,:)=0;
        else
            refim(B,:)=1;
%             refim(B,1)=1;
        end
    end
    refim=reshape(refim,ss);
    refim_RCaMP=zeros(size(refim));   %changed by Hod 14 May 2013 to fit to RCaMP with NLS GFP experiments
    refim_RCaMP(:,:,1)=refim(:,:,1);
    refim_RCaMP(:,:,2)=refim(:,:,2);
    refim_RCaMP(:,:,3)=refim(:,:,3);  %added by Hod 20131021 - make segmentation lines more visible

    image(refim_RCaMP);axis image
else
    roimap=zeros([ss(1)*ss(2),3]);
    if ~isempty(ROI_list)
        if isfield(ROI_list(1),'nuc_list')
            GCaMP_total=[ROI_list.GCaMP_total];
            mCherry=[ROI_list.mCherry];
            for i=1:length(ROI_list)
                roimap(setdiff(ROI_list(i).pixel_list,ROI_list(i).nuc_list),2)=(ROI_list(i).GCaMP_total)/myprctile(GCaMP_total,95);
                roimap(ROI_list(i).nuc_list,1)=(ROI_list(i).mCherry)/myprctile(mCherry,95);
            end
        else
            for i=1:length(ROI_list)
                roimap(ROI_list(i).pixel_list,2)=1;
            end
        end
    end
    roimap(roimap>1)=1;roimap(roimap<0)=0;
    roimap=reshape(roimap,[ss,3]);
    roimap_RCaMP=zeros(size(roimap));
    roimap_RCaMP(:,:,1)=roimap(:,:,2);  % changed by Hod May 14 2013
    roimap_RCaMP(:,:,2)=roimap(:,:,1);
    image(roimap_RCaMP);axis image
end


