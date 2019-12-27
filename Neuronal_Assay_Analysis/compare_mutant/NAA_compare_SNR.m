
saveflag=1;
% string={'20101213*_10dot1_','20101220*_10dot1_','20110613*_10dot1_','_10dot29_','_10dot3_'}%,'_10dot30_','_10dot31_','_10dot244_','_10dot250_','_10dot69_','20110815*_fluo4_','20110815*_ogb1'};
string={'20101213*_10dot1_','20101220*_10dot1_','20110613*_10dot1_','_10dot29_','_10dot63_','_10dot354'};
mutant=NAA_pile_mutants(string);
%%
figure;
nAP=[1,2,3,5,10,20,40,80,160];hold on;
color=['r','g','b','k','c','m','r','k','g','b'];
name={};
for i=1:length(mutant)
     SNR=median(mutant(i).df_fpeak_med./mutant(i).df_fnoise,2);
     SNR_sd=std(mutant(i).df_fpeak_med./mutant(i).df_fnoise,[],2);
     SNR_sem=SNR_sd/sqrt(mutant(i).nreplicate);
     h=errorbar(nAP,SNR,SNR_sem,'.-','color',color(i));
     ERRORBAR_TICK(h,0.2,'UNITS')
end
legend(mutant.construct);

%%
figure;
nAP=[1,2,3,5,10,20,40,80,160];hold on;
color=['r','g','b','k','c','m','r','k','g','b'];
name={};
for i=1:length(mutant)
     dff=median(mutant(i).df_fpeak_med,2);
     dff_sd=std(mutant(i).df_fpeak_med,[],2);
     dff_sem=dff_sd/sqrt(mutant(i).nreplicate);
     h=errorbar(nAP,dff,dff_sem,'.-','color',color(i));
     ERRORBAR_TICK(h,0.2,'UNITS')
end
legend(mutant.construct);

%% output excel file

file='SNR_newmutants.xlsx';
file = fullfile(pwd, file);
hexcel=actxserver('excel.application');
wb=hexcel.WorkBooks.Add();


%% construct name: column A
column='A';
ran = hexcel.Activesheet.get('Range',[column,'1']); 
ran.value='Name';
for i=1:length(mutant)
    ran = hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    ran.value=mutant(i).construct;
end
%% n replicate: column B
column='B';
ran = hexcel.Activesheet.get('Range',[column,'1']); 
ran.value='replicate';
for i=1:length(mutant)
    ran = hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    ran.value=mutant(i).nreplicate;
end

%% date last assay: column C
column='C';
ran = hexcel.Activesheet.get('Range',[column,'1']); 
ran.value='last assay date';
for i=1:length(mutant)
    ran = hexcel.Activesheet.get('Range',[column,num2str(i+1)]); 
    num=datenum(mutant(i).date,'yyyymmdd');
    [num,ind]=sort(num,'descend');
    ran.value=mutant(i).date(ind);
end

%% response amplitude:
column={'D','E','F','G','H','I','J','K','L'};
title_text={'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'};
for i=1:length(column)
    ran=hexcel.Activesheet.get('Range',[column{i},'1']);
    ran.value=title_text{i};
    
    for k=1:length(mutant)
        ran = hexcel.Activesheet.get('Range',[column{i},num2str(k+1)]);
        
        ran.value=median(mutant(k).df_fpeak_med(i,:));
%         ran.font.Color=get_color(p_array(k,i),amp_array(k,i));
    end
end

%% SNR
column={'N','O','P','Q','R','S','T','U','V'};
title_text={'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'};
for i=1:length(column)
    ran=hexcel.Activesheet.get('Range',[column{i},'1']);
    ran.value=title_text{i};
    
    for k=1:length(mutant)
        ran = hexcel.Activesheet.get('Range',[column{i},num2str(k+1)]);        
        SNR=median(mutant(k).df_fpeak_med./mutant(k).df_fnoise,2);
        ran.value=SNR(i);
%         ran.font.Color=get_color(p_array(k,i),amp_array(k,i));
    end
end

%% SNR SD
column={'X','Y','Z','AA','AB','AC','AD','AE','AF'};
title_text={'1FP','2FP','3FP','5FP','10FP','20FP','40FP','80FP','160FP'};
for i=1:length(column)
    ran=hexcel.Activesheet.get('Range',[column{i},'1']);
    ran.value=title_text{i};
    
    for k=1:length(mutant)
        ran = hexcel.Activesheet.get('Range',[column{i},num2str(k+1)]);  
        SD=std(mutant(k).df_fpeak_med./mutant(k).df_fnoise,[],2);
        ran.value=SD(i);
%         ran.font.Color=get_color(p_array(k,i),amp_array(k,i));
    end
end
%%

wb.SaveAs(file); 
wb.Close;
hexcel.Quit;
hexcel.delete;