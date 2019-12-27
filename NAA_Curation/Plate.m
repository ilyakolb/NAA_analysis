classdef Plate < VirtualFileObject
    
    properties
        protocol
        wells
        
        curators
    end
    
    
    methods
        
        function obj = Plate(parentSet, path, name, protocol)
            obj = obj@VirtualFileObject(parentSet, path, name);
            
            obj.protocol = protocol;
        end
        
        function i = icon(obj) %#ok<MANU>
            % TODO: return a different icon depending on annotation status (dynamically determined by looking at wells?)
            [parentDir, ~, ~] = fileparts(mfilename('fullpath'));
            i = fullfile(parentDir, 'plate.png');
        end
        
        
        function w = get.wells(obj)
            % Don't load the wells until they are requested because it can take a while.
            if isempty(obj.wells)
                obj.wells = cell(obj.protocol.wellDims(1), obj.protocol.wellDims(2));
                
                % Read in the annotations file, if it exists.
                annotations = [];
                wellData = [];
                if exist(obj.annotationsPath(), 'file')
                    ws = warning('off', 'MATLAB:load:variableNotFound');
                    S = load(obj.annotationsPath(), 'curators', 'annotations', 'wellData');
                    warning(ws);
                    annotations = S.annotations;
                    obj.curators = S.curators;
                    if isfield(S, 'wellData')
                        wellData = S.wellData;
                    end
                end
                
                % Loop through the wells as defined by the protocol.
                for rowNum = 1:obj.protocol.wellDims(1)
                    for colNum = 1:obj.protocol.wellDims(2)
                        % Determine the well name at this row/column.
                        rowName = char(64 + rowNum);
                        if obj.protocol.wellDims(2) > 9
                            colName = sprintf('%02d', colNum);
                        else
                            colName = num2str(colNum);
                        end
                        wellName = [rowName colName];
                        
                        try
                            % See if there is a directory for this well.
                            % TODO: just make the dir call once for the plate then use regexp to see if there is an entry for the well
                            %% modified by Hod Dana 20140902 to overcome copying bug with duplicated folder names
%                             wellDirs = dir(fullfile(obj.path, 'imaging', ['*Well*-' wellName]));
                            wellDirs = dir(fullfile(obj.path, 'imaging', ['96Well*-' wellName]));
                            %% end of modification, 2nd line replaced 1st line 
                            
                            if length(wellDirs) == 1
                                wellPath = fullfile(obj.path, 'imaging', wellDirs(1).name);
                            else
                                wellPath = '';
                            end
                            
                            if isfield(wellData, wellName)
                                % Create a well using the data cached in the annotations file.
                                well = Well(obj, wellPath, wellName, [rowNum, colNum], wellData.(wellName));
                            else
                                % Create a well and let it read its data from its own file.
                                well = Well(obj, wellPath, wellName, [rowNum, colNum]);
                            end
                            
                            % Restore any annotations.
                            if isfield(annotations, wellName)
                                % Update the well's fields directly to avoid dirtying it.
                                % TODO: Pass these into the constructor instead.
                                well.passed = annotations.(wellName).passed;
                                if isfield(annotations.(wellName), 'failureReason') && ~isempty(annotations.(wellName).failureReason)
                                    reason = FailureReason(annotations.(wellName).failureReason);
                                    well.failureReason = reason;
                                    reason.addWell(well);
                                end
                            end
                            
                            % Add the well to this plate.
                            obj.wells{rowNum, colNum} = well;
                        catch ME
                            disp(['Could not load well ' wellName ' (' ME.message ')']);
                        end
                    end
                end
            end
            
            w = obj.wells;
        end
        
        
        function m = isModified(obj)
            % Check if any of the wells have been modified.
            m = any(any(cellfun(@(x) ~isempty(x) && x.isModified(), obj.wells)));
        end
        
        
        function p = annotationsPath(obj)
            plateSet = obj.parent;
            [~, fileName, ~] = fileparts(obj.path);
            p = fullfile(plateSet.path, [fileName '.mat']);
        end
        
        
        function [didSave, errorMessage] = save(obj)
            didSave = true;
            errorMessage = '';
            
            obj.curators(end+1).name = NAA_curation().userName;
            obj.curators(end).date = now; 
            S.curators = obj.curators;
            
            S.annotations = [];
            S.wellData = [];
            for i = 1:numel(obj.wells)
                well = obj.wells{i};
                S.annotations.(well.name).passed = well.passed;
                if isempty(well.failureReason)
                    S.annotations.(well.name).failureReason = '';
                else
                    S.annotations.(well.name).failureReason = well.failureReason.name;
                end
                S.wellData.(well.name).summary = well.summary;
                S.wellData.(well.name).cell_list = well.cellList;
                S.wellData.(well.name).para_array = well.paraArray;
                S.wellData.(well.name).temperature1 = well.temperature1;
                S.wellData.(well.name).temperature2 = well.temperature2;
                S.wellData.(well.name).fmax = well.fMax;
                S.wellData.(well.name).thumbnail = well.thumbnail;
            end
            
            try
                save(obj.annotationsPath(), '-struct', 'S');
                
                % Reset the dirty flag on all the wells.
                for i = 1:numel(obj.wells)
                    obj.wells{i}.modified = false;
                end
            catch ME
                didSave = false;
                errorMessage = ME.message;
            end
        end
    end
    
end
