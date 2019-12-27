function NAA_processH5( imagingDir, WSoptions )
%NAA_ProcessH5 Processes h5 files from Wavesurfer and generates info file
%   equivalent to NAA_getEphus_info
%   INPUTS:
%       ImagingDir: dir containing h5 file and all well folders e.g.
%                   imagingDir = '/Volumes/genie/GENIE_Pipeline/GECI Imaging Data/20180828_GCaMP96uf_analyzed/P1a-20180813_GCaMP96uf/imaging'
%       WSoptions.
%                 nRecsPerWell: num stim pulses (e.g. 4)
%                 stim_sync_channel: = 4 for Rig 1
%                 andor_sync_channel: = 3 for Rig 1

nRecsPerWell = WSoptions.nRecsPerWell;
dirWells = dir(fullfile(imagingDir, '96Well*'));
nWells = length(dirWells);
% channel names
stim_sync_channel = WSoptions.stim_sync_channel;
andor_sync_channel = WSoptions.andor_sync_channel;

% h5 is in the main plate folder i.e. in /Volumes/genie/GENIE_Pipeline/GECI
% Imaging Data/20190528_GCaMP96uf_analyzed/P3a-20190513_GCaMP96uf
h5dir = fullfile(fileparts(imagingDir), '*.h5');
h5file = dir(h5dir);

assert(~isempty(h5file), ['Error: Wavesurfer file not found at: ' h5dir])

h5data = ws.loadDataFile(fullfile(h5file.folder, h5file.name));

fs = h5data.header.AcquisitionSampleRate;
nSweeps = length(fieldnames(h5data))-1; % sweeps start with 0001

% make sure num sweeps = n wells * n recs per well
assert(nSweeps == nWells * nRecsPerWell, ['Error, number of sweeps (' int2str(nSweeps) ') does not equal number of wells (' int2str(nWells) ') X number of recs per well (' int2str(nRecsPerWell) ')!']);


sweepCounter = 1;
for i = 1:nWells
	
	clearvars ws_info
	ws_info_array = [];
	for j = 1:nRecsPerWell
		
		currentSweep = h5data.(sprintf('sweep_%04d', sweepCounter));
		AndorSync = currentSweep.analogScans(:,andor_sync_channel);
		voltage = currentSweep.analogScans(:,stim_sync_channel);
		
		positive=(diff(AndorSync>1.5))>0;
		timestamp=find(positive);
		exposure=mean(diff(timestamp));
		ws_info.ImageTime=(timestamp+exposure/2)/fs;
		ws_info.AndorSync=single(AndorSync);
		
		
		%%
		vmax=max(voltage);
        vmin = min(voltage);
        if abs(vmin) > vmax % check for negative-going stim sync signal
            voltage = -1.*voltage;
            vmax = abs(vmin);
        end
		vbase=median(voltage);
		threshold=(vmax-vbase)/2;
		positive=(diff(voltage>threshold))>0;
		timestamp=find(positive);
		
		ws_info.VPulseTime=timestamp/fs;
		ws_info.VAmp=median(voltage(voltage>threshold));
		ws_info.nVPulse=length(timestamp);
		ws_info.voltage=single(voltage);
		%%
		current = voltage; % IK hack
		
		cmax=max(current);
		cbase=median(current);
		threshold=(cmax-cbase)/2;
		positive=(diff(current>threshold))>0;
		timestamp=find(positive);
		ws_info.nIPulse=length(timestamp);
		
		ws_info.IPulseTime=timestamp/fs;
		ws_info.IAmp=median(current(current>threshold));
		
		ws_info.current=single(current);
		% interp1(y,x,timestamp(1))
		
		%% not recording temperature
		% problems when temperature is NaN so make it 0 later?? -- IK 070319
		ws_info.AvgTemp1=NaN;
		ws_info.Temp1=NaN;
		ws_info.AvgTemp2=NaN;
		ws_info.AvgTemp2=NaN;
		ws_info.Temp2=NaN;
		
		
		ws_info_array = [ws_info_array ws_info];
		sweepCounter = sweepCounter + 1;
	end
	
	% save ws_info_array here
	h5SaveName = fullfile(dirWells(i).folder, dirWells(i).name, 'ws_info_array.mat');
	save(h5SaveName, 'ws_info_array');
	
	
end
end



