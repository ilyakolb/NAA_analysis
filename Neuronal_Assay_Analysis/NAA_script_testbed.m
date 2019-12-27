%% NAA_script_testbed
% Ilya Kolb
% testbed for NAA_script to ease implementing wavesurfer etc'

% for testing, using /Volumes/genie/GENIE_Pipeline/GECI Imaging Data/20180619_GCaMP96uf

segment_file_ID = 4;
nominal_pulse = [1,3,10,160];
segmentation_threshold = 0;
type = 'GCaMP96uf';
plate_folder_path = '/Volumes/genie/GENIE_Pipeline/GECI_NAA_code_20170728/Neuronal_Assay_Analysis/testbed/';

cd(plate_folder_path)
% NAA_organize_files(plate_folder_path);
NAA_script_ver4_IK(segment_file_ID, nominal_pulse, type, segmentation_threshold);