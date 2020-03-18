function [h5data, status] = run_ilastik(fileName)
%RUN_ILASTIK: runs ilastik segmentation engine. Called by NAA_script_ver4_IK
% INPUTS:
%        fileName: AutoFocusRef file (just filename)
% OUTPUTS:
%         h5data: 1 x 512 x 512 ilastik segmentation output
%         status: system(  ) output. 0 if success

% FOR DEBUGGING: launch this from the 96WellXX-AXX/AutoFocus folder
% TODO: pass ilastik_props in instead of hardcoding

if ispc % running on my PC
    ilastik_props.ilastik_location= 'C:\Program Files\ilastik-1.3.3post1\run-ilastik.bat';
    ilastik_props.proj_location = 'Z:\ilya\code\GECI_NAA_code\ilastik\gcamp_pixel_classifier.ilp';
    
    
else % running on cluster
    ilastik_props.ilastik_location='/groups/genie/home/kolbi/Downloads/ilastik-1.3.3post1-Linux/run_ilastik.sh';
    ilastik_props.proj_location = '/groups/genie/genie/ilya/code/GECI_NAA_code/ilastik/gcamp_pixel_classifier.ilp';
end

ilastik_props.output_filename = 'ilastik_segmentation.h5';
ilastik_props.datasetName = '/testGCaMP';

assert(isfile(ilastik_props.proj_location), ['ilastik project not found in: ' ilastik_props.proj_location])
assert(isfile(ilastik_props.ilastik_location), ['run_ilastik not found in: ' ilastik_props.ilastik_location])
assert(isfile(fileName), ['run_ilastk: ' fileName ' not found!'])

if isfile(ilastik_props.output_filename)
    disp('ilastik file already exists! Overwriting...')
end

ilastik_bat_str = ['"' ilastik_props.ilastik_location '"'];
ilastik_params = ['--headless --project="' ilastik_props.proj_location '" --export_source="Simple Segmentation" --readonly'];
ilastik_output_params = ['--output_filename_format="' ilastik_props.output_filename '"'];
tiffFile = ['"' fileName '"'];

ilastik_cmd = [ilastik_bat_str ' ' ilastik_params ' ' ilastik_output_params ' ' tiffFile];

% disp(ilastik_cmd)
[status, cmdout] = system(ilastik_cmd); % launch headless ilastik

assert(~status, ['error running ilastik: ' cmdout])
% h5data = h5read("ilastik_segmentation.h5", ilastik_props.datasetName);

pause(2)
if status
    warning(cmdout)
end

pause(2)

% read in generated data
h5data = h5read(ilastik_props.output_filename, ilastik_props.datasetName);

end

