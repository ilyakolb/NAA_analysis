classdef PlateSet < VirtualFileObject
    
    properties
        type
    end
    
    
    methods
        
        function obj = PlateSet(parentSet, path, type, varargin)
            obj = obj@VirtualFileObject(parentSet, path, varargin{:});
            
            obj.type = type;
            
            if strcmp(type, 'Root')
                % Find any dated folders that start with '20'.
                primaryWeekDirs = dir(fullfile(path.primary, '20*'));
                for i = 1:length(primaryWeekDirs)
                    primaryWeekDirs(i).path = fullfile(path.primary, primaryWeekDirs(i).name);
                end
                archiveWeekDirs = dir(fullfile(path.archive, '20*'));
                archiveYearDirs = {};
                i = 1;
                while i <= length(archiveWeekDirs)
                    if length(archiveWeekDirs(i).name) == 4
                        % This is a folder that contains weekly folders for a given year, e.g. '2012'.
                        % We'll need to look one level deeper to find the weekly folders.
                        archiveYearDirs{end + 1} = fullfile(path.archive, archiveWeekDirs(i).name); %#ok<AGROW>
                        archiveWeekDirs(i) = [];    % Don't look for protocol folders
                    else
                        % It's a regular weekly folder.
                        archiveWeekDirs(i).path = fullfile(path.archive, archiveWeekDirs(i).name);
                        i = i + 1;
                    end
                end
                % Look for the weekly sub-folders of any yearly folders that were found.
                for i = 1:length(archiveYearDirs)
                    archiveYearWeekDirs = dir(fullfile(archiveYearDirs{i}, '20*'));
                    for j = 1:length(archiveYearWeekDirs)
                        archiveYearWeekDirs(j).path = fullfile(archiveYearDirs{i}, archiveYearWeekDirs(j).name);
                        archiveWeekDirs(end + 1) = archiveYearWeekDirs(j); %#ok<AGROW>
                    end
                end
                if isempty(archiveWeekDirs)
                    weekDirs = primaryWeekDirs;
                else
                    weekDirs = [primaryWeekDirs; archiveWeekDirs];
                end
                [~, inds] = sort({weekDirs.name}'); %#ok<TRSRT>
                weekDirs = weekDirs(inds(length(inds):-1:1));
                h = waitbar(0, 'Getting the list of plates from the file shares...', 'Name', 'GENIE NAA Curation', 'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)', 'WindowStyle', 'modal');
                for i = 1:length(weekDirs)
                    if getappdata(h, 'canceling')
                        break
                    end
                    if weekDirs(i).isdir
                        obj.children{end + 1} = PlateSet(obj, weekDirs(i).path, 'Week');
                    end
                    waitbar(i / length(weekDirs), h);
                end
                delete(h);
            elseif strcmp(type, 'Week')
                % This is a set for a week's results, find any protocol sub-folders.
                protocolDirs = dir(fullfile(path, 'result*'));
                for i = 1:length(protocolDirs)
                    % Try to guess the protocol from the folder name.
                    parts = regexp(protocolDirs(i).name, '_', 'split');
                    if length(parts) > 1
                        protocolName = parts{2};
                    else
                        protocolName = 'GCaMP';
                    end
                    if ~Protocol.exists(protocolName)
                        warning('GENIE:UnknownProtocol', 'Unknown protocol at %s', fullfile(path, protocolDirs(i).name));
                        protocolName = 'GCaMP';
                    end
                    protocolSet = PlateSet(obj, fullfile(path, protocolDirs(i).name), 'Protocol', protocolName);
                    if ~isempty(protocolSet)
                        obj.children{end + 1} = protocolSet;
                    end
                end
            elseif strcmp(type, 'Protocol')
                % This is a set for a specific protocol within a given week.
                plateDirs = dir(fullfile(obj.parent.path, ['P*-*_' obj.name]));
                if isempty(plateDirs)
                    plateDirs = dir(fullfile(obj.parent.path, ['P*-*-' obj.name]));
                end
                if isempty(plateDirs)
                    % Determine the set of plates from the contents of the results folder.
                    summaries = dir(fullfile(obj.path, 'P*Summary.mat'));
                    plateNames = cell(length(summaries), 1);
                    for i = 1:length(summaries)
                        try
                            info = NAA_file_info(summaries(i).name);
                            plateNames{i} = info.plate;
                        catch ME %#ok<NASGU>
                            warning('GENIE:UnknownSummaryFileFormat', 'Could not determine the plate of %s', fullfile(obj.parent.path, summaries(i).name));
                            plateNames{i} = '';
                        end
                    end
                    plateNames(strcmp(plateNames, '')) = [];
                    plateNames = unique(plateNames);
                else
                    plateNames = {plateDirs.name};
                end
                for i = 1:length(plateNames)
                    protocol = Protocol(obj.name);
                    plate = Plate(obj, fullfile(obj.parent.path, plateNames{i}), plateNames{i}, protocol);
                    if ~isempty(plate)
                        obj.children{end + 1} = plate;
                    end
                end
            else
                error('Unknown plate set type: %s', type);
            end
        end
        
        
        function c = canBeModified(obj)
            c = canBeModified@VirtualFileObject(obj);
            
            if c && strcmp(obj.type, 'Week')
                % Check if the folder is on the archive.
                rootPaths = obj.parent.path;
                c = strncmp(obj.path, rootPaths.primary, length(rootPaths.primary));
            end
        end
        
        
        function i = icon(obj)
            % TODO: return a different icon depending on annotation status
            if obj.canBeModified()
                i = fullfile(matlabroot, '/toolbox/matlab/icons/foldericon.gif');
            else
                [parentDir, ~, ~] = fileparts(mfilename('fullpath'));
                i = fullfile(parentDir, 'lockedfolder.gif');
            end
        end
        
    end
    
end