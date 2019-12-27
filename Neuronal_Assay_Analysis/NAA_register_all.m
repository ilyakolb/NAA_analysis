target_file_ID=1;

files=dir('*.tif');
datenum=[files.datenum];
[s,ind]=sort(datenum);
files=files(ind);
filenames={files.name};


%%

im=readTifStack(filenames{target_file_ID},2,10);
im=mean(im,3);
imwrite(uint16(im),'target.tif');

parfor i=1:length(filenames)
name=filenames{i};
name=name(1:(end-4));
str=['java -Xmx4096m -jar "C:\Program Files (x86)\ImageJ\ij.jar" -ijpath "C:\Program Files (x86)\ImageJ" -batch register ',name];
system(str);
end
% for i=1:length(filenames)
% str=['java -Xmx4096m -jar "C:\Program Files (x86)\ImageJ\ij.jar" -ijpath "C:\Program Files (x86)\ImageJ" -batch register ',filenames{i}];
% system(str);
% system('
% end

%system(['java -Xmx4096m -jar "C:\Program Files (x86)\ImageJ\ij.jar" -ijpath "C:\Program Files (x86)\ImageJ" -batch Register ','"',filename,'"']);