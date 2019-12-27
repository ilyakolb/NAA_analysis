function result = compile_results(plates_folder_path, plate_type, segmentation_threshold)
    if nargin < 2
        fprintf('Usage: compile_results <plates_folder_path> <plate_type> <optional segmentation_threshold>\n');
        result = -1;
        return
    else
        result = 0;
    end
    
    if ~isdir(plates_folder_path)
        error('Unable to find location: %s', plates_folder_path);
    end
    
    if ~isdeployed
        fprintf('Compiling weekly results at %s on %s\n\n', plates_folder_path, datestr(now));
    end
    
    cd(plates_folder_path);
    
    % Locate the results folder, creating it if needed.
    if nargin < 3 || isempty(segmentation_threshold)
        results_folder = fullfile(plates_folder_path, ['results_' plate_type]);
    else
        results_folder = fullfile(plates_folder_path, ['results_' plate_type '_th=' segmentation_threshold]);
    end
    if ~isfolder(results_folder)
        mkdir(results_folder);
        fileattrib(results_folder, '+w', 'u');
        fileattrib(results_folder, '+w', 'g');
    end
    
    % Copy the results files of each plate to the top-level results folder.
    plate_folders = dir(fullfile(plates_folder_path, ['P*' plate_type]));
    for i = 1:length(plate_folders)
        plate_folder = plate_folders(i).name;
        if plate_folder(2) ~= '0'
            try
                % original (12/9/19)
                % copyfile(fullfile(plates_folder_path, plate_folder, 'imaging', 'results', '*.mat'), results_folder);
                
                % IKMOD: copy over all Summary files (*Summary.mat)
                copyfile(fullfile(plates_folder_path, plate_folder, 'imaging', 'results', '*_Summary.mat'), results_folder);
                
                % if there is existing `P8a-20190826_GCaMP96uf.mat` file,
                % only modify the wellData to leave annotations intact
                newResultsFilePath = fullfile(plates_folder_path, plate_folder, 'imaging', 'results', [plate_folder '.mat']);
                oldResultsFilePath = fullfile(results_folder, [plate_folder '.mat']);
                if exist(oldResultsFilePath, 'file') > 0
                    disp('Results file already found! Preserving annotations...')
                    % load annotations and curator list from existing file
                    load(oldResultsFilePath, 'annotations', 'curators') 
                    
                    % load wellData from the new analysis
                    load(newResultsFilePath, 'wellData')
                    
                    save(oldResultsFilePath, 'annotations', 'curators', 'wellData')
                else
                    % just copy over the entire results .mat file
                    copyfile(newResultsFilePath, results_folder)
                end
            catch ME
                error('An error occurred while copying the results of %s:\n\t%s\n', plate_folder, ME.message);
            end
        end
    end
    
    % Create the top-level NAA_result Excel and text files.
    cd(results_folder);
    NAA_pile_df_f(plate_type);
    if strcmpi(plate_type, 'FRET')
        NAA_pile_df_f(plate_type, 'CFP');
        NAA_pile_df_f(plate_type, 'YFP');
    end
end
