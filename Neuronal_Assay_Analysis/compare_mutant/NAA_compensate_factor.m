function df_fpeak_med_comp=NAA_compensate_factor(nsegment,df_fpeak_med,coef)

%  df_fpeak_med:   9x nrepeat
%  nsegment    :   1x nrepeat


center=40;
% ind=3;
df_fpeak_med_comp=zeros(size(df_fpeak_med));

for ind=1:size(df_fpeak_med,1)
    factor=(40*coef(1,ind)+coef(2,ind))./(nsegment*coef(1,ind)+coef(2,ind));
    factor(factor>2.5)=2.5;
    factor(factor<0.4)=0.4;
    df_fpeak_med_comp(ind,:)=df_fpeak_med(ind,:).*factor;
end

    