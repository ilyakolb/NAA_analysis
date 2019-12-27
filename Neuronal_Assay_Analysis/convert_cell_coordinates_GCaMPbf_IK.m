% 12/4/19 IK fixed
cell_coordinates_org=ROI.pixel_list; % indices of masked pixels in 512 x 512 ref image
binning_factor=4; % IK MODIFIED to 4. originally = 5 (12/4/19)
frame_size_ref=512; % size of ref image

% size of stream image
% if binning_factor == 4 => frame_size_stream = 128 (CORRECT)
% if binning_factor == 5 => frame_size_stream = 102 (WRONG)
frame_size_stream = floor(frame_size_ref / binning_factor);

cur_coordinates=cell_coordinates_org;

% X,Y mask of cell in original image
[r, c]=ind2sub([frame_size_ref frame_size_ref],cur_coordinates); 

% scale X Y coords from ref image to stream image
conv_r=floor(r/binning_factor)+1;
conv_c=floor(c/binning_factor)+1;

% this doesn't do anything
if (max(conv_r)>frame_size_stream) || (max(conv_c)>frame_size_stream)
    conv_r(conv_r>frame_size_stream)=frame_size_stream;
    conv_c(conv_c>frame_size_stream)=frame_size_stream;
end

% convert X Y coords of stream image to indices
conv_ind=sub2ind([frame_size_stream,frame_size_stream],conv_r,conv_c);
conv_ind=unique(conv_ind);
mod_cell_coordinates=conv_ind;
cell_coordinates=mod_cell_coordinates;