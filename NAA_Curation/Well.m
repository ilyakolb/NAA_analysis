classdef Well < VirtualFileObject
    
    properties
        position
        assayDate
        
        construct
        buffer
        drugName
        drugVolume
        
        % Non-imagery data from the *cherry.mat files.
        summary
        cellList
        temperature1
        temperature2
        numNearby
        thumbnail
        
        % Imagery data from the *cherry.mat files.
        baseImage
        mCherryImage
        overlayImage
        paraArray
        fMean
        fMax
        responseMap
        
        modified    % Indicates whether the user has made changes that need to be saved.
        
        passed
        failureReason
    end
    
    
    properties (Dependent)
        plate
        description
        imagingDate
    end
    
    
    properties (Constant)
        % The imagery for each well takes 15-20 MB so one 96 well plate consumes nearly 2 GB.
        % To keep MATLAB from slowing to a crawl we limit the number of wells which can have their imagery in memory at the same time.
        % Once the limit is reached the least recently accessed imagery is purged but will be re-loaded the next time it's requested.
        imageryAccess = containers.Map; % A singleton object tracking which imagery was most recently accessed
        maxImageryInMemory = 100;
    end
    
    
    methods
        
        function obj = Well(plate, path, name, position, wellData)
            % Create a new well, optionally populating it with data cached at the plate level for performance.
            obj = obj@VirtualFileObject(plate, path, name);
            
            if isempty(Well.imageryAccess)
                map = Well.imageryAccess;
                map('loaded') = []; %#ok<NASGU>
            end
            
            obj.position = position;
            
            if ~isempty(path)
                % modified by Hod Dana 20140902 to overcome copying bug with duplicated folder names 
%                 xsgFiles = dir(fullfile(path, '*.xsg'));
                metadataFiles = dir(fullfile(path, 'P*.xsg'));
				
				% ADDED IK 20190616 FOR WAVESURFER COMPATIBILITY
				% no xsg files -> it's a wavesurfer folder, look for tifs
				if isempty(metadataFiles)
					metadataFiles = dir(fullfile(path, 'P*.tif'));
				end
                
				if ~isempty(metadataFiles)
                    info = NAA_file_info(metadataFiles(1).name);
                    parts = regexp(info.plate, '-', 'split');
                    if length(parts) ~= 2 || length(parts{2}) ~= 8
                        error 'bad plate name';
                    end
                    obj.assayDate = parts{2};
                    obj.construct = Construct(info.construct);
                    obj.construct.addWell(obj);
                    obj.buffer = info.buffer;
                    obj.drugName = info.drug;
                    obj.drugVolume = info.volume;
				end
			
            end
            
            obj.modified = false;
            
            if nargin == 5 && ~isempty(wellData)
                % Load the well with the non-imagery data cached in the annotations file.
                obj.loadDataFromStruct(wellData);
            else
                % Load the non-imagery data from the individual well .mat file.
                obj.loadMat(true, false);
            end
        end
        
        
        function p = get.plate(obj)
            p = obj.parent;
        end
        
        
        function d = saveDelegate(obj)
            % The plate saves any changes made to this well.
            d = obj.plate;
        end
        
        
        function loadDataFromStruct(obj, wellData)
            if strcmp(obj.plate.protocol.indicator, 'FRET')
                obj.summary = wellData.summaryRatio;
            else
                if ~isfield(wellData, 'summary')
                    disp([obj.plate.name ' well ' obj.name ' has no summary.']);
                else
                    obj.summary = wellData.summary;
                end
            end
            obj.cellList = wellData.cell_list;
            obj.temperature1 = wellData.temperature1;
            obj.temperature2 = wellData.temperature2;
            if isfield(wellData, 'fmax')
                obj.fMax = wellData.fmax;
            end
            if isfield(wellData, 'thumbnail')
                obj.thumbnail = wellData.thumbnail;
            end
            
            if strcmp(obj.plate.protocol.name, 'GCaMP96') ||strcmp(obj.plate.protocol.name, 'GCaMP96b')||strcmp(obj.plate.protocol.name, 'GCaMP96b-ERtag') ||...
                    strcmp(obj.plate.protocol.name, 'RCaMP96')|| strcmp(obj.plate.protocol.name, 'RCaMP96b') ||  strcmp(obj.plate.protocol.name, 'OGB1')||...
                    strcmp(obj.plate.protocol.name, 'GCaMP96z')||strcmp(obj.plate.protocol.name, 'RCaMP96z') ||strcmp(obj.plate.protocol.name, 'GCaMP96bf')...
                    ||strcmp(obj.plate.protocol.name, 'GCaMP96uf')||strcmp(obj.plate.protocol.name, 'mngGECO')||strcmp(obj.plate.protocol.name, 'RCaMP96uf')||strcmp(obj.plate.protocol.name, 'GCaMP96u')...
                    ||strcmp(obj.plate.protocol.name, 'RCaMP96u') % RCaMP96b added by Hod 10Jul2013, OGB1 on 20131125, updated 20170723
                if ~isempty(obj.cellList)
                    center = [obj.cellList.center];
                    distmat = squareform(pdist(center'));
                    obj.numNearby = sum(distmat < 50) - 1;
                else
                    obj.numNearby = 0;
                end
            end
        end
        
        
        function loadMat(obj, loadData, loadImagery)
            if strcmp(obj.plate.protocol.indicator, 'FRET')
                segmentationName = 'Segmentation.mat';
                baseName = 'CFP_base';
                summaryName = 'summaryRatio';
                responseName = 'dr_rmap';
            elseif strcmp(obj.plate.protocol.indicator, 'GCaMP2')
                segmentationName = 'segmentation_cherry.mat';
                baseName = 'GCaMPbase2';
                summaryName = 'summary';
                responseName = 'df_fmap';
            else
                segmentationName = 'segmentation_cherry.mat';
                baseName = 'GCaMPbase';
                summaryName = 'summary';
                responseName = 'df_fmap';
            end
            
            if loadImagery
                % Unload some imagery if we have too much in memory.
                map = Well.imageryAccess;
                loaded = map('loaded');
                if length(loaded) > Well.maxImageryInMemory
                    % Purge the imagery for the least recently accessed well.
                    % TODO: would it be faster overall to purge more than just one here?  Maybe 24?
                    well = loaded(end);
                    %fprintf('Unloading imagery for %s: %s\n', well.plate.name, well.name);
                    well.clearImagery();
                    loaded(end) = [];
                end
            end
            
            matPath = fullfile(obj.path, 'para_array_cherry.mat');
            if exist(matPath, 'file')
                if isempty(obj.passed)
                    obj.passed = true;
                end
                
                fields = {};
                if loadData
                    fields = {summaryName, 'cell_list', 'temperature1', 'temperature2', 'fmax'};  % para_array?
                end
                if loadImagery
                    fields = {fields{:}, baseName, responseName, 'mCherry', 'para_array', 'fmean'};
                end
                S = load(matPath, fields{:});
                if loadData
                    obj.loadDataFromStruct(S);
                end
                if loadImagery
                    obj.baseImage = S.(baseName);
                    obj.mCherryImage = S.mCherry;
                    obj.paraArray = S.para_array;
                    obj.fMean = S.fmean;
                    obj.responseMap = S.(responseName);
                    loaded = [obj loaded(:)'];
                end
            else
                % Get what we can from the segmentation file.
                matPath = fullfile(obj.path, segmentationName);
                if exist(matPath, 'file')
                    if isempty(obj.passed)
                        obj.passed = false;
                        reason = FailureReason('Unknown');
                        reason.addWell(obj);
                    end
                    
                    fields = {};
                    if loadData
                        fields = {'cell_list'};
                    end
                    if loadImagery
                        fields = {fields{:}, baseName, 'mCherry'}; %#ok<CCAT>
                    end
                    S = load(matPath, fields{:});
                    if loadData
                        obj.cellList = S.cell_list;
                    end
                    if loadImagery
                        obj.baseImage = S.(baseName);
                        obj.mCherryImage = S.mCherry;
                        loaded = [obj loaded(:)'];
                    end
                else
                    % fprintf('No data files could be found for well %s in %s.\n', obj.name, obj.path);
                end
            end
            
            if loadImagery
                map('loaded') = loaded; %#ok<NASGU>
            end
        end
        
        
        function d = get.fMax(obj)
            if isempty(obj.fMax)
                obj.loadMat(true, false);
            end
            d = obj.fMax;
        end
        
        
        function d = get.thumbnail(obj)
            if isempty(obj.thumbnail)
                if ~isempty(obj.overlayImage)
                    obj.thumbnail = uint8(imresize(obj.overlayImage, [100 100], 'bilinear') * 255);
                end
            end
            d = obj.thumbnail;
        end
        
        
        function d = get.baseImage(obj)
            if isempty(obj.baseImage)
                obj.loadMat(false, true);
            end
            d = obj.baseImage;
            obj.imageryWasAccessed();
        end
        
        
        function d = get.mCherryImage(obj)
            if isempty(obj.mCherryImage)
                obj.loadMat(false, true);
            end
            d = obj.mCherryImage;
            obj.imageryWasAccessed();
        end
        
        
        function o = get.overlayImage(obj)
            if isempty(obj.overlayImage)
                if ~isempty(obj.baseImage)
                    obj.overlayImage = NAA_create_overlay(obj.baseImage, obj.mCherryImage);
                end
            end
            
            o = obj.overlayImage;
            obj.imageryWasAccessed();
        end
        
        
        function d = get.paraArray(obj)
            if isempty(obj.paraArray)
                obj.loadMat(false, true);
            end
            d = obj.paraArray;
            obj.imageryWasAccessed();
        end
        
        
        function d = get.fMean(obj)
            if isempty(obj.fMean)
                obj.loadMat(false, true);
            end
            d = obj.fMean;
            obj.imageryWasAccessed();
        end
        
        
        function d = get.responseMap(obj)
            if isempty(obj.responseMap)
                obj.loadMat(false, true);
            end
            d = obj.responseMap;
            obj.imageryWasAccessed();
        end
        
        
        function imageryWasAccessed(obj)
            map = Well.imageryAccess;
            wellList = map('loaded');
            wellList(wellList == obj) = [];
            wellList = [obj wellList(:)'];
            map('loaded') = wellList; %#ok<NASGU>
        end
        
        
        function clearImagery(obj)
            % debug code: disp(['Freeing memory used by imagery for well ' obj.name ' on ' obj.plate.name]);
            obj.baseImage = [];
            obj.mCherryImage = [];
            obj.overlayImage = [];
            obj.paraArray = [];
            obj.fMean = [];
            obj.responseMap = [];
        end
        
        
        function d = get.description(obj)
            if strcmp(obj.plate.protocol.name, 'GCaMP96') ||strcmp(obj.plate.protocol.name, 'GCaMP96b')||strcmp(obj.plate.protocol.name, 'GCaMP96b-ERtag') ...
                    || strcmp(obj.plate.protocol.name, 'FRET96') ||  strcmp(obj.plate.protocol.name, 'RCaMP96')||  strcmp(obj.plate.protocol.name, 'RCaMP96b')...
                    ||  strcmp(obj.plate.protocol.name, 'OGB1')||strcmp(obj.plate.protocol.name, 'GCaMP96z')||strcmp(obj.plate.protocol.name, 'RCaMP96z')...
                    ||strcmp(obj.plate.protocol.name, 'GCaMP96bf')||strcmp(obj.plate.protocol.name, 'GCaMP96uf')||strcmp(obj.plate.protocol.name, 'mngGECO')||strcmp(obj.plate.protocol.name, 'RCaMP96uf')...
                    ||strcmp(obj.plate.protocol.name, 'GCaMP96u')||strcmp(obj.plate.protocol.name, 'RCaMP96u')%RCaMP96b added by Hod 10Jul2013, OGB1 on 20131125, RCaMP96z on 20161130, u and uf protocols on 20170723
                if ~isempty(obj.summary)
                    d = sprintf('dff=%.2g', obj.summary.df_fpeak(3));
                else
                    d = 'Missing summary';
                end
            else
                if isempty(obj.summary) || ~isfield(obj.summary, 'df_fpeak')
                    d = 'Missing summary';
                else
                    d = sprintf('df/f 10 = %.2g', obj.summary.df_fpeak(5));
                end
            end
        end
        
        
        function d = get.imagingDate(obj)
            d = obj.plate.parent.parent.name;
            if length(d) > 8
                d = d(1:8);
            end
        end
        
        
        function m = isModified(obj)
            m = obj.modified;
        end
        
        
        function setPassed(obj, passed, failureReason)
            if ~isa(failureReason, 'FailureReason')
                error('Well.setPassed() must be passed a FailureReason');
            end
            
            if isempty(passed) ~= isempty(obj.passed) || passed ~= obj.passed || (~passed && ~isequal(failureReason, obj.failureReason))
                if isempty(passed)
                    obj.passed = [];
                    obj.failureReason = [];
                elseif passed
                    if ~isempty(obj.failureReason)
                        obj.failureReason.removeWell(obj);
                    end
                    
                    obj.passed = true;
                    obj.failureReason = [];
                else
                    obj.passed = false;
                    obj.failureReason = failureReason;
                    
                    obj.failureReason.addWell(obj);
                end
                
                obj.modified = true;
            end
        end
        
        
        function t = temperature(obj)
            if obj.temperature1(1) < 50
                t = obj.temperature1(1);
            else
                t = obj.temperature2(1);
            end
        end
        
        
        function pw = plateWellFileName(obj)
            [~, wellFileName, ~] = fileparts(obj.path);
            [~, plateFileName, ~] = fileparts(obj.plate.path);
            pw = [plateFileName '_' wellFileName];
        end
        
        
        function [obj,idx]=sort(obj,varargin)
            % Sort the wells by their plate's file name and then their own file name.
            % This puts them in the same order that doing a directory listing on a results folder would get you.
            names = arrayfun(@(well) well.plateWellFileName(), obj, 'UniformOutput', false);
            [~,idx]=sort(names,varargin{:});
            obj=obj(idx);
        end
        
    end
    
end