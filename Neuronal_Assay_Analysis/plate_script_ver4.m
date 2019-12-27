%% Function to run a single plate through the data pipeline
% NOTE: PDF generation is commented out
%       Excel files are not generated
% Global params give errors > put WS global param into argument
function plate_script_ver4(plate_folder_path, segmentation_threshold, WS, WSoptions, reprocessFlag)

% global WS % wavesurfer flag

if ~isfolder(plate_folder_path)
	error('Unable to find location: %s', plate_folder_path);
end
if nargin < 2 || isempty(segmentation_threshold)
	segmentation_threshold = [];
elseif isnan(str2double(segmentation_threshold))
	error('GENIE:InvalidThreshold', 'Invalid segmentation threshold: %s', segmentation_threshold);
else
	segmentation_threshold = str2double(segmentation_threshold);
end

if ~isdeployed
	fprintf('Analyzing folder at %s on %s\n', plate_folder_path, datestr(now));
end

imagingDir = fullfile(plate_folder_path, 'imaging');

% Determine the experiment type from the plate folder name.
[dayDir, plate_folder_name, ~] = fileparts(plate_folder_path);
parts = textscan(plate_folder_name, '%s', 'delimiter', '_');
type = parts{1}{end};

%% organize
tic
fprintf('\nOrganizing files \n');
NAA_organize_files(plate_folder_path);
toc
%% wavesurfer

if WS
	
	fprintf('\nProcessing Wavesurfer file...')
	
	% move relevant h5 file to plate folder path
	h5fileDirStr = fullfile(dayDir, [parts{1}{1} '*.h5']);
	h5fileDir = dir(fullfile(h5fileDirStr));
    % check day folder (where h5 file should be)
    if ~isempty(h5fileDir)
        movefile(fullfile(h5fileDir.folder, h5fileDir.name), plate_folder_path)
    elseif ~isempty(fullfile(plate_folder_path, [parts{1}{1} '*.h5']))
        disp('WS file already in right place')
    else
        error(['Error: Wavesurfer file not found or multiple files found at: ' h5fileDirStr])
    end
	
	
	% process H5 file
	NAA_processH5( imagingDir , WSoptions);
	fprintf('done\n\n')
	
end

%% process

fprintf('\nProcessing dir...\n');
NAA_process_dir_ver4(imagingDir, type, segmentation_threshold, WS, reprocessFlag);

%%
fprintf('\nChanging to imaging dir \n');
cd(imagingDir);

resultsDir = fullfile(imagingDir, 'results');

fprintf('\nCompiling results...\n');
NAA_pile_results(imagingDir, resultsDir, type, WS);

fprintf('\nChanging to imaging/results \n');
cd(resultsDir);

fprintf('\nCompiling df_f...\n');
NAA_pile_df_f_ver2_IK(type);


if strcmpi(type, 'FRET')||strcmpi(type, 'FRET96')
	NAA_pile_df_f_ver2(type, 'CFP');
	NAA_pile_df_f_ver2(type, 'YFP');
end

fprintf('\nGenerating results PDF...\n');
NAA_display_Plate_r2016b(type);

fprintf('\nAnalysis completed.\n\n');
end
