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

%% decay
decay_comp_control=[control.decay_half_med_comp];

fast_ind=[];
p_array_decay=zeros(length(mutant),1);
amp_array_decay=zeros(length(mutant),1);
g1=decay_comp_control;

for i=1:length(mutant)
    g2=mutant(i).decay_half_med_comp;
    [p,h] = ranksum(g1,g2);
    if median(g2)<median(g1)
        p_array_decay(i)=log10(p)*-1;  %mutant faster
        if p<0.01
            amp_array(i)=median(g1)/median(g2);
        end
    else
        p_array_decay(i)=log10(p);  %mutant slower
        if p<0.01
            amp_array(i)=median(g2)/median(g1);
        end
    end
end

test_array=zeros(size(p_array_decay));
test_array(p_array_decay(:)>2)=1;
test_array(p_array_decay(:)>3)=2;
test_array(p_array_decay(:)<-2)=-1;
test_array(p_array_decay(:)<-3)=-2;


figure;imagesc(test_array');
set(gca,'position',[0.1,0.5,0.8,0.4]);
set(gca,'XTick',[]);

for i=1:length(mutant)
    text(i,2,mutant(i).construct,'Rotation',90,'HorizontalAlignment','center')
end
xlswrite('test.xls',sign(p_array_decay).*10.^(-1*abs(p_array_decay)));
%%  box plot for amplitude
faster_ind=find(p_array_decay(:)<-3);
decay_array=zeros(length(faster_ind),1);
for i=1:length(faster_ind)
    decay_array(i)=median(mutant(faster_ind(i)).decay_half_med_comp);
end
[A,idx]=sort(decay_array);
faster_ind=faster_ind(idx);

ymax=2;
figure;hold on;
g1=decay_comp_control;
text(1,ymax*0.95,['(',num2str(length(g1)),')'],'HorizontalAlignment','center')
group=zeros(size(g1));
hitname={'GCaMP3'};
pval=[];
X=g1;
group=zeros(size(g1));
for i=1:length(faster_ind)
    g2=mutant(faster_ind(i)).decay_half_med_comp;
    [p,h] = ranksum(g1,g2);
    pval(i)=p;
    X=[X,g2];
    group=[group,ones(size(g2))*i];
    hitname{end+1}=mutant(faster_ind(i)).construct;
end
boxplot(X,group,'symbol','','labels',hitname,'plotstyle','compact');
ylim([0,ymax]);

for i=1:length(faster_ind)
    text(i+1,ymax*0.95,['(',num2str(mutant(faster_ind(i)).nreplicate),')'],'HorizontalAlignment','center')
    
end

