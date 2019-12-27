function NAA_process_dir_ver4(plate_folder_path, type, segmentation_threshold, WS, reprocessFlag)
% 4/12/19 IK added reprocessFlag

%todo try to handle case where dir_name does not include full path name
if ~isfolder(plate_folder_path)
    error('Cannot find location: %s', plate_folder_path);
end

[~, plate_folder_name, ~] = fileparts(plate_folder_path);

files=dir(fullfile(plate_folder_path, '*.tif'));

if length(files)>3 && (strncmp(plate_folder_name, 'Well', 4) || strncmp(plate_folder_name, '96Well', 6)|| strncmp(plate_folder_name, '96well', 6))
    %data folder
    cd(plate_folder_path);
    disp(['Switching to ' , plate_folder_path,' for processing'])
    
    % if reprocessFlag is not set and there are already segmentation files
    % there, do not reprocess
    if ~reprocessFlag && (exist('Segmentation.mat', 'file') || exist('segmentation_cherry.mat', 'file'))  %modified Hod
        disp('This directory has already been processed.');
    else % if reprocessFlag set OR segmentation files not present, reprocess
        if strcmpi(type, 'GCaMP96') ||strcmpi(type, 'GCaMP96b') || strcmpi(type, 'RCaMP96')|| strcmpi(type, 'FRET96') || strcmpi(type, 'RCaMP96b')||...
                strcmpi(type, 'OGB1')|| strcmpi(type, 'GCaMP96b-ERtag')|| strcmpi(type, 'GCaMP96z')|| strcmpi(type, 'RCaMP96z')||strcmpi(type, 'GCaMP96bf')...
                ||strcmpi(type, 'GCaMP96u')||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96u')||strcmpi(type, 'RCaMP96uf')% changed by Hod 29Mar2013 and 05June2013 and 20131125
            segment_file_ID = 4;
            nominal_pulse = [1,3,10,160];
        elseif strcmpi(type, 'mngGECO') % IK 11/15/19 to handle Abhi's sensor
            segment_file_ID = 8;
            nominal_pulse = [1,2,3,5,10,20,40,160];
        else
            error([type ' is not a recognized sensor type!'])
        end
        
        try
            % IK mod 5/29/19
			if WS % if wavesurfer
                NAA_script_ver4_IK(segment_file_ID, nominal_pulse, type, segmentation_threshold);
            else
				NAA_script_ver4(segment_file_ID, nominal_pulse, type, segmentation_threshold);
			end
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
        NAA_process_dir_ver4(fullfile(plate_folder_path, subfolders(i).name), type, segmentation_threshold, WS, reprocessFlag);
    end
end
