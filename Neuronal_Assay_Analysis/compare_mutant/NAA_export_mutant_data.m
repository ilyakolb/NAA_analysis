function NAA_export_mutant_data(mutant,control)
%% sort mutant according to GECI numbering
compensation=1;

% construct_num=zeros(length(mutant),1);
% for i=1:length(mutant)
%     temp=mutant(i).construct;
%     construct_num(i)=str2num(temp(6:end));
% end
% [n,ix]=sort(construct_num);
% mutant=mutant(ix);
construct={mutant.construct};
%% calculate amplitudes and p values
p_array=zeros(length(mutant),9);
amp_array=zeros(length(mutant),9);
decay_amp=zeros(length(mutant),1);
decay_p=zeros(length(mutant),1);
% title_text={'','1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP
% ','','decay_10FP','','nrep'};
for i=1:length(mutant)
    for stim_ind=1:9
        if compensation==1
            g1=control.df_fpeak_med_comp(stim_ind,:);
            g2=mutant(i).df_fpeak_med_comp(stim_ind,:);
        else
            g1=control.df_fpeak_med(stim_ind,:);
            g2=mutant(i).df_fpeak_med(stim_ind,:);
        end
        [p,h] = ranksum(g1,g2);
        p_array(i,stim_ind)=p;        
        amp_array(i,stim_ind)=median(g2)/median(g1);
    end
    
    if compensation==1
        g1=[control.decay_half_med_comp];
        g2=[mutant(i).decay_half_med_comp];
    else
        g1=[control.decay_half_med(5,:)];
        g2=[mutant(i).decay_half_med(5,:)];
    end
    [p,h]=ranksum(g1,g2);
    decay_p(i)=p;
    decay_amp(i)=median(g2)/median(g1);        
end


%% output excel file

file='test.xls';
file = fullfile(pwd, file);
%hexcel=actxserver('excel.application');
%wb=hexcel.WorkBooks.Add();

data_all = cell(length(mutant) + 1, 25);
%data_all{1, :} = {'construct', 'replicate_number', 'last_assay_date', '1_fp', '2_fp', '3_fp', '5_fp', '10_fp', '20_fp', '40_fp', '80_fp', '160_fp', 'score', 'decay_10_fp', 'norm_f0', '1_fp_p', '2_fp_p', '3_fp_p', '5_fp_p', '10_fp_p', '20_fp_p', '40_fp_p', '80_fp_p', '160_fp_p', 'decay_10_fp_p', 'norm_f0_p'};

%% construct name: column A
%column='A';
%ran = hexcel.Activesheet.get('Range',[column,'1']); 
%ran.value='Name';
for i=1:length(mutant)
    %ran = hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    %ran.value=mutant(i).construct;
    data_all{i + 1, 1} = mutant(i).construct;
end
%% n replicate: column B
%column='B';
%ran = hexcel.Activesheet.get('Range',[column,'1']); 
%ran.value='replicate';
for i=1:length(mutant)
    %ran = hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    %ran.value=mutant(i).nreplicate;
    data_all{i + 1, 2} = mutant(i).nreplicate;
end

%% date last assay: column C
%column='C';
%ran = hexcel.Activesheet.get('Range',[column,'1']); 
%ran.value='last assay date';
for i=1:length(mutant)
    %ran = hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    num=datenum(mutant(i).date,'yyyymmdd');
    [num,ind]=sort(num,'descend');
    %ran.value=mutant(i).date(ind);
    data_all{i + 1, 3} = mutant(i).date(ind(1));
end

%% response amplitude:
column={'D','E','F','G','H','I','J','K','L'};
%title_text={'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'};
for i=1:length(column)
    %ran=hexcel.Activesheet.get('Range',[column{i},'1']);
    %ran.value=title_text{i};
    
    for k=1:length(mutant)
        %ran = hexcel.Activesheet.get('Range',[column{i},num2str(k+1)]);
        %ran.value=round(amp_array(k,i)*100)/100;
        %ran.font.Color=get_color(p_array(k,i),amp_array(k,i));
        data_all{k + 1, i + 3} = round(amp_array(k,i)*100)/100;
    end
end

%% significance score
%column='M';
%ran = hexcel.Activesheet.get('Range',[column,'1']); 
%ran.value='Score';
for i=1:length(mutant)
    %ran = hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    
    value=p_array(i,:);
    amp=amp_array(i,:);
    score=0;
    for k=1:length(value)
        if amp(k)>1
            if value(k)<0.001
                score=score+1.5;
            elseif value(k)<0.01
                score=score+1.2;
            elseif value(k)<0.05
                score=score+1;
            end
        end
    end
    %ran.value=score;
    data_all{i + 1, 13} = score;
end

%%  decay
%column='O';
%ran = hexcel.Activesheet.get('Range',[column,'1']); 
%ran.value='Decay (10FP)';
for i=1:length(mutant)
    %ran=hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    %ran.value=round(decay_amp(i)*100)/100;
    %ran.font.Color=get_color(decay_p(i),decay_amp(i));
    data_all{i + 1, 14} = round(decay_amp(i)*100)/100;
end

%% brightness
%column='Q';
%ran = hexcel.Activesheet.get('Range',[column,'1']); 
%ran.value='norm F0';
for i=1:length(mutant)
    %ran=hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    [mutant_norm_brightness,control_norm_brightness]=NAA_calculate_norm_brightness(mutant(i),control);
    
    %[p] = ranksum(mutant_norm_brightness,control_norm_brightness);
    amp=median(mutant_norm_brightness)/median(control_norm_brightness);
    
    %ran.value=amp;
    %ran.font.Color=get_color(p,amp);
    data_all{i + 1, 15} = amp;
end

%% response p value:
column={'S','T','U','V','W','X','Y','Z','AA'};
%title_text={'1FP(p)','2FP(p)','3FP(p)','5FP(p)','10FP(p)','20FP(p)','40FP(p)','80FP(p)','160FP(p)'};
for i=1:length(column)
    %ran=hexcel.Activesheet.get('Range',[column{i},'1']);
    %ran.value=title_text{i};
    
    for k=1:length(mutant)
        %ran = hexcel.Activesheet.get('Range',[column{i},num2str(k+1)]);
        %ran.value=p_array(k,i);
        %ran.font.Color=get_color(p_array(k,i),amp_array(k,i));
        data_all{k + 1, i + 15} = p_array(k,i);
    end
end

%%  decay p value:
%column='AC';
%ran = hexcel.Activesheet.get('Range',[column,'1']); 
%ran.value='Decay (10FP)(p)';
for i=1:length(mutant)
    %ran=hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    %ran.value=decay_p(i);
    %ran.font.Color=get_color(decay_p(i),decay_amp(i));
    data_all{i + 1, 25} = decay_p(i);
end

%% brightness p value
%column='AE';
%ran = hexcel.Activesheet.get('Range',[column,'1']); 
%ran.value='norm F0(p)';
for i=1:length(mutant)
    %ran=hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    [mutant_norm_brightness,control_norm_brightness]=NAA_calculate_norm_brightness(mutant(i),control);
    
    [p] = ranksum(mutant_norm_brightness,control_norm_brightness);
    %amp=median(mutant_norm_brightness)/median(control_norm_brightness);
    
    %ran.value=p;
    %ran.font.Color=get_color(p,amp);
    data_all{i + 1, 26} = p;
end


%%
% wb.SaveAs(file); 
% wb.Close;
% hexcel.Quit;
% hexcel.delete;

% for i=1:length(mutant)
%     ran=
% ran = hexcel.Activesheet.get('Range',range); 
% ran.value = data; 
% ran.font.Color=hex2dec('FF0000'); %Blue
end

function Color=get_color(pvalue,amplitude)
if pvalue<0.001
    if amplitude>1
        Color=hex2dec('0000FF');  %red
    else
        Color=hex2dec('FF0000');  %blue
    end
elseif pvalue<0.01
    if amplitude>1
        Color=hex2dec('0060FF');
    else
        Color=hex2dec('FF6000');
    end
elseif pvalue<0.05
    if amplitude>1
        Color=hex2dec('00C0FF');
    else
        Color=hex2dec('FFC000');
    end
else 
    Color=hex2dec('000000');
end

end


