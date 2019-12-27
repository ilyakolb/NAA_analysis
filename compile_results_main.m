%% RUNNING GCAMP ANALYSIS ON CLUSTER -- PARALLEL EXECUTION
% RUN THIS ON PC, NOT LINUX DUE TO INCOMPATIBILITY WITH EXCEL WRITING
% 10/9/19

%% TODO
% compatibility with NAA Curation

clc
GECI_imaging_dir = 'Z:\GECIScreenData\GECI_Imaging_Data';

compile_results(fullfile(GECI_imaging_dir, '20191112_GCaMP96uf_analyzed'),'mngGECO','0')
% compile_results(fullfile(GECI_imaging_dir, '20180515_GCaMP96uf_analyzed'),'GCaMP96uf','0')
% compile_results(fullfile(GECI_imaging_dir, '20180508_GCaMP96uf_analyzed'),'GCaMP96uf','0')
% compile_results(fullfile(GECI_imaging_dir, '20170801_GCaMP96uf_analyzed'),'GCaMP96uf','0')
% compile_results(fullfile(GECI_imaging_dir, '20170725_GCaMP96uf_NIRGECO96_analyzed'),'GCaMP96uf','0')
% compile_results(fullfile(GECI_imaging_dir, '20170711_GCaMP96uf_analyzed'),'GCaMP96uf','0')

% TODO
%  compile_results(fullfile(GECI_imaging_dir, '20170717_GCaMP96uf_analyzed'),'GCaMP96uf','0')