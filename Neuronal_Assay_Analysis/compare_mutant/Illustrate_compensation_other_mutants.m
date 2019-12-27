[mutant_data]=NAA_pile_mutants;
%%
construct={mutant_data.construct};
ctr_ind=strcmp(construct,'10dot1');
control=mutant_data(ctr_ind);
mutant=mutant_data(~ctr_ind);
num=[];
for i=1:length(mutant)
    temp=mutant(i).construct;
    num(i)=str2num(temp(6:end));
end
[n,ix]=sort(num);
mutant=mutant(ix);

%%
corr_mutant=zeros(size(mutant));
nseg_std_mutant=zeros(size(mutant));
nwell_mutant=zeros(size(mutant));

for i=1:length(mutant)
    df_f=mutant(i).df_fpeak_med(5,:);
    nsegment=mutant(i).nSegment;
    
    r=corrcoef(df_f,nsegment);
    corr_mutant(i)=r(2,1);
    nseg_std_mutant(i)=std(nsegment);
    nwell_mutant(i)=mutant(i).nreplicate;
end

figure
subplot(1,2,1);hist(corr_mutant)

th=median(nseg_std_mutant);
subplot(1,2,2);hist(corr_mutant(nseg_std_mutant>th));


%%
mutant_idx=24;
figure;
subplot(1,3,1);
hold on;
plot(control.nSegment,control.df_fpeak_med(5,:),'.')
plot(mutant(mutant_idx).nSegment,mutant(mutant_idx).df_fpeak_med(5,:),'r.')
xlim([0,100]);ylim([0,2]);
subplot(1,3,2);
hold on;
plot(control.nSegment,control.df_fpeak_med_comp(5,:),'.')
xlim([0,100]);ylim([0,2]);
plot(mutant(mutant_idx).nSegment,mutant(mutant_idx).df_fpeak_med_comp(5,:),'r.')

subplot(1,3,3);
group=[ones(1,control.nreplicate),ones(1,mutant(mutant_idx).nreplicate)*2];
boxplot([control.df_fpeak_med_comp(5,:),mutant(mutant_idx).df_fpeak_med_comp(5,:)],group,'symbol','');