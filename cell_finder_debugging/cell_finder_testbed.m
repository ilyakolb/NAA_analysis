%% cell finder testbed

clearvars
%load('/Volumes/genie/GENIE_Pipeline/GECI_NAA_code/cell_finder/B05.mat')
%load('/Volumes/genie/GENIE_Pipeline/GECI_NAA_code/cell_finder/B07.mat')
load('C09.mat')

% cell_list = NAA_segment_IK(GCaMPbase - bg, mCherry - bg_cherry, dF, type, segmentation_threshold,GCaMPbase2);
tic
cell_list = NAA_segment_IK(GCaMPbase - bg, mCherry - bg_cherry, dF, type, segmentation_threshold,imresize(imRef,4));
toc