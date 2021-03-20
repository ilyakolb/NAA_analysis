classdef Construct < Singleton
    
    properties
        wells = Well.empty(1, 0)
    end
    
    
    methods
        
        function obj = Construct(name)
            if strfind(name, 'dot')
                name = strrep(name, 'dot', '.');
            end
            
            obj = obj@Singleton(name);
        end
        
        
        function addWell(obj, well)
            obj.wells(end + 1) = well;
            obj.wells = sort(obj.wells);
        end
        
        
        function pw = passedWells(obj, dataFilter)
            % A well is considered to have passed if the passed flag is true, more than one ROI was found and 
            % there are the correct number of entries in the summary data.
            % For example, Well C6 on plate P1a-20110919 (10.454) has eight summary entries when there should be nine.
            % 
            % The dataFilter should be a structure with a 'protocol' field containing a Protocol instance and one of:
            %  * a 'minImagingDate' field containing the earliest imaging date that should be included
            %  * a 'plateSet' field containing a PlateSet instance
            
            if isfield(dataFilter, 'passedWells')
                % Use the cached list.
                disp('tried to use passedWells list')
                % pw = dataFilter.passedWells;
            else
                % Calculate the list of wells that passed.
                if isfield(dataFilter, 'minImagingDate')
                    if ischar(dataFilter.minImagingDate)
                        dataFilter.minImagingDate = str2double(dataFilter.minImagingDate);
                    end
                    pw = obj.wells(arrayfun(@(well) well.plate.protocol == dataFilter.protocol && ...
                                                    (~isempty(well.passed) && well.passed == true) && ...
                                                    length(well.cellList) > 1 && ...
                                                    ~isempty(well.summary) && length(dataFilter.protocol.nAP) == length(well.summary.df_fpeak_med) && ...
                                                    str2double(well.imagingDate) >= dataFilter.minImagingDate, ...
                                                    obj.wells));
                elseif isfield(dataFilter, 'plateSet')
                    % TODO: more than one plate set?
                    pw = obj.wells(arrayfun(@(well) well.plate.protocol == dataFilter.protocol && ...
                                                    (~isempty(well.passed) && well.passed == true) && ...
                                                    length(well.cellList) > 1 && ...
                                                    ~isempty(well.summary) && length(dataFilter.protocol.nAP) == length(well.summary.df_fpeak_med) && ...
                                                    (well.plate.parent == dataFilter.plateSet || well.plate.parent.parent == dataFilter.plateSet), ...
                                                    obj.wells));
                end
                dataFilter.passedWells = pw;
            end
        end
        
        
        function fw = failedWells(obj, dataFilter)
            % A well is considered to have faield if the passed flag is false, no ROI's were found or 
            % there are not the correct number of entries in the summary data.
            % 
            % The dataFilter should be a structure with a 'protocol' field containing a Protocol instance and one of:
            %  * a 'minImagingDate' field containing the earliest imaging date that should be included
            %  * a 'plateSet' field containing a PlateSet instance
            
            if isfield(dataFilter, 'failedWells')
                % Use the cached list.
                fw = dataFilter.failedWells;
            else
                % Calculate the list of wells that failed.
                if isfield(dataFilter, 'minImagingDate')
                    if ischar(dataFilter.minImagingDate)
                        dataFilter.minImagingDate = str2double(dataFilter.minImagingDate);
                    end
                    fw = obj.wells(arrayfun(@(well) well.plate.protocol == dataFilter.protocol && ...
                                                    str2double(well.imagingDate) >= dataFilter.minImagingDate && ...
                                                    (isempty(well.passed) || well.passed == false || ...
                                                     isempty(well.cellList) || ...
                                                     isempty(well.summary) || length(dataFilter.protocol.nAP) ~= length(well.summary.df_fpeak_med)), ...
                                                    obj.wells));
                elseif isfield(dataFilter, 'plateSet')
                    % TODO: more than one plate set?
                    fw = obj.wells(arrayfun(@(well) well.plate.protocol == dataFilter.protocol && ...
                                                    (well.plate.parent == dataFilter.plateSet || well.plate.parent.parent == dataFilter.plateSet) && ...
                                                    (isempty(well.passed) || well.passed == false || ...
                                                     isempty(well.cellList) || ...
                                                     isempty(well.summary) || length(dataFilter.protocol.nAP) ~= length(well.summary.df_fpeak_med)), ...
                                                    obj.wells));
                end
                dataFilter.failedWells = fw;
            end
        end
        
        
        function d = firstAssayDate(obj, dataFilter)
            dates = sort(arrayfun(@(well) well.assayDate, obj.passedWells(dataFilter), 'UniformOutput', false));
            if isempty(dates)
                d = [];
            else
                d = dates{1};
            end
        end
        
        
        function d = lastAssayDate(obj, dataFilter)
            dates = sort(arrayfun(@(well) well.assayDate, obj.passedWells(dataFilter), 'UniformOutput', false));
            if isempty(dates)
                d = [];
            else
                d = dates{end};
            end
        end
        
        
        function r = responses(obj, stimInd, dataFilter)
            pw = obj.passedWells(dataFilter);
            r = arrayfun(@(well) well.summary.df_fpeak_med(stimInd), pw);
            
            % Compensate for the number of cells detected if this is for 24-well GCaMP data.
            if pw(1).plate.protocol == Protocol('GCaMP')
                cellCounts = arrayfun(@(well) length(well.cellList), pw);
                coef = dataFilter.protocol.coef(:, stimInd);
                factor = (40 * coef(1) + coef(2)) ./ (cellCounts * coef(1) + coef(2));
                factor(factor > 2.5) = 2.5;
                factor(factor < 0.4) = 0.4;
                r = r .* factor;
            end
        end
        
        
        function d = decays(obj, stimInd, dataFilter)
            pw = obj.passedWells(dataFilter);
            decays = arrayfun(@(well) well.summary.decay_half_med(stimInd), pw);
            % Compensate for temperature.
            temps = arrayfun(@(well) well.temperature(), pw);
            if pw(1).plate.protocol==Protocol('GCaMP96')||pw(1).plate.protocol==Protocol('GCaMP96b')||pw(1).plate.protocol==Protocol('GCaMP')
                factors = (29 * -0.0633 + 2.495) ./ (temps * -0.0633 + 2.495);
            elseif pw(1).plate.protocol==Protocol('RCaMP96b')
                if str2num(pw(1).construct.name)>200 %RCaMP
                    if stimInd==3
                        factors = (29 * -0.03745 + 1.9867) ./ (temps * -0.03745 + 1.9867);
                    elseif stimInd==4
                        factors = (29 * -0.06862 + 3.5127) ./ (temps * -0.06862 + 3.5127); %160FPs
                    else
                        factors=1;
                    end
                elseif str2num(pw(1).construct.name)<200 %R-GECO
                    if stimInd==3
                        factors = (29 * -0.0448 + 1.793) ./ (temps * -0.0448 + 1.793);
                    elseif stimInd==4
                        factors = (29 * -0.0427 + 2.3672) ./ (temps * -0.0427 + 2.3672);
                    else
                        factors=1;
                    end
                end
            else
                factors=1;
            end
            if ~exist('factors', 'var')
                factors=1;
            end
            d = decays .* factors;
        end
        
        
        function r = rises(obj, stimInd, dataFilter)
            pw = obj.passedWells(dataFilter);
            rises = arrayfun(@(well) well.summary.rise_half_med(stimInd), pw);
            temps = arrayfun(@(well) well.temperature(), pw);
            if pw(1).plate.protocol==Protocol('RCaMP96b')
                if str2num(pw(1).construct.name)>200 %RCaMP
                    if stimInd==3
                        factors = (29 * -0.04555 + 1.642) ./ (temps * -0.04555 + 1.642);
                    elseif stimInd==4
                        factors = (29 * -0.07876 + 3.517) ./ (temps * -0.07876 + 3.517); %160FPs
                    else
                        factors=1;
                    end
                elseif str2num(pw(1).construct.name)<200 %R-GECO
                    if stimInd==3
                        factors = (29 * -0.00473 + 0.23) ./ (temps * -0.00473 + 0.23);
                    elseif stimInd==4
                        factors = (29 * -0.09425 + 3.317) ./ (temps * -0.09425 + 3.317);
                    else
                        factors=1;
                    end
                end
            else
                factors=1;
            end
            if ~exist('factors', 'var')
                factors=1;
            end
            
            r = rises .* factors;
        end
        
        function fullrises = timetopeak(obj, stimInd, dataFilter)
            pw = obj.passedWells(dataFilter);
            fullrises = arrayfun(@(well) well.summary.timetopeak_med(stimInd), pw);
            
        end
        

        function [dprime, SNR] =  dprimeAndSNR(~, fmean,~)
            % calculate d prime and SNR: average all cells for each well
            % inputs:
            %        fmean: [1x n_wells] cell array of [t x nAPs x nCells]
            %        type: assume ultra-fast ('uf')
            % assume stimulation happens at t = 200 frames
            % outputs:
            %         dprime: [nAPs x nWells] sensitivity index
            %         SNR: [nAPs x nWells] SNR
            
            nAPs = size(fmean{1},2);
            nWells = size(fmean,2);
            nFrames = size(fmean{1},1);
            
            dprime = nan(nAPs, nWells);
            SNR = dprime;
            
            % baseline
            stim_frame = 200;
            baseline_start= 150;
            duration_frames = 30;
            baseline_frames = baseline_start + (1:duration_frames)';
            
            for w = 1:nWells
                fmean_well = double(fmean{w});
                ncells = size(fmean_well,3);
                for apidx = 1:nAPs
                    dprime_well_array = nan(ncells,1);
                    SNR_well_array = dprime_well_array;
                    for cellidx = 1:ncells
                        trace = squeeze(fmean_well(:,apidx, cellidx));
                        baseline_segment = trace(baseline_frames);
                        [~,peak_idx] = max(trace(stim_frame:end));
                        peak_idx = peak_idx + stim_frame-1;
                        
                        % mis-identified peak -- set values to nan and move on
                        if peak_idx + duration_frames >= nFrames
                            dprime_well_array(cellidx) = NaN;
                            SNR_well_array(cellidx) = NaN;
                            continue;
                        end
                        
                        peak_segment = trace(peak_idx + (0:duration_frames-1));
                        
                        % simple bleach correction (linear fit)
                        c = polyfit(baseline_frames,baseline_segment,1);
                        slope = c(1);
                        index_diff = peak_idx - baseline_start;
                        peak_segment_corrected = peak_segment - index_diff*slope - (1:duration_frames)'.*slope;
                        
                        cell_SNR = (mean(peak_segment_corrected) - mean(baseline_segment))/std(baseline_segment);
                        cell_dp = abs(mean(peak_segment_corrected) - mean(baseline_segment)) / sqrt(0.5 * var(peak_segment_corrected) + var(baseline_segment));
                        
                        dprime_well_array(cellidx) = cell_dp;
                        SNR_well_array(cellidx) = cell_SNR;
                        
                    end
                    dprime(apidx, w) = nanmedian(dprime_well_array);
                    SNR(apidx, w) = nanmedian(SNR_well_array);
                    
                end
            end
            
            
            
        end
        function [dprime, SNR] = dprime(~, fmean,type)  %added by Hod 20131123, d-prome for 10FP added 20140603 by Hod
            if strcmp(type,'bf')
                base_time=1:150;
                resp_time=170:330; %modified by Hod 16Jan2014, to improve d-prime accuracy
                resp_time_SNR=170:500;
            elseif strcmp(type,'uf') || strcmpi(type,'CO') %added by Hod 20170728, modified IK 11/18/19 to include mngGECO
                % NOTE: use corrected for all except mngGECO?
                base_time= 150:180 ; %300:360 %for mngGECO % corrected: 
                resp_time= 210:240; %420:900 % for mngGECO % corrected: 
                resp_time_SNR= 210:500; %420:1000 for mngGECO % corrected: 210:500
            else
                base_time=1:23;
                resp_time=24:70; %modified by Hod 16Jan2014, to improve d-prime accuracy
                resp_time_SNR=24:135;
            end
            fmean_piled=[];
            for i=1:length(fmean)
                fmean_piled=cat(3,fmean_piled,fmean{1,i});
            end
            % build data on signal distribution during base period to detect AP later
            m0=zeros(size(fmean_piled,2),size(fmean_piled,3));
            s0=zeros(size(fmean_piled,2),size(fmean_piled,3));
            s1=zeros(1,size(fmean_piled,3));
            s10=zeros(1,size(fmean_piled,3));
            sd=zeros(size(fmean_piled,2),size(fmean_piled,3));
            signal_max=zeros(size(fmean_piled,2),size(fmean_piled,3));
            
            for i=1:size(fmean_piled,3)
                for j=1:size(fmean_piled,2)
                    signal0=fmean_piled(base_time,j,i);
                    m0(j,i)=mean(signal0);
                    s0(j,i)=max(signal0);
                    dF_0(j,i)=s0(j,i)-m0(j,i);
                    dff_0(j,i)=dF_0(j,i)/m0(j,i);
                    sd(j,i)=std(signal0);
                end
            end
            dF_0=reshape(dF_0,1,[]);
            dff_0=reshape(dff_0,1,[]);
            
            for i=1:size(fmean_piled,3)
                for j=1:size(fmean_piled,2)
                    if (j==size(fmean_piled,2)||j>=7)  %160FP or 40,80,160FP for RCaMP96c - time window is larger to include F peak, Hod 20140119
                        signal_resp=fmean_piled(resp_time_SNR,j,i);
                    else
                        signal_resp=fmean_piled(resp_time,j,i);
                    end
                    dF(j,i)=max(signal_resp)-m0(j,i);
                    dff(j,i)=(max(signal_resp)-m0(j,i))/m0(j,i);
                    %                     signal_baseline(j,i)=mean(fmean_piled(1:23,j,i));
                    %                     measured_resp(j,i)=max(signal_resp); %HD 20150728
                end
            end
            
            for j=1:size(fmean_piled,2) %num of FPs, HD 20150728
%                 dprime(j)=(mean(dF(j,:))-mean(dF_0))/(sqrt(0.5*(var(dF(j,:))+var(dF_0))));
                  dprime(j)=(mean(dff(j,:))-mean(dff_0))/(sqrt(0.5*(var(dff(j,:))+var(dff_0))));%modified d-prime calculation 20160214 HD
            end
            SNR=dF./sd;
        end
        
        %old code, modified 20150729 HD
        %dprime(j)=(mean(measured_resp(j,:))-mean(signal_baseline(j,:)))/(sqrt(0.5*(var(measured_resp(j,:))+var(signal_baseline(j,:)))));
                
                
                
                
                %                 signal1=fmean_piled(resp_time,1,i); %1FP data
                %                 if strcmp(type, 'RCaMP96b')
                %                     signal10=fmean_piled(resp_time,3,i); %10FP data, added 20140603 HD
                %                 elseif strcmp(type, 'RCaMP96c')
                %                     signal10=fmean_piled(resp_time,5,i); %HD 20150728
                %                     [a,ind]=max(signal1);
                %                 else
                %                     signal10=fmean_piled(resp_time,3,i);
                %                 end
                %                 [a2,ind2]=max(signal10);
                %                 s1(i)=a; %modified by Hod 20131123 - need to check if averaging several sample would affect results
                %                 s10(i)=a2;
                %                 dF_1(i)=s1(i)-m0(1,i);
                %                 dF_10(i)=s10(i)-m0(3,i);
            
            
            
            %             mu_0=mean(dF_0);
            %             mu_1=mean(dF_1);
            %             mu_10=mean(dF_10);
            %             var_0=var(dF_0);
            %             var_1=var(dF_1);
            %             var_10=var(dF_10);
            %
            %             dprime1=(mu_1-mu_0)/sqrt(0.5*(var_0+var_1)); %d-prime for 1FP resp
            %             dprime10=(mu_10-mu_0)/sqrt(0.5*(var_0+var_10));%d-prime for 10FP resp
            
        
            
        
        function [dates, brightness] = brightness(obj, dataFilter)
            pw = obj.passedWells(dataFilter);
            dates = arrayfun(@(well) well.assayDate, pw, 'UniformOutput', false);
            f0s = arrayfun(@(well) mean(well.summary.f0), pw);
            mCherrys = arrayfun(@(well) mean([well.cellList.mCherry]), pw);
            % IK ADDED GCaMP96uf to if statement below 10/30/19: don't want
            % to normalize to mCherry if no mCherry signal (e.g. if
            % comapring to XCaMPs. Otherwise, normalize to mCherry
            if pw(1).plate.protocol==Protocol('RCaMP96') || pw(1).plate.protocol==Protocol('mngGECO')
                brightness = f0s;
            else
                brightness = f0s ./ mCherrys;
            end
        end
        
        
        function [b, cb, dates] = normalizedBrightness(obj, controlDates, controlBrightness, dataFilter)
            % Return the brightness normalized to the median control brightness of each day.
            [dates, brightness] = obj.brightness(dataFilter);
            uniqueDates = unique(dates);
            b = [];
            cb = [];
                        for i = 1:length(uniqueDates)
                            controlInds = strcmp(controlDates, uniqueDates{i});
                            if any(controlInds)
                                controlBrightnessOnDate = controlBrightness(controlInds);
                                brightnessOnDate = brightness(strcmp(dates, uniqueDates{i}));
            
                                b = [b, brightnessOnDate / median(controlBrightnessOnDate)]; %#ok<AGROW>
                                cb = [cb, controlBrightnessOnDate / median(controlBrightnessOnDate)]; %#ok<AGROW>
                            end
                        end
             %Calculating brightness based on grand average - Modified by
             %Hod 20131009, returned to prev. version by Hod 20170125

%             controlInds = true(size(controlDates));
%             constructInds = true(size(dates));
%             controlBrightness = controlBrightness(controlInds);
%             constructBrightness = brightness(constructInds);
%             
%             b = [b, constructBrightness / median(controlBrightness)];
%             cb = [cb, controlBrightness / median(controlBrightness)];
        end
        
        
        function values = deltaFmaxF0(obj, dataFilter)
            % TODO: should a well be considered passed if its fmax is empty?
            
            pw = obj.passedWells(dataFilter);
            values = [];
            for well = pw
                if isempty(well.fMax)
                    % Exclude wells with no Fmax data.
                elseif median(well.fMax) < 0.1 * median([well.paraArray(end, :).f0])
                    % Per Doug, Fmax must be at least 10% of F0@160 to be considered.
                    % TODO: should the 10% check be per-ROI instead?
                elseif size(well.paraArray, 2) ~= size(well.fMax, 2)
                    % Exclude wells with mismatched cell list sizes.
                    % TODO: should this be an error state?
                else
%                    fprintf('%f\t%f\n', well.summary.f0(end), median(well.fMax));
                    f0 = [well.paraArray(2, :).f0];
                    values(end + 1) = median((well.fMax - f0) ./ f0); %#ok<AGROW>
                end
            end
        end
        
        
        function cmp = lt(obj, otherObj)
            objParts = regexp(obj.name, '\.', 'split');
            otherObjParts = regexp(otherObj.name, '\.', 'split');
            cmp = str2double(objParts{1}) < str2double(otherObjParts{1}) || ...
                  (str2double(objParts{1}) == str2double(otherObjParts{1}) && str2double(objParts{2}) < str2double(otherObjParts{2}));
        end
        
        
        function cmp = gt(obj, otherObj)
            objParts = regexp(obj.name, '\.', 'split');
            otherObjParts = regexp(otherObj.name, '\.', 'split');
            cmp = str2double(objParts{1}) > str2double(otherObjParts{1}) || ...
                  (str2double(objParts{1}) == str2double(otherObjParts{1}) && str2double(objParts{2}) > str2double(otherObjParts{2}));
        end
    end
    
    
    methods (Static)
        
        function i = all()
            i = Singleton.all('Construct');
        end
        
    end
    
end
