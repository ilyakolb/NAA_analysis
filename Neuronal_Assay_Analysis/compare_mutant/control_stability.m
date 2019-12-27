control=NAA_pile_mutants('_10dot1_');
%%
g1=control.df_fpeak_med_comp(5,:);
g2=control.df_fpeak_med_comp(9,:);
g3=control.decay_half_med_comp;
figure;
plot(g1,'or');
hold on;
plot(g2,'o');
xlim([0,control.nreplicate]);
ylim([0,8]);
%%
% subplot(2,1,2);
plot(g3,'o');
xlim([0,control.nreplicate]);
ylim([0,1]);