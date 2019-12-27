function NAA_script(segment_file_ID, nominal_pulse, type, segmentation_threshold)

global DEBUG;   % If set to anything but [] then debugging code will be run.

analysis_version = '20131021'; %#ok<NASGU>
if (strcmp(type,'GCaMP'))
    type='OGB1'; %patch for analysis GCaMP data without red channel, Hod 20131216
end

%patch for fmax and imfmax - until we get real data  Hod 20131021
fmax=[];
imfmax=[];

if strcmp(type,'FRET96');
    type='FRET';
end

% Delete any files left over from a previous run.
% ionomycin data will be analyzed only if written in lower case letters
% dd=dir;
% dd_ind=dd.isdir;
% for i=1:length(dd_ind)
%     if dd_ind(i)
%         if strcmp(dd(i).name,'ionomycin')
%             % Remove any registration files from a previous run.
%             if exist('fmax.tif', 'file')
%                 delete('fmax.tif');
%             end
%             if exist('fmax_reg.tif', 'file')
%                 delete('fmax_reg.tif');
%             end
%             if exist(fullfile('ionomycin', 'fmax_reg.tif'), 'file')
%                 delete(fullfile('ionomycin', 'fmax_reg.tif'));
%             end
%         end
%     end
% end
if exist('tempMeasureFmean.tif', 'file')
    delete('tempMeasureFmean.tif');
end

files=dir('*.tif');
if strcmpi(type, 'Dye')
    datenum=[files.datenum];
    [~, ind]=sort(datenum);
else
    npulse=zeros(size(files));
    for i=1:length(files)
        info=NAA_file_info(files(i).name);
        npulse(i)=str2double(info.stim_pulse(1:3));
    end
    [~, ind]=sort(npulse);
end

files=files(ind);
filenames={files.name};
if strcmpi(type, 'FRET')
    im=readTifStack(filenames{end}, 1, 150);
    avg=mean(im,3);
    [topbox,botbox,width,height]=NAA_find_splitbox(avg); %#ok<NASGU,ASGLU>
    CFP=NAA_get_subimage(im,topbox);
    YFP=NAA_get_subimage(im,botbox);
    
    CFP_base=mean(CFP(:,:,2:30),3);
    bg_CFP=myprctile(CFP_base,5);
    bg_CFP=mean(CFP_base(CFP_base<bg_CFP));
    if isnan(bg_CFP)
        bg_CFP=1;
    end
    CFP_resp=mean(CFP(:, :, 55:150), 3);
    dF_CFP=CFP_resp-CFP_base;
    % mask1=(CFP_base-bg_CFP)>500;
    %% YFP image registration to CFP
    [optimizer,metric] = imregconfig('monomodal');
    optimizer.MaximumStepLength=0.45;
    optimizer.MaximumIterations=1e11;
    optimizer.RelaxationFactor=0.9;
    YFP_reg=zeros(size(YFP));
    warning off %#ok<WNOFF>
    warning('no warning');
    warning on %#ok<WNON>
    if ~isdeployed && ~isempty(DEBUG)
        h = waitbar(0, 'Images Registration');
    end
    for i=1:size(YFP,3)
        if i==1
            YFP_im=mean(YFP(:,:,1:25),3);
            YFP_vec=reshape(YFP_im,1,[]);
            YFP_vec_ord=sort(YFP_vec);
            thY=YFP_vec_ord(round(0.9*length(YFP_vec)));
            YFP_vec(YFP_vec<thY)=0;
            YFP_im=reshape(YFP_vec,size(YFP_im));
            
            CFP_im=mean(CFP(:,:,1:25),3);
            CFP_vec=reshape(CFP_im,1,[]);
            CFP_vec_ord=sort(CFP_vec);
            thC=CFP_vec_ord(round(0.9*length(CFP_vec)));
            CFP_vec(CFP_vec<thC)=0;
            CFP_im=reshape(CFP_vec,size(CFP_im));
            
            registered_image=imregister(YFP_im,CFP_im,'translation',optimizer,metric);
            if strfind(lastwarn,'failed')
                optimizer.MaximumStepLength=0.015;
                optimizer.RelaxationFactor=0.95;
                warning off %#ok<WNOFF>
                warning('no warning');
                warning on %#ok<WNON>
                registered_image=imregister(YFP_im,CFP_im,'translation',optimizer,metric);
                if strfind(lastwarn,'failed')
                    disp('can not register images')
                    registered_image=mean(YFP,3);  % return to initial mage - since registration failed
                else
                    disp('Problem seems to be solved')
                end
            end
            [r1, c1]=find(YFP_im==max(max(YFP_im)));
            registered_image2=zeros(size(registered_image));
            for r=r1-35:r1+35
                for c=c1-35:c1+35
                    if r>size(registered_image,1)||r<1||c>size(registered_image,2)||c<1
                        continue
                    else
                        registered_image2(r,c)=registered_image(r,c);
                    end
                end
            end
            [r2, c2]=find(registered_image2==max(max(registered_image2)));
            horizontal_shift=c2-c1;
            vertical_shift=r2-r1;
            xform=[1 0 0; 0 1 0;horizontal_shift vertical_shift 1];
            tform_translate=maketform('affine',xform);
        end
        [trans_image, ~, ~]=imtransform(YFP(:,:,i),tform_translate,'Xdata',[1 (size(YFP,2)+xform(3,1))],'Ydata',[1 (size(YFP,1)+xform(3,2))]);
        if xform(3,1)>=0&&xform(3,2)>=0
            YFP_reg(:,:,i)=trans_image(1:end-xform(3,2),1:end-xform(3,1));
        elseif xform(3,1)>=0&&xform(3,2)<0
            YFP_reg(1:end+xform(3,2),:,i)=trans_image(:,1:end-xform(3,1));
        elseif xform(3,1)<0&&xform(3,2)>=0
            YFP_reg(:,1:end+xform(3,1),i)=trans_image(1:end-xform(3,2),:);
        else %both values are negative
            YFP_reg(1:end+xform(3,2),1:end+xform(3,1),i)=trans_image;
        end
        
        if ~isdeployed && ~isempty(DEBUG)
            waitbar(i/size(YFP, 3), h);
        end
    end
    
    if ~isdeployed && ~isempty(DEBUG)
        % Close the progress window.
        close(h);
        
        % Show the registration results.
        figure
        subplot(1,2,1)
        imshowpair(CFP_base,mean(YFP_reg,3))
        title('Registered Images')
        subplot(1,2,2)
        imshowpair(CFP_base,mean(YFP,3))
        title('Original Images')
    end
    
    YFP_base=mean(YFP_reg(:,:,2:30),3);
    bg_YFP=myprctile(YFP_base,5);
    bg_YFP=mean(YFP_base(YFP_base<bg_YFP)); 
    if isnan(bg_YFP)
        bg_YFP=1;
    end
    YFP_resp=mean(YFP_reg(:,:,55:150),3);
    dF_YFP=YFP_resp-YFP_base;
    
else
    im=readTifStack(filenames{segment_file_ID},1,200);
    avg=mean(im,3);
    GCaMPbase=mean(im(:,:,2:30),3);
    bg=myprctile(GCaMPbase,5);
    bg=mean(GCaMPbase(GCaMPbase<bg));
    if isnan(bg)
        bg=1;
    end
    GCaMPresp=mean(im(:,:,55:200),3);
    dF=GCaMPresp-GCaMPbase;
end

%% Create the segmentation_cherry.mat file.
if strcmpi(type, 'Dye')
    cherry_file = dir(fullfile('.', 'Segment', '*Analog*.tif'));
elseif strcmpi(type, 'RCaMP96') || strcmpi(type, 'RCaMP96b')
    cherry_file = dir(fullfile('.', 'Segment', '*GFP*.tif'));
else
    cherry_file = dir(fullfile('.', 'Segment', '*TxRed_t1.tif'));
end
if isempty(cherry_file)
    cherry_file = dir(fullfile('.', 'Segment', '*OGB*')); %just a patch for OGB analysis Hod 20131003
    if isempty(cherry_file)
        error('Could not find the cherry file in the Segment folder.');
    end
end
im=readTifStack(fullfile('.', 'Segment', cherry_file.name));
mCherry = mean(im, 3);
if strcmpi(type, 'FRET')
    %     mCherry = NAA_get_subimage(mCherry, botbox);
    %     mCherry=imregister(mCherry,CFP_base,'translation',optimizer,metric);
    mCherry=CFP_base; % mCherry channel is less informative than CFP channel - 29Mar2013 Hod Dana
end

bg_cherry=myprctile(mCherry,5);
bg_cherry=mean(mCherry(mCherry<bg_cherry));
if isnan(bg_cherry)
    bg_cherry=1;
end
%% DIC file info is ignored - Hod 01Apr2013
% DIC_file=dir(fullfile('.', 'Segment', '*DIC_t1.tif'));
% if ~isempty(DIC_file)
%     im=readTifStack(fullfile('.', 'Segment', DIC_file.name));
%     DIC = mean(im, 3);
%     if strcmpi(type, 'FRET')
%         DIC = DIC(botbox(2):(botbox(2)+height-1), botbox(1):(botbox(1)+width-1)); %#ok<NASGU>
%     end
% else
DIC=[]; %#ok<NASGU>
% end

if strcmpi(type, 'FRET')
    cell_list = NAA_segment_mCherry(cat(3,(CFP_base - bg_CFP),(YFP_base-bg_YFP)), mCherry - bg_CFP, cat(3,dF_CFP,dF_YFP), type, segmentation_threshold);
    cell_max = 500;
    seg_file_name = 'Segmentation.mat';
    seg_file_fields = {'cell_list', 'CFP_base', 'mCherry', 'analysis_version'};
else
    if strcmpi(type, 'Dye')
        cell_list = NAA_segment_dye(filenames{segment_file_ID});
        cell_max = 200;
    else
        %add option to calculate adaptive segmentation threshold - value=0
        
        cell_list = NAA_segment_mCherry(GCaMPbase - bg, mCherry - bg_cherry, dF, type, segmentation_threshold);  %version 1.4 is based on GFP nuclear labeling
        cell_max = 500;
    end
    seg_file_name = 'segmentation_cherry.mat';
    seg_file_fields = {'cell_list', 'GCaMPbase', 'mCherry', 'DIC', 'analysis_version'};
end
save(seg_file_name, seg_file_fields{:});

if length(cell_list) > cell_max  ||  isempty(cell_list)
    return;
end

% Process the ionomycin folder if its name is in lowercase.
% dd=dir;
% dd_ind=dd.isdir;
% for i=1:length(dd_ind)
%     if dd_ind(i)
%         if strcmp(dd(i).name,'ionomycin')
%             if strcmpi(type, 'FRET')
%                 file_fmax=dir(fullfile('ionomycin', '*CyanFP*.tif'));
%             elseif strcmpi(type, 'RCaMP96') || strcmpi(type, 'RCaMP96b')
%                 file_fmax=dir(fullfile('ionomycin', '*TxRed_t1.tif'));
%             else
%                 file_fmax=dir(fullfile('ionomycin', '*GFP*.tif'));
%             end
%             % TODO: check isempty(file_fmax)
%             im_fmax=readTifStack(fullfile('ionomycin',file_fmax.name));
% 
%             im = mean(im_fmax,3);
%             if verLessThan('images', '8.0') || ~license('checkout', 'image_toolbox')
%                 % Use ImageJ to align the image.
%                 imwrite(uint16(avg),'target.tif');
%                 name='fmax.tif';
%                 imwrite(uint16(im),[name(1:end-4),'.tif']);
%                 if ispc
%                     str = ['java -Xmx4096m -jar "C:\Program Files (x86)\ImageJ\ij.jar" -ijpath "C:\Program Files (x86)\ImageJ" -batch register ', name(1:end-4)];
%                 else
%                     str = ['java -Xmx4096m -jar "/misc/local/ImageJ_144/ij.jar" -ijpath "/misc/local/ImageJ_144" -batch register ', name(1:end-4)];
%                     if ismac
%                         % The DYLD_LIBRARY_PATH set up by MATLAB causes Java to fail to launch so don't use it.
%                         str = ['unset DYLD_LIBRARY_PATH; ' str];
%                     end
%                 end
%                 system(str);
%                 imreg = imread('fmax_reg.tif');
%             else
%                 % In MATLAB R2012a and later use the image processing toolbox to align the image.
%                 [optimizer, metric] = imregconfig('monomodal');
%                 imreg = imregister(im, avg, 'rigid', optimizer, metric);
%                 imwrite(uint16(imreg), 'fmax_reg.tif');
%             end
% 
%             % Uncomment to debug
%             if ~isdeployed && ~isempty(DEBUG)
%                 if strcmpi(type, 'Dye')
%                     figure;
%                     subplot(1,2,1); image(NAA_create_overlay(imreg, avg));           axis image;
%                     subplot(1,2,2); image(NAA_create_overlay(mean(im_fmax,3), avg)); axis image;
%                     title(file_fmax.name);
%                 elseif strcmpi(type, 'FRET')
%                     figure;
%                     subplot(2,2,1); image(NAA_create_overlay(YFP_base,mCherry));  axis image;
%                     subplot(2,2,2); image(NAA_create_overlay(CFP_base,mCherry));  axis image;
%                     subplot(2,2,3); image(NAA_create_overlay(CFP_base,YFP_base)); axis image;
%                     subplot(2,2,4); NAA_displayROI(cell_list,-dF_CFP);
%                 end
%             end
% 
%             movefile('fmax_reg.tif', 'ionomycin');
%             if verLessThan('images', '8.0')
%                 delete('fmax.tif');
%                 delete('target.tif');
%             end
% 
%             positive = imreg(imreg>10);
%             th = myprctile(positive, 5);
%             bg = mean(imreg((imreg<th) & (imreg>0)));
%             imreg = imreg - bg;
%             imfmax = imreg; %#ok<NASGU>
%             fmax = zeros(1, length(cell_list));
%             for i = 1:length(cell_list)
%                 fmax(i) = mean(imreg(cell_list(i).pixel_list));
%             end
%         else
%             fmax = [];    %#ok<NASGU>
%             imfmax = [];  %#ok<NASGU>
%         end
%     end
% end


%%
load(seg_file_name);
local=['C','D','F','G'];
currDir=pwd;
% If running on a Linux box (presumably the Janelia cluster) or on a local PC drive then don't copy the file locally.
if (~ismac && ~ispc) || (ispc && ismember(currDir(1),local))
    location = 'Local';
else
    display('Files on network drive, use move local method');
    location = 'Network';
end
if strcmpi(type, 'FRET')
    [fmeanCFP, fmeanYFP, dffmapCFP, dffmapYFP, bgCFP, bgYFP, baseCFP, baseYFP, respCFP, respYFP] = NAA_MeasureFmeanFRET(filenames, cell_list, topbox, botbox, location); %#ok<ASGLU>
    fmean_file_name = 'FmeanROI_FRET.mat';
    save(fmean_file_name, 'fmeanCFP', 'fmeanYFP', 'dffmapCFP', 'dffmapYFP', 'bgCFP', 'bgYFP', 'baseCFP', 'baseYFP', 'respCFP', 'respYFP');
else
    [fmean, df_fmap, bg] = NAA_MeasureFmean(filenames, cell_list, location, mCherry); %#ok<ASGLU>
    fmean_file_name = 'FmeanROI_cherry.mat';
    save(fmean_file_name, 'fmean', 'df_fmap', 'bg');
end


%%
xsgfiles=dir('*.xsg');
datenum=[xsgfiles.datenum];
[~, ind]=sort(datenum);
xsgfiles=xsgfiles(ind);
xsgfilenames={xsgfiles.name};
for i=1:length(ind)
    ephus_info_file(i)=NAA_getEphus_info(xsgfilenames{i});     %#ok<AGROW>
end

npulse=[ephus_info_file.nVPulse];
for i=1:length(nominal_pulse)
    [~, ind]=min(abs(nominal_pulse(i)-npulse));
    ephus_info(i)=ephus_info_file(ind); %#ok<AGROW>
end

temperature1=[ephus_info.AvgTemp1]; %#ok<NASGU>
temperature2=[ephus_info(i).AvgTemp2]; %#ok<NASGU>

%%
load(fmean_file_name);
load(seg_file_name);

if strcmpi(type, 'FRET')
    dr_rmap=[];
    for i=1:size(baseCFP,3)
        rbase=(baseYFP(:,:,i)-100)./(baseCFP(:,:,i)-100);
        rresp=(respYFP(:,:,i)-100)./(respCFP(:,:,i)-100);
        
        %% Get rid of NaN and Inf values
        ind1=find(isnan(rresp));
        rresp(ind1)=0;
        ind2=find(isinf(rresp));
        rresp(ind2)=0;
        ind3=find(isnan(rbase));
        rbase(ind3)=0;
        ind4=find(isinf(rbase));
        rbase(ind4)=0;
        tmp=(rresp-rbase)./rbase;
        tmp(ind3)=0;
        tmp(ind4)=0;
        dr_rmap=cat(3,dr_rmap,tmp);
    end
    [para_arrayCFP,summaryCFP,fmeanCFP_bgremoved]=NAA_MeasurePara(fmeanCFP,bgCFP,ephus_info,1); %#ok<ASGLU>
    [para_arrayYFP,summaryYFP,fmeanYFP_bgremoved]=NAA_MeasurePara(fmeanYFP,bgYFP,ephus_info); %#ok<ASGLU>
    Ratio=fmeanYFP_bgremoved./fmeanCFP_bgremoved;
    [para_arrayRatio,summaryRatio]=NAA_MeasurePara(Ratio,0,ephus_info);
    para_array=para_arrayRatio; %#ok<NASGU>
    fmean=Ratio; 
    
    % Measure FRET SNR for Twitch paper
    base_signal1=squeeze(fmean(1:23,1,:));
    noise_signal1=median(std(base_signal1));
    R_signal1=median(max(squeeze(fmean(25:end,1,:)))-mean(base_signal1));
    SNR1=R_signal1./noise_signal1;
    SNR1_STD=std((max(squeeze(fmean(25:end,1,:)))-mean(base_signal1))./std(base_signal1));
    
    base_signal3=squeeze(fmean(1:23,2,:));
    noise_signal3=median(std(base_signal3));
    R_signal3=median(max(squeeze(fmean(25:end,2,:)))-mean(base_signal3));
    SNR3=R_signal3./noise_signal3;
    SNR3_STD=std((max(squeeze(fmean(25:end,2,:)))-mean(base_signal3))./std(base_signal3));

    base_signal10=squeeze(fmean(1:23,3,:));
    noise_signal10=median(std(base_signal10));
    R_signal10=median(max(squeeze(fmean(25:end,3,:)))-mean(base_signal10));
    SNR10=R_signal10./noise_signal10;
    SNR10_STD=std((max(squeeze(fmean(25:end,3,:)))-mean(base_signal10))./std(base_signal10));

    base_signal160=squeeze(fmean(1:23,4,:));
    noise_signal160=median(std(base_signal160));
    R_signal160=median(max(squeeze(fmean(25:end,4,:)))-mean(base_signal160));
    SNR160=R_signal160./noise_signal160;
    SNR160_STD=std((max(squeeze(fmean(25:end,4,:)))-mean(base_signal160))./std(base_signal160));

    
    SNR=[SNR1 SNR3 SNR10 SNR160]; %#ok<NASGU>
    SNR_STD=[SNR1_STD SNR3_STD SNR10_STD SNR160_STD];
    
    summary=summaryRatio; %#ok<NASGU>
    save('para_array_cherry.mat','para_arrayCFP','summaryCFP','para_arrayYFP','summaryYFP',...
        'para_arrayRatio','para_array','fmean','summary','summaryRatio','cell_list','CFP_base','YFP_base','dr_rmap','mCherry','DIC','bgCFP','bgYFP',...
        'fmeanCFP','fmeanYFP','fmax','ephus_info','temperature1','temperature2','imfmax','SNR','SNR_STD','analysis_version');
elseif strcmp(type,'RCaMP96b');
    [para_array, summary]=NAA_MeasurePara(fmean,bg,ephus_info); %#ok<NASGU,ASGLU>
    
    %% Photoswitch and bleach measurements
    
    bl = dir(fullfile('.', 'Segment', '*bleach*.tif'));
    im_bleach=readTifStack(fullfile('.', 'Segment', bl.name));
    before_bleach=im_bleach(:,:,2);
    before_bleach=reshape(before_bleach,1,[]);
    after_bleach=im_bleach(:,:,end);
    after_bleach=reshape(after_bleach,1,[]);
    tmp1=0;
    tmp2=0;
    for i=1:length(cell_list)
        tmp1=tmp1+sum(before_bleach(cell_list(1,i).pixel_list));
        tmp2=tmp2+sum(after_bleach(cell_list(1,i).pixel_list));
    end
    bleach=(tmp1-tmp2)/tmp1; %#ok<NASGU> %fraction of initial fluorescence
    
    psw_before=dir(fullfile('.', 'Segment', '*prephotoswitch*.tif'));
    im_psw_before=readTifStack(fullfile('.', 'Segment', psw_before.name),1,10);
    im_psw_before=mean(im_psw_before(:,:,2:end),3);
    im_psw_before=reshape(im_psw_before,1,[]);
    
    psw_during=dir(fullfile('.', 'Segment', '*photoswitch_photoswitch*.tif'));
    im_psw_during=readTifStack(fullfile('.', 'Segment', psw_during.name));
    im_psw_during=reshape(im_psw_during,[],size(im_psw_during,3));
    
    psw_after=dir(fullfile('.', 'Segment', '*postphotoswitch*.tif'));
    im_psw_after=readTifStack(fullfile('.', 'Segment', psw_after.name),1,10);
    im_psw_after=mean(im_psw_after(:,:,2:end),3);
    im_psw_after=reshape(im_psw_after,1,[]);
   
    for i=1:length(cell_list)
        base(i)=mean(im_psw_before(cell_list(1,i).pixel_list));
        tmp=mean(im_psw_during(cell_list(1,i).pixel_list,:),1);
        resp(i)=max(tmp);
        psw(i)=(resp(i)-base(i))/base(i); %photoswitch effect as a fraction of baseline fluorescence
        post(i)=mean(im_psw_after(cell_list(1,i).pixel_list));
        psw_b2b(i)=(post(i)-base(i))/base(i); %back to baseline after PSW
    end
    med_psw=median(psw); %#ok<NASGU>
    med_psw_b2b=median(psw_b2b); %#ok<NASGU>
    
    save('para_array_cherry.mat','para_array','summary','cell_list','df_fmap','GCaMPbase','mCherry','DIC', ...
        'bg','fmean','fmax','ephus_info','temperature1','temperature2','imfmax','analysis_version','bleach','med_psw','med_psw_b2b');
else
    [para_array, summary]=NAA_MeasurePara(fmean,bg,ephus_info); %#ok<NASGU,ASGLU>
    
    save('para_array_cherry.mat','para_array','summary','cell_list','df_fmap','GCaMPbase','mCherry','DIC', ...
        'bg','fmean','fmax','ephus_info','temperature1','temperature2','imfmax','analysis_version');
end
