files=dir('*.mat');
for i=1:length(files)
    load(files(i).name,'fmean','bg','ephus_info');
    [para_array,summary]=NAA_MeasurePara(fmean,bg,ephus_info);
    save(files(i).name,'summary','-append');
end
    