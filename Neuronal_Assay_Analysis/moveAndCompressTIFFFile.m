function moveAndCompressTIFFFile(sourcePath, destPath)
    info = imfinfo(sourcePath);
    
    if ~isfield(info, 'ImageDescription')
        info.ImageDescription = '';
    end
    
    if isdir(destPath)
        % Only a destination directory was specified so use the same file name as the source.
        [~, name, ext] = fileparts(sourcePath);
        destPath = fullfile(destPath, [name ext]);
    end
    
    if strcmp(info(1).Compression, 'Uncompressed')
        % Write to a temp file and then move to the final location for better performance.
        tempPath = [tempname '.tiff'];
        try
            % Copy each plane of the TIFF to the destination.
            for image_index = 1:length(info)
                image_data = imread(sourcePath, 'Info', info, 'Index', image_index);
                if image_index == 1
                    imwrite(image_data, tempPath, 'Compression', 'lzw', 'Description', info(1).ImageDescription);
                else
                    imwrite(image_data, tempPath, 'Compression', 'lzw', 'WriteMode', 'append');
                end
            end
            movefile(tempPath, destPath);
            fileattrib(destPath, '+w', 'u');
            fileattrib(destPath, '+w', 'g');
        catch ME
            if exist(tempPath, 'file')
                delete(tempPath);
            end
            rethrow(ME);
        end

        delete(sourcePath);
    else
        % The TIFF is already compressed, just move it.
        movefile(sourcePath, destPath);
    end
end
