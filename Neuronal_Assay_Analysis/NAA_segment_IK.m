function ROI_list = NAA_segment_IK(GCaMPbase, mCherry, dF, type, segmentation_threshold,GCaMPbase2)
% ilya modifications to segmentation code
%version 4 - removing greenish nuceli for RCaMP96 (no nuclear GFP) - since it's a debree/dead cell, Hod 20140412 
%version 4 - modified for low F0 GCaMPs - for GCaMP96 there will be no
%threshold on F0 GCaMP signal
%version 4 on 20140811 - GCaMP96b class of low F0 variants was added. dF is used for
%segmentation instead of GCaMPbase
% IK modified 11/15/19 for Abhi's mng-GECO
DEBUG=1; %% IK MOD change back to DEBUG = 0;

if strcmpi(type, 'GCaMP96bf')||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf') || strcmpi(type, 'mngGECO')
    GCaMPbase=GCaMPbase2;
end
% if strcmp(type,'GCaMP96b')
%     GCaMPbase=dF;
% end
% 
if strcmp(type,'FRET')  %% added by Hod Dana 29Mar2013
    CFP_base=GCaMPbase(:,:,1);
    YFP_base=GCaMPbase(:,:,2);
    s=size(dF,3);
    CFP_dF=dF(:,:,s/2);
    YFP_dF=dF(:,:,s/2+1:s);
    GCaMPbase=CFP_base; %this image will be used for segmentation
    mCherry=YFP_base;
    dF=YFP_dF; %this dF will be used for segmentation
end

%%
ss=size(GCaMPbase);
%%
reg=11;
cen=(reg+1)/2;
h2=zeros(reg,reg);
%% start of change Hod 11Jul 2013 - changing conv kernel to better identify nuclear excluded cells - cancelled 22Jul2013
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

%trying different convolution kernel (Gaussian)
% x=1:reg;
% y=x;
% [X,Y]=meshgrid(x,y);
% h2=exp(-(((X-cen).^2)+(Y-cen).^2)/(reg/4)^2);
% m=sum(sum(h2))/numel(h2);
% h2=h2-m;
% clear x y X Y m
%% end of change Hod 11Jul2013
%%
%% changed by Hod 13Feb2013, changed back 22Jul2013 (NLS GFP available)

filt_map=imfilter(GCaMPbase,h2,'symmetric'); % IKMOD: filt_map=imfilter(mCherry,h2,'symmetric'); 

if (strcmpi(type, 'RCaMP96'))||(strcmpi(type, 'OGB1'))
    filt_map=imfilter(GCaMPbase,h2,'symmetric');  % no green (nls GFP) channel available
end
if (strcmpi(type, 'P4a-20130812-GCaMP-no-mCherry'))
    filt_map=imfilter(dF,h2,'symmetric');  % no red (nls mCherry) channel available, Hod 20131220
end
if (strcmpi(type, 'GCaMP96z'))||(strcmpi(type, 'RCaMP96z'))
    filt_map2=imfilter(GCaMPbase,h2,'symmetric'); %20160923 better detection of low F0 variants
end
% filt_map=imfilter(GCaMPbase,h2,'symmetric');
%% end of change

maximal=local_maximal(filt_map).*filt_map;
peakvalue=maximal(maximal>0);
if (strcmpi(type, 'RCaMP96'))
    % adding adaptive threshold to find local maxima - Hod Dana 4Apr2013
    filt_map_order=sort(reshape(filt_map,1,[]));
    th=filt_map_order(round(0.98*numel(filt_map_order)));
elseif(strcmpi(type, 'OGB1'))
    % adding adaptive threshold to find local maxima - Hod Dana 4Apr2013
    filt_map_order=sort(reshape(filt_map,1,[]));
    th=filt_map_order(round(0.992*numel(filt_map_order)));
elseif(strcmpi(type, 'RCaMP96b')||strcmpi(type, 'RCaMP96c'))
    % for RCaMP96b - adding a constant threshold
    %     th=1800; %based on GFP expression levels
    filt_map_order=sort(reshape(filt_map,1,[]));
    th=filt_map_order(round(0.992*numel(filt_map_order)));
elseif(strcmpi(type, 'GCaMP96bf'))||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf') || strcmpi(type, 'mngGECO')
    filt_map_order=sort(reshape(filt_map,1,[]));
    th=filt_map_order(round(0.9875*numel(filt_map_order)));
elseif(strcmpi(type, 'GCaMP96'))
    % adding adaptive threshold to find local maxima for low F0 GCaMPs
    % - Hod Dana 27Dec2013, activated and modified Hod 20140409
    filt_map_order=sort(reshape(filt_map,1,[]));
    th=filt_map_order(round(0.95*numel(filt_map_order)));
elseif(strcmpi(type, 'GCaMP96b')) %added by Hod 20140811, 
    filt_map_order=sort(reshape(filt_map,1,[]));
    th=filt_map_order(round(0.95*numel(filt_map_order)));
elseif(strcmpi(type, 'GCaMP96z'))||(strcmpi(type, 'RCaMP96z'))||(strcmpi(type, 'GCaMP96c')) %updated 20160916 anf 20170314 HD
    filt_map_order=sort(reshape(filt_map,1,[]));
    th=filt_map_order(round(0.98*numel(filt_map_order)));
elseif (strcmpi(type, 'FRET'))
    th = kmean1D_threshold(peakvalue, 0.3);
else
    th = kmean1D_threshold(peakvalue, 0.42);
end
val=maximal(maximal>th);
[~,ind]=sort(val,'descend');
[row,col]=find(maximal>th);
row=row(ind);
col=col(ind);

% if length(ind)>5000
%     ROI_list=[];
%     if ~isdeployed && ~isempty(DEBUG)
%         if strcmpi(type, 'RCaMP96')||strcmpi(type, 'RCaMP96b')
%             overlay = NAA_create_overlay(mCherry, GCaMPbase);
%         else
%             overlay = NAA_create_overlay(GCaMPbase, mCherry);
%         end
%         figure;image(overlay);
%     end
%     return;
% end

if (strcmpi(type, 'RCaMP96b')||strcmpi(type, 'RCaMP96c'))
    radius_neu=4;
elseif strcmpi(type, 'RCaMP96')||strcmpi(type, 'FRET')||strcmpi(type, 'OGB1')
    radius_neu=6;
else
    radius_neu=7.5; % IKMOD radius_neu=4;
end

radius_cell=7.5; % IKMOD radius_cell=7.5;
%%
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
if (strcmpi(type, 'GCaMP96bf'))||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf') || strcmpi(type, 'mngGECO')
    ss=size(mCherry);
end
se = strel('square',5);
ROI_list=[];
ROI=[];
% coll=col; %bug fixing ?  Hod 20170307
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
    
    
    pixel_list=find(BW2);
    
    
    %% added by Hod 13Feb2013
    [is_round_, area_] = cell_shaped_segmentation(BW2);
    %         is_round(i)=is_round_;
    %         area(i)=area_;
    
    %         mean_GCaMP=mean(GCaMPbase(pixel_list));
    %         loc=round(0.99*numel(GCaMPbase));
    %         G=sort(reshape(GCaMPbase,[],1));
    %         G_th=G(loc);
    %         if max(mean_GCaMP)>G_th
    %             if (is_round_<0.73||area_<20)
    %                 continue
    %             end
    %         elseif (is_round_<0.80||area_<25)
    %             continue
    %         end
    %% end of addition
    
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
        if strcmpi(type, 'GCaMP96bf')||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf') || strcmpi(type, 'mngGECO')
            
            % convert_cell_coordinates_GCaMPbf was giving wrong coords.
            % IK corrected 12/4/19 
            convert_cell_coordinates_GCaMPbf_IK;
            ROI.dF_coordinates=unique(cell_coordinates);
            ROI.dF=mean(dF(ROI.dF_coordinates))/25;  %normalized dF to dif in # pixels
        else
            ROI.dF=mean(dF(ROI.pixel_list));
        end
        %          if strcmp(type,'FRET')  %% added by Hod Dana 29Mar2013
        %             ROI.GCaMP_total=mean(YFP_base(ROI.pixel_list))./mean(CFP_base(ROI.pixel_list)); %R0
        %             ROI.dF=mean(YFP_dF(ROI.pixel_list))./mean(CFP_dF(ROI.pixel_list));   %dR
        %         end
        
        %shape parameters added for ROI_list, version 3 20130815
        ROI.area=area_;
        ROI.is_round=is_round_;
        
        
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
% ROI_list=ROI_list(~remove_ind);

%%  remove really dark cells likely from over segmentation

if ~isempty(segmentation_threshold)
    %% adding adaptive threshold - Hod Dana 04Apr2013, modifying this threshold Hod 20130815
    if segmentation_threshold==0
        %             GClist=sort(reshape(GCaMPbase,1,[]));
        %             th=GClist(round(0.96*length(GClist)));
        %             mClist=sort(reshape(mCherry,1,[]));
        %             th_nucleus=mClist(round(0.96*length(mClist)));
        %             GClist=[ROI_list.GCaMP_total];
        gc=reshape(GCaMPbase,[],1);
        %         th=3*median(gc); %the median value represent the noise level in the system
        sgc=sort(gc);
        th=5*(sgc(round(0.15*length(gc)))); %Hod 20150723, better estim of noise level
        if strcmp(type, 'GCaMP96')
            th=0;  %modified for low F0 GCaMPs
        end
        if strcmp(type, 'GCaMP96b') %added by Hod 20140811
            GCaMPbase=dF;
            gc=sort(reshape(GCaMPbase,[],1));
            %             th=1*median(gc); %the median value represent the noise level in the system
            th=gc(round(0.3*numel(gc)));
        elseif strcmp(type, 'GCaMP96z')||(strcmpi(type, 'RCaMP96z')) %added by Hod 20160916, updated 20161122,, updated 20170306
            noise_med_estim=sgc(round(0.5*length(sgc)));
            noise_std_estim=std(sgc(round(0.2*length(sgc)):round(0.65*length(sgc))));
            th=noise_med_estim+2*noise_std_estim; %new expression threshold for GCaMP96z, should catch dim cells
        elseif strcmp(type, 'GCaMP96c') % updated 20170314
            noise_med_estim=sgc(round(0.55*length(sgc)));
            noise_std_estim=std(sgc(round(0.2*length(sgc)):round(0.75*length(sgc))));
            th=noise_med_estim+7*noise_std_estim; %new expression threshold for GCaMP96z, should catch dim cells
        elseif strcmp(type, 'GCaMP96bf')||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf') || strcmpi(type, 'mngGECO')%updated 20170719
            gc=reshape(GCaMPbase2,[],1);
            sgc=sort(gc);
            noise_med_estim=sgc(round(0.5*length(sgc)));
            noise_std_estim=std(sgc(round(0.2*length(sgc)):round(0.65*length(sgc))));
            th=noise_med_estim+6*noise_std_estim; %IKMOD should detect dimmer GCaMPuf cells? was: th=noise_med_estim+6*noise_std_estim
        end
        %         if strcmp(type, 'GCaMP96')
        %             th=2.5*median(gc); %low F0 GCaMP variants, Hod 27Dec2013
        %         end
        mc=reshape(mCherry,[],1);
        %         th_nucleus=3*median(mc);
        smc=sort(mc);
        th_nucleus=5*(smc(round(0.15*length(mc)))); %Hod 20150723, better estim of noise level
        if strcmp(type, 'GCaMP96')
            th_nucleus=5*median(mc); %modified for low F0 GCaMPs - higher detection accuracy for mCherry
        end
        if strcmp(type, 'GCaMP96b')%Hod 20140811
            th_nucleus=4*median(mc); %modified for low F0 GCaMPs - higher detection accuracy for mCherry
        elseif strcmp(type, 'GCaMP96z')||(strcmpi(type, 'RCaMP96z')) %added by Hod 20160916, updated 20161121
            noise_med_estim=smc(round(0.6*length(smc)));
            noise_std_estim=std(smc(round(0.25*length(smc)):round(0.75*length(smc))));
            th_nucleus=noise_med_estim+7*noise_std_estim; %new expression threshold for GCaMP96z, should catch dim cells
            %adding activity th for low F0 GCaMPs, Hod 20160925
            sdF=sort(reshape(dF,[],1));
            th_act=sdF(round(0.925*length(sdF)));
            th_act=max(th_act, 50);
        elseif strcmp(type, 'GCaMP96bf') || strcmp(type, 'GCaMP96c')||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf') || strcmpi(type, 'mngGECO')%added 20170306, updated 20170719
            noise_med_estim=smc(round(0.6*length(smc)));
            noise_std_estim=std(smc(round(0.35*length(smc)):round(0.8*length(smc))));
            th_nucleus=noise_med_estim+7*noise_std_estim; % IKMOD: used to be noise_med_estim+7*noise_std_estim;
        end
        if strcmp(type, 'OGB1')||strcmp(type, 'RCaMP96')%Hod 20140811, and 20150408
            th=5*median(gc); %the median value represent the noise level in the system
        end
    else
        th = segmentation_threshold;
    end
elseif strcmp(type, 'FRET') || strcmp(type, 'GCaMP96')||strcmp(type, 'GCaMP96b')||strcmp(type, 'GCaMP96z')||(strcmpi(type, 'RCaMP96z'))
    th = 100;
    th_nucleus=300;
elseif strcmpi(type, 'RCaMP96')||strcmpi(type, 'RCaMP96b')||strcmpi(type, 'RCaMP96c')
    th = 400;
    th_nucleus=300;
else
    th = 100;
end
% if (strcmpi(type, 'P4a-20130812-GCaMP-no-mCherry'))
%     gc=reshape(GCaMPbase,[],1);
%     th=1.8*median(gc); %the median value represent the noise level in the system
% end

%% changed by Hod 13Feb2013
% v1 = [ROI_list.mCherry];
v1 = [ROI_list.GCaMP_total];
%% end of change

%% another threshold addition - Hod Dana 10May2013
disc = th;
if (strcmpi(type, 'RCaMP96b')||strcmpi(type, 'GCaMP96')||strcmp(type, 'GCaMP96b')||strcmpi(type, 'RCaMP96c'))||...
        strcmp(type, 'GCaMP96z')||(strcmpi(type, 'RCaMP96z'))||strcmp(type, 'GCaMP96bf')||strcmp(type, 'GCaMP96c')...
        ||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf') || strcmpi(type, 'mngGECO')
    disc2=th_nucleus;
end
v2=[ROI_list.mCherry];
if (strcmpi(type, 'RCaMP96b')||strcmpi(type, 'GCaMP96')||strcmp(type, 'GCaMP96b')||strcmpi(type, 'RCaMP96c'))||...
        strcmp(type, 'GCaMP96bf')||strcmp(type, 'GCaMP96c')||strcmpi(type, 'GCaMP96uf') || strcmpi(type, 'mngGECO') ||strcmpi(type, 'RCaMP96uf')  
    remove_ind = (v1<disc|v2<disc2);
	% disp(['Removed ' num2str(sum(remove_ind))])
elseif strcmpi(type, 'GCaMP96z')||(strcmpi(type, 'RCaMP96z'))  %added by Hod 20160925, updated 20161122
    v3=[ROI_list.dF];
    disc3=th_act;
    remove_ind = (v1<disc|v2<disc2|v3<disc3);
elseif strcmpi(type, 'FRET')   %added by Hod 20130913
    th=5*median(mc);
    disc = th;
    remove_ind = (v2<disc);
elseif strcmpi(type, 'RCaMP96') %Hod 20150412 remove yellowish debree that identified as ROIs when no nuclear GFP exists
    th_nucleus_low=median(mc)+1.5*std(mc); %threshld for removing greenish nuceli
    th_nucleus_up=median(mc)+5*std(mc);
    disc2=th_nucleus_low;
    disc3=th_nucleus_up;
    remove_ind = (v1<disc|(v2>disc2&v2<disc3));
else
    remove_ind = (v1<disc);
end
%% end of addition

% dark_list = ROI_list(remove_ind); %dark list was moved downward to
% include also shape based rejection Hod 20130815

dark_list_expression = ROI_list(remove_ind);
% IKMOD -- seems to remove all cells. keep commented out
% ROI_list = ROI_list(~remove_ind);


% adding shape/area threshold Hod 20130815
remove_ind=zeros(size(ROI_list));
area=[ROI_list.area];
roundness=[ROI_list.is_round];
expression_level=[ROI_list.mCherry];
expression_th=median(expression_level)+0.8*(max(expression_level)-median(expression_level)); % IKMOD was median(expression_level)+0.8*(max(expression_level)-median(expression_level))
high_expression=expression_level>expression_th;
for k=1:length(ROI_list)
    if high_expression(k)
        if roundness(k)>0.3 && area(k)>20 % IK relaxed constraints roundness(k)>0.73&&area(k)>20
            remove_ind(k)=0; % do not remove these
        else
            remove_ind(k)=1; % remove these
        end
    else
        if roundness(k)>0.8&&area(k)>25
            remove_ind(k)=0;
        else
            remove_ind(k)=1;
        end
    end
end
remove_ind=logical(remove_ind);
dark_list_shape = ROI_list(remove_ind);

% IKMOD -- doesn't seem to do much. keep uncommented
ROI_list = ROI_list(~remove_ind);

if ~isempty(ROI_list)
    %% remove ROI that has dark green signal
    
    if strcmp(type, 'FRET')
        a = [ROI_list.GCaMP_total];
        th1 = kmean1D_threshold(GCaMPbase(:),0.5); % threshold valuse was changed Hod 31Mar2013
        remove_ind = a<th1;
        %         ROI_list = ROI_list(~remove_ind); % changed by Hod 31Mar2013
        
        a = [ROI_list.dF];
        th2 = kmean1D_threshold(dF(:),0.15);% threshold valuse was changed Hod 31Mar2013
        remove_ind = a<th2;
        %         ROI_list = ROI_list(~remove_ind);% changed by Hod 31Mar2013
        
        if ~isdeployed && DEBUG
            figure;
            overlay = NAA_create_overlay(GCaMPbase, mCherry);
            subplot(2, 2, 2);
            NAA_displayROI(ROI_list, overlay);
            title('Registered Image+ROI');
            subplot(2, 2, 3);
            NAA_displayROI(ROI_list, zeros(size(overlay)));
            title('ROI');
            subplot(2, 2, 4);
            NAA_displayROI(ROI_list, dF);
            title('YFP channel dF+ROI');
            subplot(2, 2, 1);
            NAA_displayROI(ROI_list, GCaMPbase>th);
            title('Pixels above adaptive threshold+ROI');
            
			print(gcf,'-dpsc','segmentation_figure.ps')
            close all
        end
    else
        
       
        a = [ROI_list.GCaMP_total];
        b = [ROI_list.npixel];
        c = [ROI_list.dF];
        v1 = a.*b;
        v2 = c./a;
        
        
        t1 = kmean1D_threshold(v1,0.3); %threshold was changed from 0.5 by Hod 20140814
        t2 = kmean1D_threshold(v2,0.3); %threshold was changed from 0.5 by Hod 20140814
        if strcmpi(type, 'GCaMP96z')||(strcmpi(type, 'RCaMP96z'))  %added by Hod 20160925, updated 20161122
            t1 = kmean1D_threshold(v1,0.5);
            t2 = kmean1D_threshold(v2,0.5);
        end
        
        %modified by Hod 20140814 - remove limit on activity threshold from GCaMP96b
        %data
%         if ~(strcmp(type,'GCaMP96b'))
%             t2=min(t2,0.25); % try to minimize removal of active cells
%         elseif(strcmp(type,'GCaMP96z'))||(strcmpi(type, 'RCaMP96z'))
%             t2=min(t2,0.5); %sepearte cells from background, Hod 20160923
%         else
%             t2=min(t2,0.4); % try to minimize removal of active cells, Hod 20140818
%         end?
        t2=min(t2,0.5); %sepearte cells from background, Hod 20160923, updated 20170314
        
        
        if (strcmp(type,'GCaMP96bf'))||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf') || strcmpi(type, 'mngGECO')
            t2 = kmean1D_threshold(v2,0.5);
        end
        
        disc = v1*(-t2/t1)+t2;
        remove_ind = v2<disc;
        dark_list_activity = ROI_list(remove_ind);

        % IKMOD 12/25/19: this removes all cells. keep commented out
        % ROI_list = ROI_list(~remove_ind);
        
        if ~isdeployed && DEBUG
            figure; subplot(2,2,1); plot(v1,v2,'.'); axis square;
            xlabel('F'); ylabel('df/f');
            ax = gca;
            hold on;
            plot([0,t1],[t2,0]);
            plot(v1(remove_ind), v2(remove_ind), '.k');
            
            fill_ind = ([ROI_list.GCaMP_nuc]./[ROI_list.GCaMP_nucborder])>1;
            a = [ROI_list.GCaMP_total];
            b = [ROI_list.npixel];
            c = [ROI_list.dF];
            v1 = a.*b;
            v2 = c./a;
            plot(ax,v1(fill_ind), v2(fill_ind), '.r');
            
            if strcmp(type,'RCaMP96b')
                overlay = NAA_create_overlay(mCherry,GCaMPbase);
            else
                overlay = NAA_create_overlay(GCaMPbase, mCherry);
            end
            subplot(2,2,2);
            NAA_displayROI(dark_list_expression, overlay);
            title('Removed ROIs based on expression');
            subplot(2,2,3);
            NAA_displayROI(dark_list_shape, overlay);
            title('Removed ROIs based on shape');
            subplot(2,2,4);
             NAA_displayROI(ROI_list, overlay);
            title('2 channels overlay+ROIs');
            
			%% IK DEBUG -- uncomment
			% print(gcf,'-dpsc','segmentation_figure.ps')
			
			if DEBUG
				% close all
			end
        end
    end
end

