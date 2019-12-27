function [filename]=NAA_find_file(plate,well,stim)

% plate='P1-20101213';
% well='Well01-A1';
% stim='010FP';
datafolder='Z:\GECI Pipeline\Imaging Data\';
files=dir([datafolder,'201*']);
folders=files([files.isdir]);

idx=0;
found=0;
while (idx<length(folders)) && (found==0)
    idx=idx+1;
    subfolders=dir([datafolder,folders(idx).name]);
    subfolders=subfolders([subfolders.isdir]);
    names={subfolders.name};
    k=find(strcmp(names,plate));
    
    if ~isempty(k)        
        str=[datafolder,folders(idx).name,'\',plate,'\imaging\',well,'\*',stim,'*'];
        filename=dir([datafolder,folders(idx).name,'\',plate,'\imaging\',well,'\*',stim,'*.tif']);
        found=1;
    end    
    
end

if exist('filename')
    filename=[datafolder,folders(idx).name,'\',plate,'\imaging\',well,'\',filename.name];
else
    filename=[];
end