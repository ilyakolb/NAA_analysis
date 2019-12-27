files=dir('*.tif');
datenum=[files.datenum];
[s,ind]=sort(datenum);
files=files(ind);

firstim=zeros(512,512,length(files));
for i=1:length(files)
    firstim(:,:,i)=imread(files(i).name,2);
end

matVis(firstim);