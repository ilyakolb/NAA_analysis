%% comparing cellpose and ilastik segmentation
clearvars
clc
% post-process ilastik h5 files generated using
% C:\Users\kolbi\Documents\cellpose\notebooks\ilastik_generate_h5.ipynb
segmentationToken = '_segIl.h5';
imageDir = 'C:/Users/kolbi/Documents/cellpose/testing/GCaMP';

tifFiles = dir(fullfile(imageDir, '*.tif'));
tifFiles = {tifFiles.name}';
h5Files = dir(fullfile(imageDir, ['*' segmentationToken]));
num_h5_files = length(h5Files);

for i = 1:num_h5_files
    h5Name = h5Files(i).name;
    % load reference image
    refImgName = [h5Name(1:strfind(h5Name,segmentationToken)-1) '.tif'];
    
    % should return just one match if everything is correct
    foundArray = contains(tifFiles, refImgName);
    
    % load reference image
    refImage = imread(fullfile(imageDir, tifFiles{find(foundArray,1)}));
    mCherryImage = refImage;
    dF = refImage;
    
    h5data = h5read(fullfile(imageDir, h5Name), '/exported_data');
    h5data = double(h5data);
    
    % ilastik
%     ROI_list = NAA_segment_ilastik(refImage, mCherryImage, dF, h5data);
%     dummyImg = zeros(size(refImage));
%     all_pixels = vertcat(ROI_list.pixel_list);
%     dummyImg(all_pixels) = 1;
%     B = bwboundaries(dummyImg);
%     refImageToShow = zeros([size(refImage) 3]); % show rgb image
%     refImageToShow(:,:,2) = mat2gray( imadjust(refImage));
%     figure('name', 'ilastik'); imshow(refImageToShow)
%     for j = 1:length(B)
%         boundary = B{j};
%         hold on,plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 1)
%         hold on,plot(boundary(:,2)+1, boundary(:,1)+1, 'k', 'LineWidth', 1)
%     end
    
    % Hod's original code
    cell_list = NAA_segment_IK(double(refImage), double(mCherryImage), double(dF), 'GCaMP96uf', 0, double(refImage));
    refImageToShow = zeros([size(refImage) 3]); % show rgb image
    refImageToShow(:,:,2) = mat2gray( imadjust(refImage));
    figure('name', 'Hod'); imshow(refImageToShow)
    for j = 1:length(cell_list)
        dummyImg = zeros(size(refImage));
        dummyImg(cell_list(j).pixel_list) = 1;
        B = bwboundaries(dummyImg);
        boundary = B{1};
        hold on,plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 1)
        hold on,plot(boundary(:,2)+1, boundary(:,1)+1, 'k', 'LineWidth', 1)
    end
end
