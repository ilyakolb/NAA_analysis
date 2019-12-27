date='20110627';
mutant=NAA_pile_mutants(date);

norm_f0=zeros(size(mutant),1);
for i=1:length(mutant)
    mCherry=mutant(i).mCherry;
    f0=mutant(i).f0;
    norm_f0(i)=median(f0./mCherry);
end
norm_f0=norm_f0/norm_f0(1);

%%
handle=figure('position',[100,100,1200,800]);
ax2=axes('position',[0.1,0.9,0.8,0.06]);

imagesc(log2(norm_f0));
set(gca,'clim',[-2,2]);
set(gca,'YTick',1);
set(gca,'YTickLabel',{'norm_f0'});
set(gca,'XTick',[]);
for i=1:length(mutant)
    text(i,10.5,mutant(i).construct,'Rotation',90,'HorizontalAlignment','center')
end
colorbar;