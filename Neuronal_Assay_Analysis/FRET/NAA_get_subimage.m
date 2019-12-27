function [im]=NAA_get_subimage(im,box)

im=im(box(2):(box(2)+box(4)-1),box(1):(box(1)+box(3)-1),:);
% botim=im(botbox(2):(botbox(2)+height-1),botbox(1):(botbox(1)+width-1),:);

end