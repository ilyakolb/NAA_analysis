function NAA_organize_files(plate_folder_path)
% Move the P*.tif, p*.xsg and ionomycin/*.tif files to the appropriate places in the new imaging sub-folder.
  
% Check that the location exists.
if ~isdir(plate_folder_path)
    error('Unable to find location: %s', plate_folder_path);
end

[~, plate_folder_name, ~] = fileparts(plate_folder_path);

% If a plate folder is found then dive in.
if plate_folder_name(1)=='P' && plate_folder_name(2)~='0'
    cd(plate_folder_path);
    
    plate_imaging_folder=fullfile(plate_folder_path, 'imaging');
    
    if ~isdir(plate_imaging_folder)
        % Create the imaging result directory.
        mkdir(plate_imaging_folder);
        fileattrib(plate_imaging_folder, '+w', 'u');
        fileattrib(plate_imaging_folder, '+w', 'g');
    end
    
    % Find the files to move from the top level folder.
    files=dir(fullfile(plate_folder_path,'P*.tif'));
    xsg_files=dir(fullfile(plate_folder_path,'P*.xsg'));
    autofocus_files=dir(fullfile(plate_folder_path,'AutoFocus*'));
    
    % Get info on the files to move.
    info=[];
    info_xsg=[];
    info_autofocus={};
    for i=1:length(files)
        info=[info,NAA_file_info(files(i).name)]; %#ok<AGROW>
    end
    
    for i=1:length(xsg_files)
        info_xsg=[info_xsg,NAA_file_info(xsg_files(i).name)]; %#ok<AGROW>
    end
    
    for i=1:length(autofocus_files)
        info_autofocus={info_autofocus{:}, NAA_file_info(autofocus_files(i).name)}; %#ok<CCAT>
    end
    
    % Get the list of unique well names.
    if isempty(info)
        wells = {};
    else
        wells={info.well};
    end
    if isempty(info_xsg)
        wells_xsg = {};
    else
        wells_xsg={info_xsg.well};
    end
    if isempty(info_autofocus)
        wells_autofocus = {};
    else
        wells_autofocus=cellfun(@(x) x.well, info_autofocus, 'UniformOutput', false);
    end
    if ~isempty(wells)
        well_unique=unique(wells);
    elseif ~isempty(wells_xsg)
        well_unique=unique(wells_xsg);
    elseif ~isempty(wells_autofocus)
        well_unique=unique(wells_autofocus);
    else
        well_unique=[];
    end
    
    % Move the top-level files to well-specfic sub-folders.
    for i=1:length(well_unique)
        well_folder = fullfile(plate_imaging_folder, well_unique{i});
        segment_folder = fullfile(well_folder, 'Segment');
        if ~isdir(segment_folder)
            mkdir(segment_folder);
        end
        autofocus_folder = fullfile(well_folder, 'AutoFocus');
        if ~isdir(autofocus_folder)
            mkdir(autofocus_folder);
        end
        % Make sure all the GENIE people can read/write the folder and its files.
        fileattrib(well_folder, '+w', 'u');
        fileattrib(well_folder, '+w', 'g');
        fileattrib(segment_folder, '+w', 'u');
        fileattrib(segment_folder, '+w', 'g');
        fileattrib(autofocus_folder, '+w', 'u');
        fileattrib(autofocus_folder, '+w', 'g');
        
        % Move the TIFF's.
        ind=find(strcmp(wells,well_unique{i}));
        for j=1:length(ind)
            if strcmp(info(ind(j)).stim_pulse,'NoStim')
                % The segment TIFF's are small (~5 MB) so it's not necessary to compress them.
                movefile(files(ind(j)).name, segment_folder);
            else
                movefile(files(ind(j)).name, well_folder);
                % IK 10/7/19 - is there a need to compress?
                % moveAndCompressTIFFFile(files(ind(j)).name, well_folder);
            end
        end
        
        % Move the XSG files.
        ind2=find(strcmp(wells_xsg,well_unique{i}));
        for j=1:length(ind2)
            movefile(xsg_files(ind2(j)).name, well_folder);
        end
        
        % Move the auto-focus files.
        ind3=find(strcmp(wells_autofocus,well_unique{i}));
        for j=1:length(ind3)
            movefile(autofocus_files(ind3(j)).name, autofocus_folder);
        end
    end
    
    % Move any TIFF's in the ionomycin folder to well-specific sub-folders.
    ionomycin_folder = fullfile(plate_folder_path, 'ionomycin');
    if ~isdir(ionomycin_folder)
        ionomycin_folder = fullfile(plate_folder_path, 'IONOMYCIN');
    end
    if isdir(ionomycin_folder)
        % Get the list of unique well names.
        files=dir(fullfile(ionomycin_folder, '*.tif'));
        wells={};
        for i=1:length(files)
            a=textscan(files(i).name,'%s','delimiter','_n');
            wells{i}=a{1}{2}; %#ok<AGROW>
        end
        well_unique=unique(wells);
        
        % Move the files into a well-specific ionomycin sub-folder.
        for i=1:length(well_unique)
            imaging_folder = fullfile(plate_imaging_folder, well_unique{i}, 'ionomycin');
            if ~isdir(imaging_folder)
                mkdir(imaging_folder);
                fileattrib(imaging_folder, '+w', 'u');
                fileattrib(imaging_folder, '+w', 'g');
            end
            % The ionomycin TIFF's are small (~5 MB) so it's not necessary to compress them.
            movefile(fullfile(ionomycin_folder, ['*' well_unique{i} '*.tif']), imaging_folder);
        end
    end
else
    % If nested dirs exist then drill down.
    list=dir(plate_folder_path);
    for i=1:length(list)
        if list(i).isdir
            if (~strcmp(list(i).name,'.'))&&(~strcmp(list(i).name,'..'))
                NAA_organize_files([plate_folder_path,filesep,list(i).name]);
            end
        end
    end
end
