function [para_array,summary,fmean_bgremoved]=NAA_MeasurePara(fmean,bg,ephus_info,isneg_resp)

if ~exist('isneg_resp')
    isneg_resp=0;
end
nFiles=size(fmean,2);
nROI=size(fmean,3);
nTime=size(fmean,1);
para=struct('f0',0,'df_fpeak',0,'tpeak',0,'df_f',zeros(nTime,1),'rise_half',0,'decay_half',0);
para_array=repmat(para,[nFiles,nROI]);

if length(bg)==1
    fmean=fmean-bg;
else
    for i=1:nFiles
        fmean(:,i,:)=fmean(:,i,:)-bg(i);
    end
end
fmean_bgremoved=fmean;
for i=1:nFiles
    if length(ephus_info(i).ImageTime)<(nTime+1)
        ephus_info(i)=ephus_info(i+1);
    end
    t_im=ephus_info(i).ImageTime(2:nTime);
    t_first_stim=ephus_info(i).IPulseTime(1);
%display(t_im);
%display(t_first_stim);
    stim_ind=interp1(t_im,1:length(t_im),t_first_stim,'nearest');
    %fprintf('\nnROI is %f',nROI);
    for j=1:nROI
        %fprintf('\nstim_ind is %f',stim_ind);
        f=squeeze(fmean(:,i,j));
        %display(f);
        

        f0=mean(f((stim_ind-10):(stim_ind-1)));        
        df_f=(f-f0)/f0;
        
        
        para_array(i,j).f0=f0;
        para_array(i,j).df_f=df_f;

        if isneg_resp
            [rise_half,decay_half,time_to_peak,peak_value]=fit_dynamic(-df_f,ephus_info(i).ImageTime(2:(nTime+1)),ephus_info(i).IPulseTime(1),0);
            peak_value=-peak_value;
        else
            % [rise_half,decay_half,time_to_peak,peak_value]=fit_dynamic(df_f,ephus_info(i).ImageTime(2:(nTime+1)),ephus_info(i).IPulseTime(1),0);
            % do bleach correction on 1AP data only
            bleachCorrect = (i == 1);
            [rise_half,decay_half,time_to_peak,peak_value]=fit_dynamic_IK(df_f,ephus_info(i).ImageTime(2:(nTime+1)),ephus_info(i).IPulseTime(1),0, bleachCorrect);
        end
        para_array(i,j).rise_half=rise_half;
        para_array(i,j).decay_half=decay_half;
        para_array(i,j).df_fpeak=peak_value;
        para_array(i,j).tpeak=time_to_peak;
    end    
end
        
df_fmean=mean(reshape([para_array.df_f],[nTime,nFiles,nROI]),3);

%df_fmean_filt = sgolayfilt(double(df_fmean(:,:,1)),2,13);

df_fmed=median(reshape([para_array.df_f],[nTime,nFiles,nROI]),3);

% df_fmed_filt=sgolayfilt(double(df_fmed(:,:,1)),2,13);

summary.f0=mean(reshape([para_array.f0],[nFiles,nROI]),2);

%% mean statistics
rise_half=zeros(nFiles,1);
decay_half=zeros(nFiles,1);
time_to_peak=zeros(nFiles,1);
peak_value=zeros(nFiles,1);
for i=1:nFiles
    if isneg_resp
        [rise_half(i),decay_half(i),time_to_peak(i),peak_value(i)]=fit_dynamic(-df_fmean(:,i),ephus_info(i).ImageTime(2:(nTime+1)),ephus_info(i).IPulseTime(1),0);
        peak_value(i)=-peak_value(i);
    else
        bleachCorrect = (i == 1) || (i == 2);
        [rise_half(i),decay_half(i),time_to_peak(i),peak_value(i)]=fit_dynamic_IK(df_fmean(:,i),ephus_info(i).ImageTime(2:(nTime+1)),ephus_info(i).IPulseTime(1),0, bleachCorrect);
    end    
end
% [df_fpeak,tpeak]=max(df_fmean_filt(33:175,:));
summary.df_fpeak=peak_value;
summary.timetopeak=time_to_peak;
% summary.df_fmean=df_fmean;
summary.rise_half=rise_half;
summary.decay_half=decay_half;

%% median statistics
for i=1:nFiles
    if isneg_resp
        [rise_half(i),decay_half(i),time_to_peak(i),peak_value(i)]=fit_dynamic(-df_fmed(:,i),ephus_info(i).ImageTime(2:(nTime+1)),ephus_info(i).IPulseTime(1),0);
        peak_value(i)=-peak_value(i);
    else
        bleachCorrect = (i == 1) || (i == 2);
        [rise_half(i),decay_half(i),time_to_peak(i),peak_value(i)]=fit_dynamic_IK(df_fmed(:,i),ephus_info(i).ImageTime(2:(nTime+1)),ephus_info(i).IPulseTime(1),0, bleachCorrect);
    end      
end
summary.df_fpeak_med=peak_value;
summary.timetopeak_med=time_to_peak;
% summary.df_fmed=df_fmed;
summary.rise_half_med=rise_half;
summary.decay_half_med=decay_half;
