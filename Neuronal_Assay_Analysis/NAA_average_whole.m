function fmean=NAA_average_whole(filenames)

% if ~exist('filenames')
%     filenames = uigetfile('.\*.tif','MultiSelect','on');
% end
nFiles=length(filenames);

info = imfinfo(filenames{1},'tif');
nTime=length(info)-1;

fmean=zeros(nTime,nFiles);
for i=1:length(filenames)
    tic
    data=readTifStack(filenames{i});    
    toc
    data=data(:,:,2:end);
    ss=size(data);   
    fmean(:,i)=mean(reshape(data,[],ss(3)));         
end
