date='20110627';
mutant=NAA_pile_mutants(date);
control=NAA_pile_mutants('_10dot1_');
construct={mutant.construct};
%%  V105R analysis
without={'10dot354','10dot358','10dot356','10dot360'};
with={'10dot352','10dot357','10dot355','10dot359'};
mutation='V105R';

%%  R392G analysis
without={'10dot359','10dot360','10dot355','10dot366','10dot362','10dot356'};
with={'10dot357','10dot358','10dot352','10dot365','10dot361','10dot354'};
mutation='R392G';

%%  T381R analysis
without={'10dot366','10dot364','10dot365'};
with={'10dot359','10dot355','10dot357'};
mutation='T381R';

%%  LP analysis
without={'10dot366','10dot358','10dot357','10dot359','10dot360'};
with={'10dot364','10dot354','10dot352','10dot355','10dot356'};
mutation='LP';

%%  A317E analysis
without={'10dot352','10dot355'};
with={'10dot361','10dot362'};
mutation='A317E';
%% N399P analysis
without={'10dot364','10dot355','10dot352'};
with={'10dot353','10dot363','10dot367'};
mutation='N399P';
%%
ind_without=[];
ind_with=[];
for i=1:length(without)
    ind_without(i)=find(strcmp(construct,without{i}));
    ind_with(i)=find(strcmp(construct,with{i}));
end

color={'b','r','g','k','c','m'};
%%  response amplitude
figure('position',[100,100,600,480]);
stim_ind=[3,5,9];
title_text={'3FP','10FP','160FP'};
for k=1:3
    subplot(2,3,k);hold on;
    for i=1:length(without)
        g1=median(mutant(ind_without(i)).df_fpeak_med_comp(stim_ind(k),:));
        g2=median(mutant(ind_with(i)).df_fpeak_med_comp(stim_ind(k),:));
        plot([1,2],[g1,g2],'o-','color',color{i});  
        
    end
    xlim([0.5,2.5]);
    yy=get(gca,'ylim');
    ylim([0,yy(2)]);
    title(title_text{k});
    set(gca,'XTick',[1,2]);
    set(gca,'XTickLabel',{['-',mutation],['+',mutation]})
end


%%  response kinetics
subplot(2,3,4);hold on;

for i=1:length(without)
    g1=median(mutant(ind_without(i)).decay_half_med_comp);
    g2=median(mutant(ind_with(i)).decay_half_med_comp);
    plot([1,2],[g1,g2],'o-','color',color{i});    
end
xlim([0.5,2.5]);
yy=get(gca,'ylim');
ylim([0,yy(2)]);
title('half decay');
set(gca,'XTick',[1,2]);
set(gca,'XTickLabel',{['-',mutation],['+',mutation]})
%%
subplot(2,3,5);hold on;
for i=1:length(without)    
    g1=median((mutant(ind_without(i)).f0)./(mutant(ind_without(i)).mCherry));
    g2=median((mutant(ind_with(i)).f0)./(mutant(ind_with(i)).mCherry));
    plot([1,2],[g1,g2],'o-','color',color{i}); 
end
xlim([0.5,2.5]);
yy=get(gca,'ylim');
ylim([0,yy(2)]);
title('Brightness');
set(gca,'XTick',[1,2]);
set(gca,'XTickLabel',{['-',mutation],['+',mutation]})

legend(without,'location','EastOutside');
