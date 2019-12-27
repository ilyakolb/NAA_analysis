function ephus_info=NAA_getEphus_info(xsgfilename)

if ~exist('xsgfilename')
  fprintf('Cannot find xsgfile %s \n', xsgfilename);
  exit;
%    xsgfilename =uigetfile('*.xsg');
end

load(xsgfilename,'-mat');
fs=10000;
total_channel=length(fieldnames(data.acquirer))/4;

temp2 = [];

for i=1:total_channel
    name=data.acquirer.(['channelName_',num2str(i)]);
    switch name
        case 'Volt 1-10'
            voltage=data.acquirer.(['trace_',num2str(i)])*10;
        case 'Current 1-10'
            current=data.acquirer.(['trace_',num2str(i)])*10;
        case 'Temp1'
            temp1=data.acquirer.(['trace_',num2str(i)])*20;
        case 'Temp2'
            temp2=data.acquirer.(['trace_',num2str(i)])*20;
        case 'Andor Sync'
            AndorSync=data.acquirer.(['trace_',num2str(i)]);
    end
end

%%
positive=(diff(AndorSync>1.5))>0;
timestamp=find(positive);
exposure=mean(diff(timestamp));
ephus_info.ImageTime=(timestamp+exposure/2)/fs;
ephus_info.AndorSync=single(AndorSync);


%%
vmax=max(voltage);
vbase=median(voltage);
threshold=(vmax-vbase)/2;
positive=(diff(voltage>threshold))>0;
timestamp=find(positive);

ephus_info.VPulseTime=timestamp/fs;
ephus_info.VAmp=median(voltage(voltage>threshold));
ephus_info.nVPulse=length(timestamp);
ephus_info.voltage=single(voltage);
%%
if length(current)<8000
    current=voltage;
end
cmax=max(current);
cbase=median(current);
threshold=(cmax-cbase)/2;
positive=(diff(current>threshold))>0;
timestamp=find(positive);
ephus_info.nIPulse=length(timestamp);

ephus_info.IPulseTime=timestamp/fs;
ephus_info.IAmp=median(current(current>threshold));

ephus_info.current=single(current);
% interp1(y,x,timestamp(1))

%%
ephus_info.AvgTemp1=mean(temp1(1:1000));
ephus_info.Temp1=single(temp1);
if isempty(temp2)
    ephus_info.AvgTemp2=NaN;
else
    ephus_info.AvgTemp2=mean(temp2(1:1000));
end
ephus_info.Temp2=single(temp2);
