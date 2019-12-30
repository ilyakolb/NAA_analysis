function ROI_list = NAA_segment_ilastik(refImage, mCherryImage, dF, h5data)% (GCaMPbase, mCherry, dF, type, segmentation_threshold,GCaMPbase2)
% ilya modifications to segmentation code
% variables to assign to cell_list
% GCaMPbase and GCaMPbase2 are both 512 x 512
% inputs:
%        refImage: 512x512 autofocusref image
%        mCherryImage: 512x512 mCherry ref image
%        dF: 128x128 max dF (unsure what this is for)
%        h5data: 1x512x512 segmentation data from ilastik. 1 is cell, 2 is
%        background

% cell_list.
%           pixel_list: linearized ref coords. convert_cell_coordinates
%                       converts these to dF_coordinates (stream coords)
%           mCherry: avg mCherry fluorescence in each ROI (?)
%           center: ref image coordinates of cell
%           GCaMPTotal: may not need. 

min_cell_area = 30;
max_cell_area = 180;
%%
% making it work w/ ilastik

% transpose to match ref image
% convert to 512 x 512, binarize to [0,1] with cells
h5data_ = abs(squeeze(h5data) - 2)'; 

h5data_ = logical(h5data_);

dataSize = size(h5data_);
streamSize = size(dF);
streamEdge = size(dF,1);
refEdge = dataSize(1);
imgSize = size(refImage);

assert(all(dataSize == imgSize), 'ref image size =/= h5 segmentation size')
assert(all(size(mCherryImage) == imgSize), 'ref image size =/= mCherry image size')

% CC = bwconncomp(h5data_);
ROIstats = regionprops(h5data_, 'PixelIdxList', 'PixelList', 'Area', 'Centroid');

% condition the stats array: remove tiny and huge blobs that are not cells
ROIstats([ROIstats.Area] < min_cell_area | [ROIstats.Area] > max_cell_area) = [];

% remove ROIs touching boundaries
ROIstats(arrayfun(@(x) any(x.PixelList(:) == 1)  | any(x.PixelList(:) == refEdge), ROIstats)) = [];

% add mCherry, dF_coordinates, dF fields
for i = 1:length(ROIstats)
    ROIstats(i).mCherry = mean(mCherryImage(ROIstats(i).PixelIdxList)); % assign mCherry signal
    
    % calculate stream coordinates (x,y) and indices
    streamCoords_xy = round(ROIstats(i).PixelList .* streamEdge ./ refEdge);
    streamCoords_xy(streamCoords_xy < 1) = 1;
    streamCoords_xy(streamCoords_xy > refEdge) = refEdge;
    streamCoords_ind = sub2ind(streamSize, streamCoords_xy(:,2), streamCoords_xy(:,1));
    ROIstats(i).dF_coordinates = unique(streamCoords_ind);
    ROIstats(i).dF = mean(dF(streamCoords_ind));
end


% sort according to largest area
[~, sortedIdx] = sort([ROIstats.Area], 'descend');
ROIstats = ROIstats(sortedIdx);

% reconstruct image
% reconstructedImg = zeros(imgSize);
% for i = 1:length(ROIstats)
%     reconstructedImg(ROIstats(i).PixelIdxList) = 1;
% end
% 
% figure, imagesc(reconstructedImg)


% rename fields for consistency with rest of code
if ~isempty(ROIstats)
    ROI_list = cell2struct( struct2cell(ROIstats), {'npixel', 'center', 'pixel_list', 'pixel_list_xy', 'mCherry', 'dF_coordinates', 'dF'});
else
    ROI_list = {};
end
end

