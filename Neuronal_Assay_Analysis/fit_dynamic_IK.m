function [rise_half,decay_half,time_to_peak,peak_value]=fit_dynamic_IK(trace,t_im,t_first_stim,disp_flag, bleachCorrect)
% calc params from trace
% modified to operate along single trace
% modified to take in bleachCorrect option (1 to do bleach correction)

% ss=size(traces);
% traces=reshape(traces,ss(1),[]);

% ntraces=size(traces,2);

stim_ind=interp1(t_im,1:length(t_im),t_first_stim,'nearest');

% IK added bleach correction 1/31/21
if bleachCorrect
    trace = bleachCorr( t_im, trace, [10:150 1000:1399]);
end

win=[1,3,1]/5;
trace=filtfilt(win,1,trace);
   if(disp_flag)
         figure;plot(trace);hold on;
            plot(trace,'r');
   end
[peak_value,maxind]=max(trace(stim_ind:end));
maxind=maxind+stim_ind-1;
time_to_peak=t_im(maxind)-t_first_stim;

half_ind=find(trace(stim_ind:maxind)>peak_value/2);
    
if ~isempty(half_ind)
    half_ind=half_ind(1)+stim_ind-1;
    rise_half=interp1([trace(half_ind-1),trace(half_ind)+eps],t_im((half_ind-1):half_ind),peak_value/2);
    rise_half=rise_half-t_first_stim;
else
    rise_half=0;
end
    
% IK added further smoothing to find half decay index
trace_smoothed = smooth(trace,10);
peak_value_smoothed = trace_smoothed(maxind);
half_ind=find(trace_smoothed(maxind:end)<peak_value_smoothed/2);
if ~isempty(half_ind)
    half_ind=half_ind(1)+maxind-1;

    decay_half=interp1(trace_smoothed((half_ind-1):half_ind),t_im((half_ind-1):half_ind),peak_value_smoothed/2);
    decay_half=decay_half-t_im(maxind);
else
    decay_half=0;
end

