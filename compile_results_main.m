%% RUNNING GCAMP ANALYSIS ON CLUSTER -- PARALLEL EXECUTION
% RUN THIS ON PC, NOT LINUX DUE TO INCOMPATIBILITY WITH EXCEL WRITING
% 10/9/19

clc
if isunix
    cd /groups/genie/genie/ilya/code/GECI_NAA_code
    GECI_imaging_dir = '/groups/genie/genie/GECIScreenData/GECI_Imaging_Data';
    addpath POI
else
    GECI_imaging_dir = 'Z:\GECIScreenData\GECI_Imaging_Data';
end

% all plates ever 

compile_results(fullfile(GECI_imaging_dir, '20191125_XCaMP_analyzed'),'GCaMP96uf','0')

compile_results(fullfile(GECI_imaging_dir, '20190910_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20190904_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20190903_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20190827_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20191209_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20191216_GCaMP96uf_analyzed'),'GCaMP96uf','0')

compile_results(fullfile(GECI_imaging_dir, '20180828_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20180725_embryonic_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20180515_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20180508_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20170801_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20170725_GCaMP96uf_NIRGECO96_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20170717_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20170711_GCaMP96uf_analyzed'),'GCaMP96uf','0')
compile_results(fullfile(GECI_imaging_dir, '20180619_GCaMP96uf_analyzed'),'GCaMP96uf','0')

% one-off
% compile_results(fullfile(GECI_imaging_dir, '20191216_GCaMP96uf_analyzed'),'GCaMP96uf','0')

