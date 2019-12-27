function NAA_script(segment_file_ID, nominal_pulse, type, segmentation_threshold,threshold2)

analysis_version = '20130104'; %#ok<NASGU>

if isdir('ionomycin')
    % Remove any registration files from a previous run.
    if exist('fmax.tif', 'file')
        delete('fmax.tif');
    end
    if exist('fmax_reg.tif', 'file')
        delete('fmax_reg.tif');
    end
    if exist(fullfile('ionomycin', 'fmax_reg.tif'), 'file')
        delete(fullfile('ionomycin', 'fmax_reg.tif'));
    end
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
    im=readTifStack(filenames{end},1,65);
    avg=mean(im,3);
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
    bg_YFP=mean(YFP_base(YFP_base<bg_YFP)); %#ok<NASGU>
    YFP_resp=mean(YFP(:,:,55:65),3);
    dF_YFP=YFP_resp-YFP_base; %#ok<NASGU>
else
    im=readTifStack(filenames{segment_file_ID},1,65);
    avg=mean(im,3);
    GCaMPbase=mean(im(:,:,2:30),3);
    bg=myprctile(GCaMPbase,5);
    bg=mean(GCaMPbase(GCaMPbase<bg));

    GCaMPresp=mean(im(:,:,50:65),3);
    dF=GCaMPresp-GCaMPbase;
end

%% changed by Hod 05Feb2013
th_dF=20;
ind=find(dF<th_dF);
dF(ind)=0;
%% end of change

%% Create the segmentation_cherry.mat file.
if strcmpi(type, 'Dye')
    cherry_file = dir(fullfile('.', 'Segment', '*Analog*.tif'));
elseif strcmpi(type, 'RCaMP96')
    cherry_file = dir(fullfile('.', 'Segment', '*GFP*.tif'));
else
    cherry_file = dir(fullfile('.', 'Segment', '*TxRed_t1.tif'));
end
if isempty(cherry_file)
    error('Could not find the cherry file in the Segment folder.');
end
im=readTifStack(fullfile('.', 'Segment', cherry_file.name));
mCherry = mean(im, 3);
if strcmpi(type, 'FRET')
    mCherry = NAA_get_subimage(mCherry, botbox);
end

bg_cherry=myprctile(mCherry,5);
bg_cherry=mean(mCherry(mCherry<bg_cherry));

DIC_file=dir(fullfile('.', 'Segment', '*DIC_t1.tif'));
if ~isempty(DIC_file)
    im=readTifStack(fullfile('.', 'Segment', DIC_file.name));
    DIC = mean(im, 3); 
    if strcmpi(type, 'FRET')
        DIC = DIC(botbox(2):(botbox(2)+height-1), botbox(1):(botbox(1)+width-1)); %#ok<NASGU>
    end
else
    DIC=[]; %#ok<NASGU>
end

if strcmpi(type, 'FRET')
    % TODO: which segmentation method should be used?
    cell_list = NAA_segment_mCherry(CFP_base - bg_CFP, mCherry - bg_CFP, dF_CFP, type, segmentation_threshold);
    %[cell_list, ~] = segment_meth1(-dF_CFP);
    cell_max = 500;
    seg_file_name = 'Segmentation.mat';
    seg_file_fields = {'cell_list', 'CFP_base', 'mCherry', 'analysis_version'};
else
    if strcmpi(type, 'Dye')
        cell_list = NAA_segment_dye(filenames{segment_file_ID});
        cell_max = 200;
    else
        %%changed by Hod 05Feb2013
%         cell_list = NAA_segment_mCherry(GCaMPbase - bg, mCherry - bg_cherry, dF, type, segmentation_threshold);
          cell_list=dF_based_segmentation(GCaMPbase - bg, mCherry - bg_cherry, dF, type, segmentation_threshold,threshold2);  
          %% end of change
        cell_max = 500;
    end
    seg_file_name = 'segmentation_cherry.mat';
    seg_file_fields = {'cell_list', 'GCaMPbase', 'mCherry', 'DIC', 'analysis_version'};
end
save(seg_file_name, seg_file_fields{:});

if length(cell_list) > cell_max  ||  isempty(cell_list)
    return;
end

%%
if isdir('ionomycin')
    if strcmpi(type, 'FRET')
        file_fmax=dir(fullfile('ionomycin', '*CyanFP*.tif'));
    elseif strcmpi(type, 'RCaMP96')
        file_fmax=dir(fullfile('ionomycin', '*TxRed_t1.tif'));
    else
        file_fmax=dir(fullfile('ionomycin', '*GFP*.tif'));
    end
    im_fmax=readTifStack(fullfile('ionomycin',file_fmax.name));
    
    im = mean(im_fmax,3);
    if verLessThan('images', '8.0') || ~license('checkout', 'image_toolbox')
        % Use ImageJ to align the image.
        imwrite(uint16(avg),'target.tif');
        name='fmax.tif';
        imwrite(uint16(im),[name(1:end-4),'.tif']);
        if ispc
            str = ['java -Xmx4096m -jar "C:\Program Files (x86)\ImageJ\ij.jar" -ijpath "C:\Program Files (x86)\ImageJ" -batch register ', name(1:end-4)];
        else
            str = ['java -Xmx4096m -jar "/misc/local/ImageJ_144/ij.jar" -ijpath "/misc/local/ImageJ_144" -batch register ', name(1:end-4)];
            if ismac
                % The DYLD_LIBRARY_PATH set up by MATLAB causes Java to fail to launch so don't use it.
                str = ['unset DYLD_LIBRARY_PATH; ' str];
            end
        end
        system(str);
        imreg = imread('fmax_reg.tif');
    else
        % In MATLAB R2012a and later use the image processing toolbox to align the image.
        [optimizer, metric] = imregconfig('monomodal');
        imreg = imregister(im, avg, 'rigid', optimizer, metric);
        imwrite(uint16(imreg), 'fmax_reg.tif');
    end
    
%     % Uncomment to debug    
%     if ~isdeployed
%         if strcmpi(type, 'Dye')
%             figure;
%             subplot(1,2,1); image(NAA_create_overlay(imreg, avg));           axis image;
%             subplot(1,2,2); image(NAA_create_overlay(mean(im_fmax,3), avg)); axis image;
%             title(file_fmax.name);
%         elseif strcmpi(type, 'FRET')
%             figure;
%             subplot(2,2,1); image(NAA_create_overlay(YFP_base,mCherry));  axis image;
%             subplot(2,2,2); image(NAA_create_overlay(CFP_base,mCherry));  axis image;
%             subplot(2,2,3); image(NAA_create_overlay(CFP_base,YFP_base)); axis image;
%             subplot(2,2,4); NAA_displayROI(cell_list,-dF_CFP);
%         end
%     end
    
    movefile('fmax_reg.tif', 'ionomycin');
    if verLessThan('images', '8.0')
        delete('fmax.tif');
        delete('target.tif');
    end
    
    positive = imreg(imreg>10);
    th = myprctile(positive, 5);
    bg = mean(imreg((imreg<th) & (imreg>0)));
    imreg = imreg - bg;
    imfmax = imreg; %#ok<NASGU>
    fmax = zeros(1, length(cell_list));
    for i = 1:length(cell_list)
        fmax(i) = mean(imreg(cell_list(i).pixel_list));
    end
else
    fmax = [];    %#ok<NASGU>
    imfmax = [];  %#ok<NASGU>
end



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
       dr_rmap=cat(3,dr_rmap,(rresp-rbase)./rbase);   
    end
    [para_arrayCFP,summaryCFP,fmeanCFP_bgremoved]=NAA_MeasurePara(fmeanCFP,bgCFP,ephus_info,1); %#ok<ASGLU>
    [para_arrayYFP,summaryYFP,fmeanYFP_bgremoved]=NAA_MeasurePara(fmeanYFP,bgYFP,ephus_info); %#ok<ASGLU>
    Ratio=fmeanYFP_bgremoved./fmeanCFP_bgremoved;
    [para_arrayRatio,summaryRatio]=NAA_MeasurePara(Ratio,0,ephus_info); %#ok<NASGU,ASGLU>
    
    save('para_array_cherry.mat','para_arrayCFP','summaryCFP','para_arrayYFP','summaryYFP',...
         'para_arrayRatio','summaryRatio','cell_list','CFP_base','YFP_base','dr_rmap','mCherry','DIC','bgCFP','bgYFP',...
         'fmeanCFP','fmeanYFP','fmax','ephus_info','temperature1','temperature2','imfmax','analysis_version');
else
    [para_array, summary]=NAA_MeasurePara(fmean,bg,ephus_info); %#ok<NASGU,ASGLU>
    
    save('para_array_cherry.mat','para_array','summary','cell_list','df_fmap','GCaMPbase','mCherry','DIC', ...
         'bg','fmean','fmax','ephus_info','temperature1','temperature2','imfmax','analysis_version');
end
