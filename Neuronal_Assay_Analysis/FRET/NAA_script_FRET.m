% function NAA_script_FRET
files=dir('*.tif');
npulse=zeros(size(files),1);
for i=1:length(files)
    info=NAA_file_info(files(i).name);
    npulse(i)=str2num(info.stim_pulse(1:3));
end
[s,ind]=sort(npulse);

files=files(ind);
filenames={files.name};
im=readTifStack(filenames{end},1,65);
avg=mean(im,3);

%%
[topbox,botbox,width,height]=NAA_find_splitbox(avg);
CFP=NAA_get_subimage(im,topbox);
YFP=NAA_get_subimage(im,botbox);

CFP_base=mean(CFP(:,:,2:30),3);
bg_CFP=myprctile(CFP_base,5);
bg_CFP=mean(CFP_base(CFP_base<bg_CFP));
CFP_resp=mean(CFP(:,:,55:65),3);
dF_CFP=CFP_resp-CFP_base;
% mask1=(CFP_base-bg_CFP)>500;

YFP_base=mean(YFP(:,:,2:30),3);
bg_YFP=myprctile(YFP_base,5);
bg_YFP=mean(YFP_base(YFP_base<bg_YFP));
YFP_resp=mean(YFP(:,:,55:65),3);
dF_YFP=YFP_resp-YFP_base;


%%
cherry_file=dir('.\segment\*TxRED_t1.tif');
im=readTifStack(['.\Segment\',cherry_file.name]);
mCherry=mean(im,3);
mCherry=NAA_get_subimage(mCherry,botbox);

% mCherry=mCherry(botbox(2):(botbox(2)+height-1),botbox(1):(botbox(1)+width-1));
bg_cherry=myprctile(mCherry,5);
bg_cherry=mean(mCherry(mCherry<bg_cherry));

DIC_file=dir('.\segment\*DIC_t1.tif');
if ~isempty(DIC_file)
    im=readTifStack(['.\Segment\',DIC_file.name]);
    DIC=mean(im,3);
    DIC=DIC(botbox(2):(botbox(2)+height-1),botbox(1):(botbox(1)+width-1));
else
    DIC=[];
end
overlay1=NAA_create_overlay(YFP_base,mCherry);
overlay2=NAA_create_overlay(CFP_base,mCherry);
overlay3=NAA_create_overlay(CFP_base,YFP_base);
% cell_list=NAA_segment_FRET(YFP_base-100,mCherry-bg_cherry,-dF_CFP);

[cell_list,ROImap]=segment_meth1(-dF_CFP);
save('Segmentation.mat','cell_list');
% save('segmentation_cherry.mat','cell_list','GCaMPbase','mCherry','DIC');
if length(cell_list)>500  ||  isempty(cell_list)
    return;
end
figure;subplot(2,2,1);image(overlay1);axis image;subplot(2,2,2);image(overlay2);axis image;subplot(2,2,3);image(overlay3);axis image;
subplot(2,2,4);NAA_displayROI(cell_list,-dF_CFP);
%%
if 0%isdir('ionomycin')
    file_fmax=dir('ionomycin\*GFP*.tif');
    im_fmax=readTifStack(['ionomycin\',file_fmax.name]);
    imwrite(uint16(GCaMPavg),'target.tif');
    name='fmax.tif';
	imwrite(uint16(mean(im_fmax,3)),[name(1:end-4),'.tif']);
    str=['java -Xmx4096m -jar "C:\Program Files (x86)\ImageJ\ij.jar" -ijpath "C:\Program Files (x86)\ImageJ" -batch register ',name(1:end-4)];
    system(str);
    
    imreg=imread('fmax_reg.tif');
    overlay=NAA_create_overlay(imreg,GCaMPavg);        
    overlay2=NAA_create_overlay(mean(im_fmax,3),GCaMPavg);
%     figure;
%     subplot(1,2,1);
%     image(overlay);axis image;
%     subplot(1,2,2);
%     image(overlay2);axis image;
%     title(file_fmax.name);
    
    
    system('move fmax_reg.tif .\ionomycin\');
    delete('fmax.tif');
    delete('target.tif');
    
    
    positive=imreg(imreg>10);
    th=myprctile(positive,5);
    bg=mean(imreg((imreg<th)&(imreg>0)));
    imreg=imreg-bg;
    imfmax=imreg;
    fmax=[];
    for i=1:length(cell_list)
        fmax(i)=mean(imreg(cell_list(i).pixel_list));
    end
else
    fmax=[];
    imfmax=[];
end



%%
load Segmentation
local=['C','D','F','G'];
currDir=pwd;
if ismember(currDir(1),local)
   [fmeanCFP,fmeanYFP,dffmapCFP,dffmapYFP,bgCFP,bgYFP,baseCFP,baseYFP,respCFP,respYFP]=NAA_MeasureFmeanFRET(filenames,cell_list,topbox,botbox,'Local');
%     [fmean,df_fmap,bg]=NAA_MeasureFmean(filenames,cell_list,'Local',mCherry);
else
    display('Files on network drive, use move local method');
   [fmeanCFP,fmeanYFP,dffmapCFP,dffmapYFP,bgCFP,bgYFP,baseCFP,baseYFP,respCFP,respYFP]=NAA_MeasureFmeanFRET(filenames,cell_list,topbox,botbox,'Network');
%     [fmean,df_fmap,bg]=NAA_MeasureFmean(filenames,cell_list,'Network',mCh
%     erry);
end
% save('FmeanROI_cherry.mat','fmean','df_fmap','bg');
save('FmeanROI_FRET.mat','fmeanCFP','fmeanYFP','dffmapCFP','dffmapYFP','bgCFP','bgYFP','baseCFP','baseYFP','respCFP','respYFP');

%%
xsgfiles=dir('*.xsg');
datenum=[xsgfiles.datenum];
[s,ind]=sort(datenum);
xsgfiles=xsgfiles(ind);
xsgfilenames={xsgfiles.name};
temperature1=[];
temperature2=[];
for i=1:length(ind)
    ephus_info_file(i)=NAA_getEphus_info(xsgfilenames{i});    
end

nominal_pulse=[1,2,3,5,10,20,40,80,160];
npulse=[ephus_info_file.nVPulse];
for i=1:length(nominal_pulse)
    [m,ind]=min(abs(nominal_pulse(i)-npulse));
    ephus_info(i)=ephus_info_file(ind);
end

temperature1=[ephus_info.AvgTemp1];
temperature2=[ephus_info(i).AvgTemp2];

%% 
load FmeanROI_FRET;
load Segmentation;
dr_rmap=[];
for i=1:size(baseCFP,3)
   rbase=(baseYFP(:,:,i)-100)./(baseCFP(:,:,i)-100);
   rresp=(respYFP(:,:,i)-100)./(respCFP(:,:,i)-100);
   dr_rmap=cat(3,dr_rmap,(rresp-rbase)./rbase);   
end
[para_arrayCFP,summaryCFP,fmeanCFP_bgremoved]=NAA_MeasurePara(fmeanCFP,bgCFP,ephus_info,1);
[para_arrayYFP,summaryYFP,fmeanYFP_bgremoved]=NAA_MeasurePara(fmeanYFP,bgYFP,ephus_info);
Ratio=fmeanYFP_bgremoved./fmeanCFP_bgremoved;
[para_arrayRatio,summaryRatio]=NAA_MeasurePara(Ratio,0,ephus_info);

save('para_array_cherry.mat','para_arrayCFP','summaryCFP','para_arrayYFP','summaryYFP',...
'para_arrayRatio','summaryRatio','cell_list','CFP_base','YFP_base','dr_rmap','mCherry','DIC','bgCFP','bgYFP',...
'fmeanCFP','fmeanYFP','fmax','ephus_info','temperature1','temperature2','imfmax');

