function out=myprctile(data,p)
% p percentile, in percent, p=1 means 1 %

data=sort(data(:));
len=length(data);
ind=round(len*p/100);
if ind<1
    ind=1;
elseif ind>len
    ind=len;
end
out=data(ind);