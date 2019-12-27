function [wellName, wellData] = NAA_pile_results(plate_folder_path, result_folder, type, WS)

% global WS
%% FRET96 will be treated like standard FRET data
if strcmp(type,'FRET96')
    type='FRET';
elseif strcmp(type,'GCaMP96b-ERtag')
    type='GCaMP96b';
end

%todo try to handle case where dir_name does not include full path name
if ~isdir(plate_folder_path)
    error('Unable to find plate_folder_path: %s', plate_folder_path);
%    folder_name=uigetdir;
end

if ~isdir(result_folder)
    mkdir(result_folder);
end

files = dir(fullfile(plate_folder_path, '*.tif'));

if length(files)>3  % why 3?
    %data folder
    prevDir = cd(plate_folder_path);
    %disp(['switch to' , plate_folder_path,' for processing'])
    
    % Get the plate, well and construct from the name of the first .xsg file.
	
	% IK Wavesurfer compatibility
	% if using WS, look for tifs to get file names instead of XSGs. Should
	% be exactly the same
	if WS
		tif_files=dir([plate_folder_path,'/*.tif']);
		if isempty(tif_files)
			error('Unable to find any .tif files at %s', plate_folder_path);
		end
		fileInfo = NAA_file_info(tif_files(1).name);
	else
		xsg_files=dir([plate_folder_path,'/*.xsg']);
		if isempty(xsg_files)
			error('Unable to find any .xsg files at %s', plate_folder_path);
		end
		fileInfo = NAA_file_info(xsg_files(1).name);
	end
    [~, wellName] = strtok(fileInfo.well, '-');
    wellName = wellName(2:end);
    
    if strcmp(type, 'FRET')
        summaryName = 'summaryRatio';
        segmentationName = 'Segmentation.mat';
        baseName = 'CFP_base';
    else
        summaryName = 'summary';
        segmentationName = 'segmentation_cherry.mat';
        baseName = 'GCaMPbase';
    end
    
    if exist('para_array_cherry.mat', 'file')
        dest_path = fullfile(result_folder, [fileInfo.plate,'_',fileInfo.well,'_',fileInfo.construct,'_Summary.mat']);
        % if exist(dest_path, 'file')
        if false % UNCOMMENT TO NOT UPDATE SUMMARY.MAT FILES
			disp('Summary.mat file has already been copied to the results.');
        else
            copyfile('para_array_cherry.mat', dest_path);
        end
        
        % Grab a copy of the fields needed for producing the data_all file.
        if strcmpi(type, 'RCaMP96b')
            wellData = load('para_array_cherry.mat', summaryName, 'cell_list', 'temperature1', 'temperature2', 'mCherry', 'bleach','med_psw','med_psw_b2b', baseName);
        elseif strcmp(type, 'FRET')
            wellData = load('para_array_cherry.mat', summaryName, 'cell_list', 'temperature1', 'temperature2', 'mCherry', 'SNR', 'SNR_STD', baseName);
        elseif strcmp(type, 'GCaMP96bf')||strcmpi(type, 'GCaMP96uf')|| strcmpi(type, 'mngGECO') ||strcmpi(type, 'RCaMP96uf')
             wellData = load('para_array_cherry.mat', summaryName, 'cell_list', 'temperature1', 'temperature2', 'mCherry', baseName,'GCaMPbase2');
        else
            wellData = load('para_array_cherry.mat', summaryName, 'cell_list', 'temperature1', 'temperature2', 'mCherry', baseName);
        end
    elseif exist(segmentationName, 'file')
        % Segmentation failed, just grab just the cell list from the segmentation file.
        if strcmpi(type, 'GCaMP96bf')||strcmpi(type, 'GCaMP96uf') || strcmpi(type, 'mngGECO') ||strcmpi(type, 'RCaMP96uf')
            wellData = load(segmentationName, 'cell_list', 'mCherry', baseName,'GCaMPbase2');
        else
            wellData = load(segmentationName, 'cell_list', 'mCherry', baseName);
        end
        wellData.(summaryName) = [];
        wellData.temperature1 = [];
        wellData.temperature2 = [];
    else
        wellData = [];
    end
    if isfield(wellData, 'mCherry')
        % Create a thumbnail image of the well.
        if strcmpi(type, 'RCaMP96') || strcmpi(type, 'RCaMP96b')|| strcmpi(type, 'RCaMP96c')||strcmpi(type, 'RCaMP96u')
            overlay = NAA_create_overlay(wellData.(baseName), wellData.mCherry);
        elseif strcmpi(type, 'GCaMP96bf')||strcmpi(type, 'GCaMP96uf') || strcmpi(type, 'mngGECO') ||strcmpi(type, 'RCaMP96uf')
            overlay = NAA_create_overlay(wellData.mCherry,wellData.GCaMPbase2); %Hod 20170308
        else
            overlay = NAA_create_overlay(wellData.mCherry, wellData.(baseName));
        end
        wellData.thumbnail = uint8(imresize(overlay, [100 100], 'bilinear') * 255);
        wellData = rmfield(wellData, {'mCherry', baseName});
    end
    
    cd(prevDir);
else
    S.curators(1).name = 'Automatic analysis';
    S.curators(1).date = now; 
    S.annotations = [];
    S.wellData = [];
    
    [parentFolder, ~, ~] = fileparts(plate_folder_path);
    [~, plateFolderName, ~] = fileparts(parentFolder);

    subfolders=dir(plate_folder_path);
    subfolders=subfolders([subfolders.isdir]);
    for i=1:length(subfolders)
        if subfolders(i).name(1) ~= '.' && ~strncmp(subfolders(i).name, 'results', 7)
            [wellName, wellData] = NAA_pile_results(fullfile(plate_folder_path, subfolders(i).name), result_folder, type, WS);
            if isempty(wellData)
                S.annotations.(wellName).passed = false;
                S.annotations.(wellName).failureReason = 'Not imaged';
            elseif isempty(wellData.cell_list)
                S.annotations.(wellName).passed = false;
                S.annotations.(wellName).failureReason = 'Segmentation failure';
            else
                S.annotations.(wellName).passed = true;
                S.annotations.(wellName).failureReason = '';
            end
            S.wellData.(wellName) = wellData;
        end
    end
    
    % Save the annotations file and make sure it'll be writable by anyone in the 'geci' UNIX group.
    annotationsPath = fullfile(result_folder, [plateFolderName '.mat']);
    save(annotationsPath, '-struct', 'S');
    if isunix
        fileattrib(annotationsPath, '+w', 'g');
    end
end
