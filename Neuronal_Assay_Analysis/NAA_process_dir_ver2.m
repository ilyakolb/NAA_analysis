function NAA_process_dir(plate_folder_path, type, segmentation_threshold)

%todo try to handle case where dir_name does not include full path name
if ~isdir(plate_folder_path)
    error('Cannot find location: %s', plate_folder_path);
end

[~, plate_folder_name, ~] = fileparts(plate_folder_path);

files=dir(fullfile(plate_folder_path, '*.tif'));

if length(files)>3 && (strncmp(plate_folder_name, 'Well', 4) || strncmp(plate_folder_name, '96Well', 6)|| strncmp(plate_folder_name, '96well', 6))
    %data folder
    cd(plate_folder_path);
    disp(['Switching to ' , plate_folder_path,' for processing'])
    
%     if exist('Segmentation.mat', 'file') || exist('segmentation_cherry.mat', 'file')  %modified Hod
if false
        disp('This directory has already been processed.');
    else
        if strcmpi(type, 'GCaMP96') || strcmpi(type, 'RCaMP96')|| strcmpi(type, 'FRET96') || strcmpi(type, 'RCaMP96b') % changed by Hod 29Mar2013 and 05June2013
            segment_file_ID = 4;
            nominal_pulse = [1,3,10,160];
        else
            segment_file_ID = 8;
            nominal_pulse = [1,2,3,5,10,20,40,80,160];
        end
        
        try
            NAA_script_ver2(segment_file_ID, nominal_pulse, type, segmentation_threshold);
        catch ME
            disp('Processing of this directory failed:');
            disp(getReport(ME));
        end
    end
else
    % If subfolders are found then drill down
    subfolders=dir(plate_folder_path);
    subfolders=subfolders([subfolders.isdir]);
    for i=3:length(subfolders) 
        NAA_process_dir_ver2(fullfile(plate_folder_path, subfolders(i).name), type, segmentation_threshold);
    end
end
