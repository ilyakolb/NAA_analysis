function df_fpeak_med_comp=NAA_compensate(nsegment,df_fpeak_med,coef)

center=40;
% ind=3;
df_fpeak_med_comp=zeros(size(df_fpeak_med));

for ind=1:size(df_fpeak_med,1)
    diff=(nsegment-40)*coef(1,ind);
    df_fpeak_med_comp(ind,:)=df_fpeak_med(ind,:)-diff;
end

    