file=dir('*.mat');
permutation=[2,3,4,5,6,7,8,9,1];
for i=1:length(file)
    S=load(file(i).name);
    S.para_array=S.para_array(permutation,:);
    S.df_fmap=S.df_fmap(:,:,permutation);
    S.fmean=S.fmean(:,permutation,:);
    S.summary.f0=S.summary.f0(permutation);
    S.summary.df_fpeak=S.summary.df_fpeak(permutation);
    S.summary.timetopeak=S.summary.timetopeak(permutation);
    S.summary.rise_half=S.summary.rise_half(permutation);
    S.summary.decay_half=S.summary.decay_half(permutation);
    S.summary.df_fpeak_med=S.summary.df_fpeak_med(permutation);
    S.summary.timetopeak_med=S.summary.timetopeak_med(permutation);
    S.summary.rise_half_med=S.summary.rise_half_med(permutation);
    S.summary.decay_half_med=S.summary.decay_half_med(permutation);
    save(file(i).name,'-struct','S');
end
    