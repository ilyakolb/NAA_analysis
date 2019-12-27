function [mutant_norm_brightness,control_norm_brightness]=NAA_calculate_norm_brightness(mutant,control)

date=mutant.date;
date_unique=unique(date);
f0_mutant=[mutant.f0];
mCherry_mutant=[mutant.mCherry];
norm_mutant=f0_mutant./mCherry_mutant;

date_control=control.date;
f0_cont=[control.f0];
mCherry_cont=[control.mCherry];
norm_cont=f0_cont./mCherry_cont;

mutant_norm_brightness=[];
control_norm_brightness=[];
for i=1:length(date_unique)
    ind1=strcmp(date_control,date_unique{i});        
    ind2=strcmp(date,date_unique{i});
    if ~isempty(ind1)
        g1=norm_cont(ind1);
        g2=norm_mutant(ind2);
        
        mutant_norm_brightness=[mutant_norm_brightness,g2/median(g1)];
        control_norm_brightness=[control_norm_brightness,g1/median(g1)];
    end
end
        
