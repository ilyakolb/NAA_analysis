files=dir('*.tif');
datenum=[files.datenum];
[s,ind]=sort(datenum);
files=files(ind);
filenames={files.name};

fmean=[];
for i=1:length(filenames)
dos(['copy ',filenames{i}, '  c:\temp.tif']);
data=readTifStack('c:\temp.tif');
ss=size(data);
data=reshape(data,[],ss(3));
fmean(:,i)=mean(data)';
end
save('para_array_cherry.mat','fmean');