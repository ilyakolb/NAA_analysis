function [rise_half,decay_half,time_to_peak,peak_value]=fit_dynamic(traces,t_im,t_first_stim,disp_flag)


ss=size(traces);
traces=reshape(traces,ss(1),[]);

ntraces=size(traces,2);
len=size(traces,1);

stim_ind=interp1(t_im,1:length(t_im),t_first_stim,'nearest');

% IK added bleach correction 1/31/21
traces(:,1) = bleachCorr(t_im,traces(:,1));
for i=1:ntraces

    trace=traces(:,i);

%    trace=[trace(1:stim_ind);sgolayfilt(double(trace(stim_ind:end)),2,7)];
    win=[1,3,1]/5;
    trace=filtfilt(win,1,trace);
        if(disp_flag)
            figure;plot(traces(:,i));hold on;
            plot(trace,'r');
        end
    [peak_value,maxind]=max(trace(stim_ind:end));
    maxind=maxind+stim_ind-1;
    time_to_peak(i)=t_im(maxind)-t_first_stim;
    
    
    half_ind=find(trace(stim_ind:maxind)>peak_value/2);
    
    if ~isempty(half_ind)
        half_ind=half_ind(1)+stim_ind-1;
        rise_half(i)=interp1([trace(half_ind-1),trace(half_ind)+eps],t_im((half_ind-1):half_ind),peak_value/2);
        rise_half(i)=rise_half(i)-t_first_stim;
    else
        rise_half(i)=0;
    end
    
    % IK added further smoothing to find half decay index
    half_ind=find(smooth(trace(maxind:end),10)<peak_value/2);
    if ~isempty(half_ind) 
        half_ind=half_ind(1)+maxind-1;
        if trace(half_ind-1) == half_ind
            decay_half(i) = t_im(half_ind) - t_im(maxind);
        else
            decay_half(i)=interp1(trace((half_ind-1):half_ind),t_im((half_ind-1):half_ind),peak_value/2);
            decay_half(i)=decay_half(i)-t_im(maxind);
        end
    else
        decay_half(i)=0;
    end
end

ss1=ss(2:end);
if length(ss1)<2
    ss1=[ss1,1];
end

rise_half=reshape(rise_half,ss1);
decay_half=reshape(decay_half,ss1);
time_to_peak=reshape(time_to_peak,ss1);
peak_value=reshape(peak_value,ss1);