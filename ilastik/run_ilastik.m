function [h5data, status] = run_ilastik(fileName)
%RUN_ILASTIK: runs ilastik segmentation engine. Called by NAA_script_ver4_IK
% INPUTS:
%        fileName: AutoFocusRef file (just filename)
%        ilastik_props.
%                      ilastik_location: location of run-ilastik.bat
% OUTPUTS:
%         h5data: 1 x 512 x 512 ilastik segmentation output
%         status: system(  ) output. 0 if success

% TODO: pass this in instead of hardcoding

if ispc % running on my PC
    ilastik_props.ilastik_location= 'C:\Program Files\ilastik-1.3.3post1\run-ilastik.bat';
    ilastik_props.proj_location = 'Z:\ilya\code\GECI_NAA_code_20191003\ilastik\gcamp_pixel_classifier.ilp';
    
    
else % running on cluster
    ilastik_props.ilastik_location='';
    ilastik_props.proj_location = '';
end

ilastik_props.output_filename = 'ilastik_segmentation.h5';
ilastik_props.datasetName = '/testGCaMP';

assert(isfile(ilastik_props.proj_location), ['ilastik project not found in: ' ilastik_props.proj_location])
assert(isfile(ilastik_props.ilastik_location), ['run_ilastik.bat not found in: ' ilastik_props.ilastik_location])
assert(isfile(fileName), ['run_ilastk: ' fileName ' not found!'])

if isfile(ilastik_props.output_filename)
    disp('ilastik file already exists! Overwriting...')
end

ilastik_bat_str = ['"' ilastik_props.ilastik_location '"'];
ilastik_params = ['--headless --project="' ilastik_props.proj_location '" --export_source="Simple Segmentation"'];
ilastik_output_params = ['--output_filename_format="' ilastik_props.output_filename '"'];
tiffFile = ['"' fileName '"'];

ilastik_cmd = [ilastik_bat_str ' ' ilastik_params ' ' ilastik_output_params ' ' tiffFile];

disp(ilastik_cmd)
[status, cmdout] = system(ilastik_cmd); % launch headless ilastik

h5data = h5read("ilastik_segmentation.h5", ilastik_props.datasetName);

if status
    warning(cmdout)
end

% read in generated data
h5data = h5read(ilastik_props.output_filename, ilastik_props.datasetName);

end

