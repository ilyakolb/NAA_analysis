%% cell finder testbed

clearvars

load('Z:\ilya\code\GECI_NAA_code_20191003\test\segment_input.mat')

% cell_list = NAA_segment_IK(GCaMPbase - bg, mCherry - bg_cherry, dF, type, segmentation_threshold,GCaMPbase2);

cell_list = NAA_segment_ilastik(GCaMPbase2, mCherry - bg_cherry, dF, h5data);
