classdef NAA_curation < Singleton
    
    properties
        pipelinePaths
        plateSetsRoot
        
        mainWindow
        toolbar
        userName
        
        % User interface elements
        plateSetsTree
        inspectionPanel
        inspectionTitle
        
        plateSetInspector
        plateInspector
        wellInspector
        
        inspector
        
        dataAllWB
        dataAllCellStyles
        
        selectingObjectInTree = false
    end
    
    
    methods
        
        function obj = NAA_curation()
            obj = obj@Singleton();
            
            if isempty(obj.mainWindow)
                % Build the interface the first time this method is called.
                
                if verLessThan('matlab', '7.12')
                    error('NAA curation requires MATLAB 7.12.0 (R2011a) or later');
                end
                
                if ~isdeployed
                    % Make sure we can find the NAA and POI (OpenOffice) functions we need.
                    [parentDir, ~, ~] = fileparts(mfilename('fullpath'));
                    addpath(parentDir);
                    [parentDir, ~, ~] = fileparts(parentDir);
                    addpath(fullfile(parentDir, 'Neuronal_Assay_Analysis'));
                    addpath(fullfile(parentDir, 'POI'));
                end
                
                obj.createSingletons();
                
                obj.populatePlateSets();
                
                obj.buildInterface();
                
                if ispc()
                    obj.userName = getenv('UserName');
                else
                    obj.userName = getenv('USER');
                end
                
                enablePOI();
                
                % TODO: re-select last plate curated?
            end
        end
        
        
        %% Protocols
        
        
        function createSingletons(obj) %#ok<MANU>
            gcamp = Protocol('GCaMP', 'GCaMP');
            gcamp.dataAllFilters = {'10\..*', 'ogb1'};
            Protocol('GCaMP96', 'GCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.1'));
            Protocol('GCaMP96b', 'GCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.641'));
            Protocol('GCaMP96z', 'GCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.641'));
            Protocol('FRET', 'FRET');
            Protocol('FRET96', 'FRET', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('19.20'));
            Protocol('Dye', 'Dye');
            Protocol('Arch', '???');
            Protocol('RCaMP', 'RCaMP');
            Protocol('RCaMP96', 'RCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1], [8, 12], Construct('101.1'));
            Protocol('RCaMP96b', 'RCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1], [8, 12], Construct('206.1488'));
            Protocol('RCaMP96c', 'RCaMP', [1, 2, 3, 5, 10, 20, 40, 80, 160],[0.3, 0.7, 1.5, 7] , [1, 1, 1, 1; 1, 1, 1, 1], [8, 12], Construct('206.1'));
            Protocol('RCaMP96z', 'RCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1], [8, 12], Construct('206.1488'));
            Protocol('RCaMP96u', 'RCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('206.1488'));
            Protocol('RCaMP96uf', 'GCaMP2', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('206.1488'));
            Protocol('OGB1', 'OGB1', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1], [8, 12], Construct('OGB1'));
            Protocol('GCaMP96b-ERtag', 'GCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.1'));
            Protocol('GCaMP96bf', 'GCaMP2', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.641'));
            Protocol('GCaMP96c', 'GCaMP', [1, 2, 3, 5, 10, 20, 40, 80, 160],[0.3, 0.7, 1.5, 2, 2.5, 3, 3.5, 5 6 7] , [1, 1, 1, 1; 1, 1, 1, 1], [8, 12], Construct('10.641'));
            Protocol('GCaMP96d', 'GCaMP', [1, 2, 3, 5, 10, 20, 40, 80, 160],[0.3, 0.7, 1.5, 2, 2.5, 3, 3.5, 5 6 7] , [1, 1, 1, 1; 1, 1, 1, 1], [8, 12], Construct('10.641'));
            Protocol('GCaMP96u', 'GCaMP', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.641'));          
            
            % GCaMP6s as control
            Protocol('GCaMP96uf', 'GCaMP2', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.641'));
            
            % jG7f as control
            % Protocol('GCaMP96uf', 'GCaMP2', [1, 3, 10, 160], [0.3, 0.7, 1.5, 7], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.921'));
            
            % IK added 16/11/19 to process Abhi sensors
            % Protocol('mngGECO', 'GCaMP2', [1, 2, 3, 5, 10, 20, 40, 160], [0.3, 0.7, 1.5, 2, 2.5, 3, 3.5, 5], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.641'));
            % IK modified 12/15/20 for ufgcamp linearity
            Protocol('mngGECO', 'GCaMP2', [1, 2, 3, 5, 10, 40], [0.3, 0.7, 1.5, 2, 2.5, 3.5], [1, 1, 1, 1; 1, 1, 1, 1] / 1000, [8, 12], Construct('10.641'));
            
            FailureReason('Bad focus');
            FailureReason('Imaging problem');
            FailureReason('no red signal'); %added by Hod Dana 02032014
            FailureReason('no 160FP dF/F response'); %added by Hod Dana 02032014
            FailureReason('not enough ROIs'); %added by Hod Dana 02032014
            FailureReason('electrode bubble'); %added by Hod Dana 02032014
            FailureReason('Cell health problem');
            FailureReason('Expression problem');
            FailureReason('Stimulation problem');
            FailureReason('Other');
            FailureReason('Side column effect');
        end
        
        
        %% User interface management
        
        
        function buildInterface(obj)
            % Restore the window position if possible.
            addlProps = {};
%             if ispref('GENIE_NAA_Curation', 'MainWindow_Position')
%                 prevPos = getpref('GENIE_NAA_Curation', 'MainWindow_Position', []);
%                 if ~isempty(prevPos)
%                     addlProps = {'Position', prevPos};
%                 end
%             end
            
            % Create the main window.
            obj.mainWindow = figure(...
                'Units', 'points', ...
                'Menubar', 'none', ...
                'Name', 'GENIE NAA Curation', ...
                'NumberTitle', 'off', ...
                'Color', get(0,'defaultUicontrolBackgroundColor'), ...
                'CloseRequestFcn', @(hObject, eventdata)closeRequestFcn(obj, hObject, eventdata), ...
                'WindowButtonUpFcn', @(hObject, eventdata)mouseButtonWasPressed(obj, hObject, eventdata), ...
                'WindowKeyPressFcn', @(hObject, eventdata)keyWasPressed(obj, hObject, eventdata), ...
                'WindowScrollWheelFcn', @(hObject, eventdata)mouseWheelWasScrolled(obj, hObject, eventdata), ...
                'ResizeFcn', @(hObject, eventdata)windowWasResized(obj, hObject, eventdata), ...
                'Position', [1 1 1024 768], ...     % default, may get overriden by addlProps
                'UserData', [], ...
                'Tag', 'figure', ...
                addlProps{:});
            
            % Create the toolbar
            [curationRoot, ~, ~] = fileparts(mfilename('fullpath'));
            defaultBackground = get(0,'defaultUicontrolBackgroundColor');
            obj.toolbar = uitoolbar(obj.mainWindow);
            saveIcon = double(imread(fullfile(curationRoot, 'file_save.png'),'BackgroundColor', defaultBackground)) / 65535;
            uipushtool(obj.toolbar, 'CData', saveIcon, ...
                 'TooltipString', 'Save the current object',...
                 'ClickedCallback', @(hObject, eventdata)saveCurrentObject(obj, hObject, eventdata));
            dataAllIcon = double(imread(fullfile(curationRoot, 'book_mat.png'),'BackgroundColor', defaultBackground)) / 255;
            uipushtool(obj.toolbar, 'CData', dataAllIcon, ...
                 'TooltipString', 'Create the data_all file',...
                 'ClickedCallback', @(hObject, eventdata)createDataAllFile(obj, hObject, eventdata));
            [roguesIcon, colorMap] = imread(fullfile(curationRoot, 'helpicon.gif'));
            roguesIcon = ind2rgb(roguesIcon, colorMap);
            uipushtool(obj.toolbar, 'CData', roguesIcon, ...
                 'TooltipString', 'Show the Rogue''s Gallery',...
                 'ClickedCallback', @(hObject, eventdata)showRoguesGallery(obj, hObject, eventdata));
            failuresIcon = imread(fullfile(curationRoot, 'Failures.png'), 'BackgroundColor', defaultBackground);
            uipushtool(obj.toolbar, 'CData', failuresIcon, ...
                 'TooltipString', 'Create the list of failed wells',...
                 'ClickedCallback', @(hObject, eventdata)createFailedWells(obj, hObject, eventdata));
            
            
            % Add the tree control for browsing plate sets.
            state = warning('off', 'MATLAB:uitree:DeprecatedFunction');
            warning('off', 'MATLAB:uitreenode:DeprecatedFunction');
            rootNode = uitreenode('v0', 'Root', 'Plate Sets', [], false);
            rootNode.UserData = obj.plateSetsRoot;
            [obj.plateSetsTree, treeContainer] = uitree('v0', ...
                'Parent', obj.mainWindow, ...
                'Position', [0 0 0.2 1], ...
                'Root', rootNode);
            warning(state);
            set(treeContainer, 'Units', 'normalized', ...
                'Position', [0 0 0.2 1]);
            set(obj.plateSetsTree, 'NodeExpandedCallback', @(tree, eventData)expandPlateSet(obj, eventData));
            set(obj.plateSetsTree, 'NodeSelectedCallback', @(tree, eventData)selectPlateSet(obj, eventData));
            tree = obj.plateSetsTree.getTree;
            tree.expandRow(0);
            tree.setRootVisible(false);
            tree.setShowsRootHandles(true);
            handleTree = obj.plateSetsTree.getScrollPane;
            jTreeObj = handleTree.getViewport.getComponent(0);
            jTreeObjh = handle(jTreeObj,'CallbackProperties');
            set(jTreeObjh, 'MouseMovedCallback',   @(tree, eventData)treeMouseMoved(obj, eventData));    % for tooltips
            
            % Create the inspection panel
            obj.inspectionPanel = uipanel(obj.mainWindow, ...
                'BorderType', 'none', ...
                'Position', [0.2 0.0 0.8 1.0], ...
                'Visible', 'on', ...
                'HitTest', 'off');
            obj.inspectionTitle = uicontrol(obj.inspectionPanel, ...
                'Style','text', ...
                'Units', 'normalized', ...
                'Position',[0 0.97 1 0.03], ...
                'FontUnits', 'normalized', ...
                'FontSize', 0.5, ...
                'String', '');
            
            % Create the inspectors.
            obj.plateSetInspector = PlateSetInspector();
            obj.plateInspector = PlateInspector();
            obj.wellInspector = WellInspector();
        end
        
        
        function windowWasResized(obj, ~, ~)
            if ~isempty(obj.inspector)
                % Get the new position of the panel in pixels.
                prevUnits = get(obj.inspector.panel, 'Units');
                set(obj.inspector.panel, 'Units', 'pixels');
                newPosition = get(obj.inspector.panel, 'Position');
                set(obj.inspector.panel, 'Units', prevUnits);
                
                % Let the inspector resize any of its controls.
                obj.inspector.handleResize(newPosition);
            end
        end
        
        
        function keyWasPressed(obj, ~, eventData)
            if ~isempty(obj.inspector)
                % Let the inspector handle the key press.
                obj.inspector.handleKeyPress(eventData);
            end
        end
        
        
        function mouseButtonWasPressed(obj, ~, eventData)
            if ~isempty(obj.inspector)
                % Get the location of the click in the inspector panel's unit coordinates.
                set(obj.mainWindow, 'Units', 'pixels')
                mouseLoc = get(obj.mainWindow, 'CurrentPoint');
                
                oldUnits = get(obj.inspectionPanel, 'Units');
                set(obj.inspectionPanel, 'Units', 'pixels');
                panel1Pos = get(obj.inspectionPanel, 'Position');
                set(obj.inspectionPanel, 'Units', oldUnits);
                
                oldUnits = get(obj.inspector.panel, 'Units');
                set(obj.inspector.panel, 'Units', 'pixels');
                panel2Pos = get(obj.inspector.panel, 'Position');
                set(obj.inspector.panel, 'Units', oldUnits);
                
                % IK
                mouseLoc(1) = (mouseLoc(1) - panel1Pos(1) - panel2Pos(1)) / (panel2Pos(3));
                mouseLoc(2) = (panel2Pos(4) - (mouseLoc(2) - panel1Pos(2) - panel2Pos(2))) / panel2Pos(4);
                
                % original
                % mouseLoc(1) = (mouseLoc(1) - panel1Pos(1) - panel2Pos(1)) / panel2Pos(3);
                % mouseLoc(2) = (panel2Pos(4) - (mouseLoc(2) - panel1Pos(2) - panel2Pos(2))) / panel2Pos(4);
                
                if mouseLoc(1) > 0.0 && mouseLoc(1) < 1.0 && mouseLoc(2) > 0.0 && mouseLoc(2) < 1.0
                    % Let the inspector handle the click.
                    obj.inspector.handleMouseClick(mouseLoc, eventData);
                end
            end
        end
        
        
        function mouseWheelWasScrolled(obj, ~, eventData)
            if ~isempty(obj.inspector)
                % Let the inspector handle the wheel scroll.
                obj.inspector.handleMouseWheelScroll(eventData);
            end
        end
        
        
        function closeRequestFcn(obj, ~, ~)
            if ~isempty(obj.inspector)
                % Make sure any changes are saved before closing.
                if ~obj.inspectObject([])
                    return
                    
                end
            end
            
            % Make sure the Rogue's Gallery gets closed.
            gallery = RoguesGallery();
            if ~close(gallery.mainWindow)
                waitfor(errordlg('Could not close the Rogue''s Gallery.'));
            else
                delete(gallery);

                % Remember the window position.
                setpref('GENIE_NAA_Curation', 'MainWindow_Position', get(obj.mainWindow, 'Position'));
                delete(obj.mainWindow);
                obj.mainWindow = [];

                % Make sure the PlateSets and Plates get deleted.
                delete(obj.plateSetsRoot);

                % Clear the imagery access history for wells.
                map = Well.imageryAccess;
                map('loaded') = []; %#ok<NASGU>

                % Delete this singleton interface object.
                delete(obj);

                % Remove all of the other singleton instances.
                delete(Construct.all());
                delete(Protocol.all());
                delete(FailureReason.all());
            end
        end
        
        
        %%
        
        % 10/14/19: changing paths
        function populatePlateSets(obj)
            if ispc
                obj.pipelinePaths.primary = '';
                obj.pipelinePaths.archive = '';
                % Scan through drive letters Z-C to see where the GENIE share is mounted.
                for i = double('Z'):-1:double('C')
                    if exist(['' i ':\GECIScreenData'], 'dir')
                        obj.pipelinePaths.primary = [i ':\GECIScreenData'];
                    end
                    if exist(['' i ':\GENIE_Pipeline'], 'dir')
                        obj.pipelinePaths.archive = [i ':\GENIE_Pipeline'];
                    end
                end
            elseif ismac
                % Determine the path to the primary and archive shares using the command line 'mount' utility.
                [status, obj.pipelinePaths.primary] = system('mount | grep -i nearline | sed "s/.* on \(.*\) (.*/\1/g"');
                if status == 0 && ~isempty(obj.pipelinePaths.primary)
                    obj.pipelinePaths.primary = fullfile(obj.pipelinePaths.primary(1:end-1), 'GENIE_Pipeline');
                end
%                 [status, obj.pipelinePaths.archive] = system('mount | grep -i arch/genie | sed "s/.* on \(.*\) (.*/\1/g"');
                  [status, obj.pipelinePaths.archive] = system('mount | grep -i tier2.hhmi.org | sed "s/.* on \(.*\) (.*/\1/g"'); %modified Hod 20140723
                if status == 0 && ~isempty(obj.pipelinePaths.archive)
                    obj.pipelinePaths.archive = fullfile(obj.pipelinePaths.archive(1:end-1), '/GENIE_Pipeline');
                end
            else
                obj.pipelinePaths.primary = '/groups/flylight/GENIE/GENIE_Pipeline';
                obj.pipelinePaths.archive = '/archive/genie/GENIE_Pipeline';
            end
            
            imagingPaths.primary = fullfile(obj.pipelinePaths.primary, 'GECI_Imaging_Data');
            
            % IK 12-6-2019: change back to 'GECI Imaging Data' to find
            % archive
            imagingPaths.archive = fullfile(obj.pipelinePaths.archive, 'GECI Imaging Data_');
            if ~isdir(imagingPaths.primary)
                waitfor(errordlg('Please mount the GENIE share and try again.', 'GENIE NAA Curation', 'modal'));
                error('Could not determine list of plate sets: GENIE share is not mounted.');
            elseif ~isdir(imagingPaths.archive)
                waitfor(warndlg('The full list of plates will not be available because the GENIE archive share could not be found.', 'GENIE NAA Curation', 'modal'));
                warning('Could not determine the full list of plate sets: GENIE archive share is not mounted.');
            end
            obj.plateSetsRoot = PlateSet([], imagingPaths, 'Root', 'Plate Sets');
        end
        
        
        %% Toolbar actions
        
        function saved = saveCurrentObject(obj, ~, ~)
            if ~isempty(obj.inspector) && ~isempty(obj.inspector.object)
                inspectedObject = obj.inspector.object;
                if inspectedObject.saveDelegate().isModified()
                    h = waitbar(0.5, ['Saving ' class(inspectedObject.saveDelegate()) '...'], 'WindowStyle', 'modal');
                    [saved, errorMessage] = inspectedObject.save();
                    close(h);
                    if ~saved
                        waitfor(errordlg(['Could not save the changes to ' class(inspectedObject.saveDelegate()) ' ' inspectedObject.saveDelegate().name ':' char(10) char(10) errorMessage], ...
                                         'GENIE NAA Curation', 'modal'));
                    end
                end
            end
        end
        
        
        function showRoguesGallery(obj, ~, ~)  %#ok<INUSD>
            gallery = RoguesGallery();
            figure(gallery.mainWindow);
        end
        
        
        %% Tree control callbacks
        
        
        function nodes = expandPlateSet(obj, eventData)
            eventNode = eventData.getCurrentNode;
            if ~obj.plateSetsTree.isLoaded(eventNode)
                state = warning('off', 'MATLAB:uitree:DeprecatedFunction');
                warning('off', 'MATLAB:uitreenode:DeprecatedFunction');
                
                plateSet = eventNode.handle.UserData;
                for i = 1:length(plateSet.children)
                    nodes(i) = uitreenode('v0', plateSet.children{i}.name, plateSet.children{i}.name, plateSet.children{i}.icon(), isempty(plateSet.children{i}.children)); %#ok<AGROW>
                    nodes(i).UserData = plateSet.children{i}; %#ok<AGROW>
                end
                obj.plateSetsTree.add(eventNode, nodes);
                obj.plateSetsTree.setLoaded(eventNode, true);
                obj.plateSetsTree.reloadNode(eventNode);
                
                warning(state);
            end
        end
        
        
        function selectPlateSet(obj, ~)
            if ~obj.selectingObjectInTree
                selectedNodes = obj.plateSetsTree.getSelectedNodes();
                if length(selectedNodes) == 1
                    plateOrSet = selectedNodes(1).handle.UserData;
                    obj.inspectObject(plateOrSet);
                end
            end
        end
        
        
        function treeMouseMoved(obj, eventData)
            if isvalid(obj) && ~isempty(obj.mainWindow)
                try
                    x = eventData.getX;
                    y = eventData.getY;
                    jtree = eventData.getSource;
                    treePath = jtree.getPathForLocation(x, y);
                    if isempty(treePath)
                        tooltipStr = '';
                    else
                        % Set the tooltip string based on the hovered node
                        node = treePath.getLastPathComponent;
                        plateOrSet = get(node, 'UserData');
                        tooltipStr = plateOrSet.path;
                    end
                    set(jtree, 'ToolTipText', tooltipStr)
                    drawnow;
                catch ME
                    disp(getReport(ME));
                end
            end
        end
        
        
        function selectObjectInTree(obj, object)
            obj.selectingObjectInTree = true;
            
            if isempty(object)
                nodeToSelect = [];
            else
                ancestors = object.ancestors();
                ancestors = {object, ancestors{1:end-1}}; 
                curNode = obj.plateSetsTree.getRoot();
                
                while ~isempty(ancestors)
                    childCount = curNode.getChildCount();
                    nextNode = [];
                    for i = 1:childCount
                        childNode = curNode.getChildAt(i - 1);
                        if childNode.handle.UserData == ancestors{end}
                            nextNode = childNode;
                            break
                        end
                    end
                    
                    if isempty(nextNode)
                        nodeToSelect = curNode;
                        break;
                    else
                        curNode = nextNode;
                        nodeToSelect = nextNode;
                        
                        if length(ancestors) > 1
                            obj.plateSetsTree.expand(nextNode);
                            drawnow;
                        end
                    end
                    
                    ancestors(end) = [];
                end
                
            end
            
            obj.plateSetsTree.setSelectedNode(nodeToSelect);
            
            drawnow;
            
            obj.selectingObjectInTree = false;
        end
        
        
        %% Object inspection
        
        
        function i = inspectObject(obj, object, varargin)
            if ~isempty(obj.inspector)
                inspectedObject = obj.inspector.object;
                if ~isempty(inspectedObject) && inspectedObject.saveDelegate().isModified() && (isempty(object) || inspectedObject.saveDelegate() ~= object.saveDelegate())
                    % Prompt the user to save the changes or cancel.
                    choice = questdlg(['This ' class(inspectedObject.saveDelegate()) ' has been modified.'], ['Save ' class(inspectedObject.saveDelegate())], ...
                                      'Don''t Save', 'Save', 'Cancel', 'Save');
                    if strcmp(choice, 'Don''t Save')
                        % Allow the UI to be cleared, but the data changes will persist...
                    elseif strcmp(choice, 'Save')
                        if ~obj.saveCurrentObject()
                            i = false;
                            return;
                        end
                    elseif strcmp(choice, 'Cancel')
                        i = false;
                        
                        % Re-select the original item (or its nearest ancestor) in the tree view.
                        obj.selectObjectInTree(inspectedObject);
                        
                        return;
                    end
                end
                
                % Clear and hide the current inspector.
                if ~obj.inspector.inspectObject([])
                    i = false;
                    return
                end
                set(obj.inspector.panel, 'Visible', 'off');
                set(obj.inspectionTitle, 'String', '');
            end
            
            if isempty(object)
                obj.inspector = [];
                obj.plateSetsTree;
            else
                if isa(object, 'PlateSet')
                    obj.inspector = obj.plateSetInspector;
                elseif isa(object, 'Plate')
                    obj.inspector = obj.plateInspector;
                elseif isa(object, 'Well')
                    obj.inspector = obj.wellInspector;
                else
                    error('Don''t know how to inspect %s objects', class(object));
                end
                
                % Load the object into the inspector and make it visible.
                try
                    obj.inspector.inspectObject(object, varargin{:});
                    obj.windowWasResized();
                    set(obj.inspector.panel, 'Visible', 'on');
                catch ME
                    % The inspector failed to load the object, clear it out.
                    obj.inspector.inspectObject([]);
                    obj.inspector = [];
                    errordlg(sprintf('The %s could not be loaded.\n\n(%s)', class(object), ME.message), 'NAA Curation', 'modal');
                    disp(getReport(ME));
                end
            end
            
            obj.selectObjectInTree(object);
            
            i = true;
        end
        
        
        %% 
        % TODO: override getdisp(H) instead.
%         function disp(obj)
%             disp('NAA curation interface');
%         end
%         
%         function display(obj)
%             display('NAA curation interface');
%         end
        
        
        %%
        
        
        function loadAllWells(obj, dataFilter)
            if nargin < 2
                dataFilter.protocol = [];
            end
            
            h = waitbar(0, 'Loading well data...', 'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)', 'vis', 'off', 'WindowStyle', 'modal');
            
            % Center the waitbar over the current window
            mainWindowPos = get(gcf, 'Position');
            centerPos = [mainWindowPos(1) + mainWindowPos(3) / 2, mainWindowPos(2) + mainWindowPos(4) / 2];
            hPos = get(h, 'Position');
            set(h, 'Position', [centerPos(1) - hPos(3) / 2, centerPos(2) - hPos(4) / 2, hPos(3), hPos(4)]);
            set(h, 'Visible', 'on');
            drawnow
            
            if isfield(dataFilter, 'minImagingDate')
                weekSets = obj.plateSetsRoot.children;
            elseif isfield(dataFilter, 'plateSet')
                if dataFilter.plateSet.parent == obj.plateSetsRoot
                    weekSets = {dataFilter.plateSet};
                else
                    weekSets = {dataFilter.plateSet.parent};
                end
            else
                weekSets = obj.plateSetsRoot.children;
            end
            numWeeks = length(weekSets);
            setappdata(h, 'canceling', false);
            startTime = now;
            platesLoaded = 0;
            for i = 1:numWeeks
                if getappdata(h, 'canceling')
                    break
                end
                
                for j = 1:length(weekSets{i}.children)
                    if getappdata(h, 'canceling')
                        break
                    end
                    protocolSet = weekSets{i}.children{j};
                    if ~isempty(protocolSet.children) && (isempty(dataFilter.protocol) || protocolSet.children{1}.protocol == dataFilter.protocol)
                        for k = 1:length(protocolSet.children)
                            if getappdata(h, 'canceling')
                                break
                            end
                            protocolSet.children{k}.wells; % make sure the non-imagery data for the plate's wells is loaded
                            platesLoaded = platesLoaded + 1;
                        end
                    end
                end
                
                if platesLoaded > 10
                    rate = (i - 1) / (now - startTime) / 60 / 60 / 24;
                    secsRemaining = (numWeeks - i + 1) / rate;
                    waitbar(i / numWeeks, h, ['Gathering data... (' timeMessage(secsRemaining) ' remaining)']);
                else
                    waitbar(i / numWeeks, h);
                end
            end
            
            delete(h);
        end
        
        
        %% 'Data all' generation
        
        
        function [dataFilter, pileMutants] = getDataFilter(obj, title)
            % TODO: allow the user to specify the start date
            % TODO: remember previous settings
            
            % Get the current selection of the tree.
            selectedPlateSet = [];
            selectedNodes = obj.plateSetsTree.getSelectedNodes();
            if length(selectedNodes) == 1
                plateOrSet = selectedNodes(1).handle.UserData;
                if isa(plateOrSet, 'PlateSet')
                    selectedPlateSet = plateOrSet;
                elseif isa(plateOrSet, 'Plate')
                    selectedPlateSet = plateOrSet.parent;
                end
            end
            
            dlg = dialog('Name', ['Create ' title ' file'], 'Position', [100 100 340 130]);
            
            % Center on the main window.
            mainWindowPos = get(obj.mainWindow, 'Position');
            centerPos = [mainWindowPos(1) + mainWindowPos(3) / 2, mainWindowPos(2) + mainWindowPos(4) / 2];
            dlgPos = get(dlg, 'Position');
            set(dlg, 'Position', [centerPos(1) - dlgPos(3) / 2, centerPos(2) - dlgPos(4) / 2, dlgPos(3), dlgPos(4)]);
            
            protocols = Protocol.all();
            protInd = find(protocols == Protocol('GCaMP'));
            uicontrol(dlg, ...
                'Style', 'text', ...
                'Position', [10 100 75 20], ...
                'FontSize', 14, ...
                'String', 'Protocol:');
            popup = uicontrol(dlg, ...
                'Style', 'popup', ...
                'Position', [90 100 150 22], ...
                'FontSize', 14, ...
                'String', {protocols.name}, ...
                'Value', protInd);
            if nargout > 1
                pileAllCheckbox = uicontrol(dlg, ...
                    'Style', 'checkbox', ...
                    'Position', [10 70 200 20], ...
                    'FontSize', 14, ...
                    'String', 'Create pile_all_upto file', ...
                    'Value', 0);
            end
            plateSetCheckbox = uicontrol(dlg, ...
                'Style', 'checkbox', ...
                'Position', [10 40 330 20], ...
                'FontSize', 14, ...
                'String', 'Only include wells for the selected set of plates', ...
                'Value', 0);
            if isempty(selectedPlateSet)
                set(plateSetCheckbox, 'Enable', 'off');
            end
            
            uicontrol(dlg, ...
                'Style', 'pushbutton', ...
                'Position', [150 10 70 20], ...
                'FontSize', 14, ...
                'String', 'Cancel', ...
                'Callback', 'setappdata(gcbf, ''cancel'', 1); uiresume(gcbf)');
            uicontrol(dlg, ...
                'Style', 'pushbutton', ...
                'Position', [250 10 70 20], ...
                'FontSize', 14, ...
                'String', 'OK', ...
                'Callback', 'setappdata(gcbf, ''cancel'', 0); uiresume(gcbf)');
            
            uiwait(dlg);
            
            if getappdata(dlg, 'cancel')
                dataFilter = [];
                if nargout > 1
                    pileMutants = [];
                end
            else
                protInd = get(popup, 'Value');
                dataFilter.protocol = protocols(protInd);
                if get(plateSetCheckbox, 'Value')
                    dataFilter.plateSet = selectedPlateSet;
                else
%                     if strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')
%                         dataFilter.minImagingDate = '20150823';
%                     else
                        % Cutoff date chosen by Doug.
                        
                        %dataFilter.minImagingDate = '20130101';
                        dataFilter.minImagingDate = '20150823'; %modified by Hod 20160509 for including good cultured cells data only
%                         dataFilter.minImagingDate = '20161001'; %modified by Hod 20161027 for comparing GCaMP96z after chaning control position

                        
                        %modified by Hod 20140910 for combos picking
                        
                        %                     dataFilter.minImagingDate = '20140815';
%                     end
                end
                if nargout > 1
                    pileMutants = get(pileAllCheckbox, 'Value');
                end
            end
            
            close(dlg);
        end
        
        
        function createDataAllFile(obj, ~, ~)
            % Make sure the current object is saved.
            if ~isempty(obj.inspector)
                inspectedObject = obj.inspector.object;
                if ~isempty(inspectedObject) && inspectedObject.saveDelegate().isModified()
                    % Prompt the user to save the changes or cancel.
                    objectClass = class(inspectedObject.saveDelegate());
                    choice = questdlg(['This ' class(inspectedObject.saveDelegate()) ' has been modified.'], ['Save ' objectClass], ...
                                      'Save', 'Cancel', 'Save');
                    if strcmp(choice, 'Save')
                        if ~obj.saveCurrentObject()
                            warndlg(['The ' objectClass ' could not be saved.'], 'GENIE NAA Curation', 'modal');
                            return;
                        end
                    else
                        return;
                    end
                end
            end
            
            [dataFilter, createPileAllUpTo] = obj.getDataFilter('data_all');
            if isempty(dataFilter)
                return
            end
            numPulses = length(dataFilter.protocol.nAP);
            
            % Import what we need from the POI jars so we can create the .xlsx file.
            import org.apache.poi.ss.usermodel.*;
            import org.apache.poi.xssf.usermodel.*;
            
            % Initially create the text files in /tmp and then move to the GENIE share once they are complete.
            % That way we don't leave half completed/errored out files on the share.
            % The xlsx file gets written out in one call at the end of this method.
            if isfield(dataFilter, 'minImagingDate')
                dateStamp = datestr(now, 'yyyymmdd');
                dataAllName = sprintf('data_all_%s_%s', dateStamp, dataFilter.protocol.name);
                pileUpToName = sprintf('pile_all_%s_upto_%s.mat', dataFilter.protocol.name, dateStamp);
            elseif isfield(dataFilter, 'plateSet')
                if dataFilter.plateSet.parent == obj.plateSetsRoot
                    dateStamp = dataFilter.plateSet.name;
                else
                    dateStamp = dataFilter.plateSet.parent.name;
                end
                dataAllName = sprintf('data_week_%s_%s', dateStamp, dataFilter.protocol.name);
                pileUpToName = sprintf('pile_week_%s_upto_%s.mat', dataFilter.protocol.name, dateStamp);
            end
            dataAllTempName = tempname;
            fid = fopen([dataAllTempName '_data_all.txt'], 'w');
            wellsFid = fopen([dataAllTempName '_data_all_wells.txt'], 'w');
            obj.dataAllWB = org.apache.poi.xssf.usermodel.XSSFWorkbook();
            obj.dataAllCellStyles = {};
            sheet = obj.dataAllWB.createSheet('data_all');
            sheet.createFreezePane(1, 1);
            
            % Look up the control construct.
            obj.loadAllWells(dataFilter);
            control = dataFilter.protocol.controlConstruct;
            controlPile = [];
            controlCount = length(control.passedWells(dataFilter));
            
            h = waitbar(0, 'Analyzing data...', 'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)', 'vis', 'off', 'WindowStyle', 'modal');
                
            % Center the waitbar over the main window
            mainWindowPos = get(obj.mainWindow, 'Position');
            centerPos = [mainWindowPos(1) + mainWindowPos(3) / 2, mainWindowPos(2) + mainWindowPos(4) / 2];
            hPos = get(h, 'Position');
            set(h, 'Position', [centerPos(1) - hPos(3) / 2, centerPos(2) - hPos(4) / 2, hPos(3), hPos(4)]);
            set(h, 'Visible', 'on');
            drawnow
            
            try
                % Get the control construct and cache some of its values for performance.
                % TODO: more than one control?
                errorMessage = '';
                if controlCount == 0
                    error('No valid %s data is available for the ''%s'' control.', dataFilter.protocol.name, control.name);
                else
                    if isfield(dataFilter, 'minImagingDate')
                        adequateControls = controlCount > 6;
                    elseif isfield(dataFilter, 'plateSet')
                        adequateControls = controlCount > 3;
                    end
                    
                    if adequateControls
                        controlResponses = cell(1, numPulses);
                        controlDecays = cell(1, numPulses);
                        controlRises = cell(1, numPulses);
                        for j = 1:numPulses
                            controlResponses{j} = control.responses(j, dataFilter);
                            
                            decays = control.decays(j, dataFilter);
                            controlDecays{j} = decays(~isnan(decays) & (decays ~= 0));
                            
                            rises = control.rises(j, dataFilter);
                            controlRises{j} = rises(~isnan(rises) & (rises ~= 0));
                            
                            timetopeak = control.timetopeak(j, dataFilter);
                            controlTTP{j} = timetopeak(~isnan(timetopeak) & (timetopeak ~= 0));
                        end
                        
                        passedWells = control.passedWells(dataFilter);
                        if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')%SNR added 20140408 Hod, RCaMP96z on 20161130, GCaMP96bf on 20170310
                            % snr and dprime data added Hod 20131123
                            fm=[];
                            for k=1:controlCount
                                
                                well = passedWells(k);
%                                 bg=myprctile(well.baseImage,2);  %HD 20140603, estimation of image background
%                                 fmean_bgremoved_estimation=well.fMean-bg;
%                                 well.fMean=fmean_bgremoved_estimation;

%                                 fm{end + 1} = fmean_bgremoved_estimation;
                                    fm{end + 1} =well.fMean;
                            end
                            type=dataAllName(end-1:end);
                            [controlDprime, controlSNR] = control.dprimeAndSNR(fm,type);
                            clear fm
                        end
                        
                        [controlDates, controlBrightness] = control.brightness(dataFilter);
                        controlDeltaFmaxF0 = []; % control.deltaFmaxF0(dataFilter);
                    end
                
                    % Header
                    headerStyle = obj.dataAllWB.createCellStyle();
                    headerStyle.setAlignment(CellStyle.ALIGN_CENTER);
                    p001DownFont = obj.dataAllWB.createFont();
                    p001DownFont.setBoldweight(Font.BOLDWEIGHT_BOLD);
                    headerStyle.setFont(p001DownFont);
                    headerRow = sheet.createRow(0);
                    fprintf(fid, 'construct\treplicate_number\tvariant_type\tfirst_assay_date\tlast_assay_date\t');
                    headerRow.createCell(0).setCellValue('Construct');
                    headerRow.createCell(1).setCellValue('# Replicates');
                    headerRow.createCell(2).setCellValue('First Assay Date');
                    headerRow.createCell(3).setCellValue('Last Assay Date');
                    colNum = 4;
                    for j = 1:numPulses
                        fprintf(fid, '%d_fp\t', dataFilter.protocol.nAP(j));
                        headerRow.createCell(colNum).setCellValue(sprintf('%dFP', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                    end
                    colNum = colNum + 1;
                    for j = 1:numPulses
                        fprintf(fid, 'rise_%d_fp\t', dataFilter.protocol.nAP(j));
                        headerRow.createCell(colNum).setCellValue(sprintf('Rise (%dFP)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                    end
                    colNum = colNum + 1;
                    for j = 1:numPulses
                        fprintf(fid, 'timetopeak_%d_fp\t', dataFilter.protocol.nAP(j));
                        headerRow.createCell(colNum).setCellValue(sprintf('TimeToPeak (%dFP)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                    end
                    colNum = colNum + 1;
                    for j = 1:numPulses
                        fprintf(fid, 'decay_%d_fp\t', dataFilter.protocol.nAP(j));
                        headerRow.createCell(colNum).setCellValue(sprintf('Decay (%dFP)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                    end
                    colNum = colNum + 1;
                    
                    if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96') ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')...
                            ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')||...
                            strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')...
                            ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')%modified Hod 20140119, and add OGB1 SNR 20140408, RCaMP96z 20161130. u and uf 20170727
                        for j = 1:numPulses
                            fprintf(fid, 'dprime_%d_fp\t', dataFilter.protocol.nAP(j));
                            headerRow.createCell(colNum).setCellValue(sprintf('dprime (%dFP)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                        end
                        for j = 1:numPulses
                            fprintf(fid, 'snr_%d_fp\t', dataFilter.protocol.nAP(j));
                            headerRow.createCell(colNum).setCellValue(sprintf('SNR (%dFP)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                        end
                        colNum = colNum + 1;
                    end
                    
                    if adequateControls
                        if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b') || strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')%modified Hod 20140119, OGB1 added 20140408
                            fprintf(fid, 'es50\t');
                            headerRow.createCell(colNum).setCellValue('ES50'); colNum = colNum + 1;
                        end
                        fprintf(fid, 'norm_f0\td_fmax_f0\t');
                        headerRow.createCell(colNum).setCellValue('Norm. F0'); colNum = colNum + 1;
                        headerRow.createCell(colNum).setCellValue('dFmax/F0'); colNum = colNum + 1;
                        colNum = colNum + 1;
                        for j = 1:numPulses
                            fprintf(fid, '%d_fp_p\t', dataFilter.protocol.nAP(j));
                            headerRow.createCell(colNum).setCellValue(sprintf('%dFP(p)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                        end
                        colNum = colNum + 1;
                        for j = 1:numPulses %Hod 20131123 - correcting missing header
                            fprintf(fid, 'rise_%d_fp_p\t', dataFilter.protocol.nAP(j));
                            headerRow.createCell(colNum).setCellValue(sprintf('Rise (%dFP)(p)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                        end
                        colNum = colNum + 1;
                        for j = 1:numPulses %Hod 20131123 - correcting missing header
                            fprintf(fid, 'timetopeak_%d_fp_p\t', dataFilter.protocol.nAP(j));
                            headerRow.createCell(colNum).setCellValue(sprintf('TimeToPeak (%dFP)(p)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                        end
                        
                        colNum = colNum + 1;
                        for j = 1:numPulses
                            fprintf(fid, 'decay_%d_fp_p\t', dataFilter.protocol.nAP(j));
                            headerRow.createCell(colNum).setCellValue(sprintf('Decay (%dFP)(p)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                        end
                        colNum = colNum + 1;
                        if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')...
                                ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')%modified Hod 20140119
                            %                         fprintf(fid, 'dprime_p\t'); %Hod 20131123 - adding dprime and SNR data
                            %                         headerRow.createCell(colNum).setCellValue('d-Prime(p)'); colNum = colNum + 1;
                            for j = 1:numPulses
                                fprintf(fid, 'dprime_%d_fp_p\t', dataFilter.protocol.nAP(j));
                                headerRow.createCell(colNum).setCellValue(sprintf('dprime (%dFP)(p)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                            end
                            for j = 1:numPulses
                                fprintf(fid, 'snr_%d_fp_p\t', dataFilter.protocol.nAP(j));
                                headerRow.createCell(colNum).setCellValue(sprintf('SNR (%dFP)(p)', dataFilter.protocol.nAP(j))); colNum = colNum + 1;
                            end
                            colNum = colNum + 1;
                        end
                        fprintf(fid, 'norm_f0_p\td_fmax_f0_p\n');
                        headerRow.createCell(colNum).setCellValue('Norm. F0(p)'); colNum = colNum + 1;
                        headerRow.createCell(colNum).setCellValue('dFmax/F0(p)');
                    else
                        fprintf(fid, 'f0\n');
                        headerRow.createCell(colNum).setCellValue('F0');
                    end
                    
                    % Get the list of constructs
                    constructs = Construct.all();
                    constructNames = {constructs.name};
                    
                    % Only use the constructs indicated by the protocol.
                    matches = false(1, length(constructs));
                    matches(strcmp(constructNames, dataFilter.protocol.controlConstruct.name)) = true; % TODO: multiple controls?
                    for filter = dataFilter.protocol.dataAllFilters
                        filterMatches = cellfun(@(m) ~isempty(m), regexp(constructNames, filter));
                        matches = matches | filterMatches;
                    end
                    constructs = constructs(matches);
                    constructNames = {constructs.name};
                    
                    % Sort by the construct name parts (e.g. '10.5' should come before '10.31')
                    parts = regexp(constructNames, '\.', 'split');
                    partsMat = zeros(length(parts), 2);
                    for i = 1:length(parts)
                        partsMat(i, 1) = str2double(parts{i}(1));
                        if length(parts{i}) > 1
                            partsMat(i, 2) = str2double(parts{i}(2));
                        end
                    end
                    [~, ind] = sortrows(partsMat);
                    constructs = constructs(ind);
                    
                    % Loop through each construct and add a row of data to the output files.
                    response = zeros(1, numPulses);
                    responsePValue = zeros(1, numPulses);
                    decay = zeros(1, numPulses);
                    decayPValue = zeros(1, numPulses);
                    wbRow = headerRow;
                    mutantPile = [];
                    for i = 1:length(constructs)
                        construct = constructs(i);
                        
                        if getappdata(h,'canceling')
                            break
                        end
                        
                        passedWells = construct.passedWells(dataFilter);
                        numReplicates = length(passedWells);
                        
                        if numReplicates > 0
                            wbRow = sheet.createRow(wbRow.getRowNum() + 1);
                            fprintf(fid, '%s\t%d\t%s\t%s\t', construct.name, numReplicates, dataFilter.protocol.name, construct.firstAssayDate(dataFilter), construct.lastAssayDate(dataFilter));
                            wbRow.createCell(0).setCellValue(construct.name);
                            wbRow.createCell(1).setCellValue(numReplicates);
                            wbRow.createCell(2).setCellValue(construct.firstAssayDate(dataFilter));
                            wbRow.createCell(3).setCellValue(construct.lastAssayDate(dataFilter));
                            mutantResponses = zeros(numPulses, numReplicates);
                            colNum = 4;
                            
                            % Add the responses
                            for j = 1:numPulses
                                mutantResponses(j, :) = construct.responses(j, dataFilter);
                                if adequateControls
                                    response(j) = median(mutantResponses(j, :)) / median(controlResponses{j});
                                else
                                    response(j) = median(mutantResponses(j, :));
                                end
                                fprintf(fid, '%f\t', response(j));
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(response(j));
                                if adequateControls
                                    [responsePValue(j), ~] = ranksum(controlResponses{j}, mutantResponses(j, :));
                                    wbCell.setCellStyle(obj.getCellStyle(responsePValue(j), response(j), true));
                                end
                            end
                            colNum = colNum + 1;
                          
                            % Add the rise times (not correctded for temprature)
                            ri = zeros(1, numPulses);
                            risePValue = zeros(1, numPulses);
                            for j = 1:numPulses
                                rises = construct.rises(j, dataFilter);
                                clear risesComp %%20151113 HD - check if helps for removing error message
                                risesComp(j,:) = rises; %#ok<AGROW> %added by Hod 20131018
                                nonNaNrises = rises(~isnan(rises)&(rises~=0)); 
                                if adequateControls
                                    ri(j) = median(nonNaNrises) / median(controlRises{j});
                                    if isempty(nonNaNrises)
                                        risePValue(j) = NaN;
                                    else
                                        risePValue(j) = ranksum(controlRises{j}, nonNaNrises);
                                    end
                                else
                                    ri(j) = median(nonNaNrises);
                                end
                                fprintf(fid, '%f\t', ri(j));
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(ri(j));
                                if adequateControls
                                    wbCell.setCellStyle(obj.getCellStyle(risePValue(j), ri(j), true));
                                end
                            end
                            colNum = colNum + 1;
                            
                            % Add times to peak (TTP, full rise times)
                            ttp = zeros(1, numPulses);
                            timeToPeakPValue = zeros(1, numPulses);
                            for j = 1:numPulses
                                timetopeak = construct.timetopeak(j, dataFilter);
                                clear ttpComp %%20151113 HD - check if helps for removing error message
                                ttpComp(j,:) = timetopeak; %#ok<AGROW> %added by Hod 20131018
                                nonNaNTTP = timetopeak(~isnan(timetopeak)&(timetopeak~=0)); 
                                if adequateControls
                                    ttp(j) = median(nonNaNTTP) / median(controlTTP{j});
                                    if isempty(nonNaNTTP)
                                        timeToPeakPValue(j) = NaN;
                                    else
                                        timeToPeakPValue(j) = ranksum(controlTTP{j}, nonNaNTTP);
                                    end
                                else
                                    ttp(j) = median(nonNaNTTP);
                                end
                                fprintf(fid, '%f\t', ttp(j));
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(ttp(j));
                                if adequateControls
                                    wbCell.setCellStyle(obj.getCellStyle(timeToPeakPValue(j), ttp(j), true));
                                end
                            end
                            colNum = colNum + 1;
                            
                            % Add the decays
                            for j = 1:numPulses
                                decays = construct.decays(j, dataFilter);
                                clear decaysComp %HD 20151113 - patch from removing error message
                                decaysComp(j,:) = decays; %#ok<AGROW> %added by Hod 20130924 - saving correctly the compensated decay data
                                nonNaNdecays = decays(~isnan(decays) & (decays ~= 0));
                                if adequateControls
                                    decay(j) = median(nonNaNdecays) / median(controlDecays{j});
                                    if isempty(nonNaNdecays)
                                        decayPValue(j) = NaN;
                                    else
                                        decayPValue(j) = ranksum(controlDecays{j}, nonNaNdecays);
                                    end
                                else
                                    decay(j) = median(nonNaNdecays);
                                end
                                fprintf(fid, '%f\t', decay(j));
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(decay(j));
                                if adequateControls
                                    wbCell.setCellStyle(obj.getCellStyle(decayPValue(j), decay(j), true));
                                end
                            end
                            colNum = colNum + 1;
                            
                            %Hod 20131123 add dprime and SNR data
                            SNR = zeros(1,numPulses);
                            dprime = SNR;
                            SNRPValue = SNR;
                            dprimePvalue = SNRPValue;
                            if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')%modified Hod 20140119, add OGB1 SNR data 20140408
                                fm=[];
                                for j=1:numReplicates
                                    well = passedWells(j);
                                    bg=myprctile(well.baseImage,0.1);  %HD 20140603, estimation of image background
                                    fmean_bgremoved_estimation=well.fMean-bg;
                                    well.fMean=fmean_bgremoved_estimation;
                                    fm{end + 1} = fmean_bgremoved_estimation;
                                end
                                [constructDprime, constructSNR] = construct.dprimeAndSNR(fm, type); % IK modified 3/11/21 %construct.dprime(fm,type); %modified HD 20150728
                                for j = 1:numPulses
                                    dprime(j) = median(constructDprime(j,:)) / median(controlDprime(j,:)); % calc normalized dprime
                                    fprintf(fid, '%f\t', dprime(j));
                                    wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                    wbCell.setCellValue(dprime(j));
                                    dprimePvalue(j)=ranksum(controlDprime(j,:),constructDprime(j,:));
                                end
                                for j = 1:numPulses
                                    SNR(j) = median(constructSNR(j,:)) / median(controlSNR(j,:)); % calc normalized SNR
                                    fprintf(fid, '%f\t', SNR(j));
                                    wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                    wbCell.setCellValue(SNR(j));
                                    SNRPValue(j)=ranksum(controlSNR(j,:),constructSNR(j,:));
                                    % wbCell.setCellStyle(obj.getCellStyle(SNRPValue(j), median(SNR(j,:)), true));
                                end
                                colNum = colNum + 1;
                            end
                            %end of addition
                            
                            %addition of es50 - hod 20140119
                            if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')...
                                    ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')%modified Hod 20140119, OGB1 added 20140408
                                resp=median(mutantResponses(:, :),2);
                                nAP=[1 3 10 160];
                                [nAP,ind]=sort(nAP);
                                resp=resp(ind);
                                [M,idx]=max(resp);
                                resp=resp/M;
                                ind=find(resp(1:idx)<0.5);
                                if isempty(ind)
                                    ind=1;
                                end
                                ind=ind(end);
                                %% cancel NaN values - added by Hod 09Apr2013
                                if isnan(resp(ind:(ind+1)))
                                    es50=0;
                                else
                                    es50=interp1(resp(ind:(ind+1)),nAP(ind:(ind+1)),0.5,'linear');
                                end
                                fprintf(fid, '%f\t', es50);
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(es50);
                            elseif strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')
                                resp=median(mutantResponses(:, :),2);
                                nAP=[1 2 3 5 10 20 40 80 160];
                                [nAP,ind]=sort(nAP);
                                resp=resp(ind);
                                [M,idx]=max(resp);
                                resp=resp/M;
                                ind=find(resp(1:idx)<0.5);
                                if isempty(ind)
                                    ind=1;
                                end
                                ind=ind(end);
                                %% cancel NaN values - added by Hod 09Apr2013
                                if isnan(resp(ind:(ind+1)))
                                    es50=0;
                                else
                                    es50=interp1(resp(ind:(ind+1)),nAP(ind:(ind+1)),0.5,'linear');
                                end
                                fprintf(fid, '%f\t', es50);
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(es50);
                            end
                            %end of addition
                            
                            % Add Norm. F0/F0 and Fmax
                            if adequateControls
                                [brightness, nControlBrightness, dates] = construct.normalizedBrightness(controlDates, controlBrightness, dataFilter);
                                normF0 = median(brightness) / median(nControlBrightness);
                                if isempty(brightness)
                                    normF0PValue = NaN;
                                else
                                    normF0PValue = ranksum(nControlBrightness, brightness);
                                end
                                deltaFmaxF0 = []; %construct.deltaFmaxF0(dataFilter);
                                normDeltaFmaxF0 = nan; % median(deltaFmaxF0) / median(controlDeltaFmaxF0);
                                if isempty(deltaFmaxF0) || isempty(controlDeltaFmaxF0)
                                    deltaFmaxF0PValue = NaN;
                                else
                                    deltaFmaxF0PValue = ranksum(controlDeltaFmaxF0, deltaFmaxF0);
                                end
                                
                                fprintf(fid, '%f\t%f\t', normF0, normDeltaFmaxF0);
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(normF0);
                                wbCell.setCellStyle(obj.getCellStyle(normF0PValue, normF0, false)); % TODO: is this on purpose?
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(normDeltaFmaxF0);
                                wbCell.setCellStyle(obj.getCellStyle(deltaFmaxF0PValue, normDeltaFmaxF0, false)); % TODO: is this on purpose?
                            else
                                [dates, brightness] = construct.brightness(dataFilter);
                                f0 = median(brightness);
                                
                                fprintf(fid, '%f\n', f0);
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(f0);
                            end
                            colNum = colNum + 1;
                            
                            if adequateControls
                                % Add all of the p-values.
                                
                                for j = 1:numPulses
                                    fprintf(fid, '%.9f\t', responsePValue(j));
                                    wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                    wbCell.setCellValue(responsePValue(j));
                                    wbCell.setCellStyle(obj.getCellStyle(responsePValue(j), response(j), false));
                                end
                                colNum = colNum + 1;
                                
                                % add rise time p vlues - Hod 20131018
                                for j = 1:numPulses
                                    fprintf(fid, '%.9f\t', risePValue(j));
                                    wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                    wbCell.setCellValue(risePValue(j));
                                    wbCell.setCellStyle(obj.getCellStyle(risePValue(j), ri(j), false));
                                end
                                colNum = colNum + 1;
                                
                                % add time-to-peak p vlues
                                for j = 1:numPulses
                                    fprintf(fid, '%.9f\t', timeToPeakPValue(j));
                                    wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                    wbCell.setCellValue(timeToPeakPValue(j));
                                    wbCell.setCellStyle(obj.getCellStyle(timeToPeakPValue(j), ttp(j), false));
                                end
                                colNum = colNum + 1;
                                for j = 1:numPulses
                                    fprintf(fid, '%.9f\t', decayPValue(j));
                                    wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                    wbCell.setCellValue(decayPValue(j));
                                    wbCell.setCellStyle(obj.getCellStyle(decayPValue(j), decay(j), false));
                                end
                                colNum = colNum + 1;
                                
                                % add SNR p values
                                % Hod 20131123
                                if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')%modified Hod 20140119, added OGB1 SNR 20140408
                                    for j = 1:numPulses
                                        fprintf(fid, '%.9f\t', dprimePvalue(j));
                                        wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                        wbCell.setCellValue(dprimePvalue(j));
                                    end
                                    for j = 1:numPulses
                                        fprintf(fid, '%.9f\t', SNRPValue(j));
                                        wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                        wbCell.setCellValue(SNRPValue(j));
                                        % wbCell.setCellStyle(obj.getCellStyle(SNRPValue(j), median(SNR(j,:)), false));
                                    end
                                    colNum = colNum + 1;
                                    %end of addition
                                end
                                
                                fprintf(fid, '%.9f\t%.9f\n', normF0PValue, deltaFmaxF0PValue);
                                wbCell = wbRow.createCell(colNum); colNum = colNum + 1;
                                wbCell.setCellValue(normF0PValue);
                                wbCell.setCellStyle(obj.getCellStyle(normF0PValue, normF0, false));
                                wbCell = wbRow.createCell(colNum);
                                wbCell.setCellValue(deltaFmaxF0PValue);
                                wbCell.setCellStyle(obj.getCellStyle(deltaFmaxF0PValue, normDeltaFmaxF0, false));
                            end
                            
                            if createPileAllUpTo
                                mutantPile(end + 1).construct = construct.name; %#ok<AGROW>
                                mutantPile(end).fullname = construct.name;
                                mutantPile(end).nreplicate = numReplicates;
                                mutantPile(end).df_fpeak_med = [];
                                mutantPile(end).decay_half_med = [];
                                mutantPile(end).decay_half_mean = [];
                                mutantPile(end).rise_half_med = [];
                                mutantPile(end).timetopeak_med = [];
                                mutantPile(end).temperature = [];
                                mutantPile(end).decay_half_med_comp = decaysComp;  clear decaysComp; %modified by Hod 20130924
                                mutantPile(end).rise_half_med_comp = risesComp;  clear risesComp; %modified by Hod 20131018
                                mutantPile(end).f0 = [];
                                mutantPile(end).plate = [];
                                mutantPile(end).well = [];
                                mutantPile(end).date = [];
                                mutantPile(end).mCherry = [];
                                mutantPile(end).nSegment = [];
                                mutantPile(end).fmean = {};
                                mutantPile(end).fmean_med = [];
                                mutantPile(end).fmax_med = [];
                                mutantPile(end).df_f_med = [];
                                mutantPile(end).df_fpeak_med_comp = mutantResponses;
                                mutantPile(end).df_fnoise = [];
                                mutantPile(end).es50 = []; %added by Hod 20140119
                                if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')%modified Hod 20140119, OGB1 added 20140408
                                    mutantPile(end).SNR=[];
                                    mutantPile(end).SNR_med=[];
                                end
                                for j = 1:numReplicates
                                    well = passedWells(j);
                                    
                                    % Add to the _wells file.
                                    parts = regexp(well.plate.name, '-', 'split');
                                    fprintf(wellsFid, '%s\t%s-%s\t%s\n', well.construct.name, parts{1}, well.assayDate, well.name);
                                    
                                    % Add to mutant pile.
                                    mutantPile(end).df_fpeak_med = horzcat(mutantPile(end).df_fpeak_med, well.summary.df_fpeak_med);
                                    mutantPile(end).decay_half_med = horzcat(mutantPile(end).decay_half_med, well.summary.decay_half_med);
                                    mutantPile(end).decay_half_mean = horzcat(mutantPile(end).decay_half_mean, well.summary.decay_half);
                                    mutantPile(end).rise_half_med = horzcat(mutantPile(end).rise_half_med, well.summary.rise_half_med);
                                    mutantPile(end).timetopeak_med = horzcat(mutantPile(end).timetopeak_med, well.summary.timetopeak_med);
                                    mutantPile(end).temperature(j, 1) = well.temperature();
                                    % mutantPile(end).decay_half_med_comp(:,j) = median(decays_comp,2); 
                                    mutantPile(end).f0(j) = mean([well.summary.f0]);
                                    mutantPile(end).plate{j} = well.plate.name;
                                    mutantPile(end).well{j} = well.name;
                                    mutantPile(end).date{j} = dates{j};
                                    mutantPile(end).mCherry(j) = mean([well.cellList.mCherry]);
                                    mutantPile(end).nSegment(j) = length(well.cellList);

                                    if isempty(well.fMean)
                                        warning('GENIE:MissingData:FMean', 'Well %s has an empty fMean.', well.name);
                                    else
                                        mutantPile(end).fmean{end + 1} = well.fMean;
                                        mutantPile(end).fmean_med = cat(3, mutantPile(end).fmean_med, squeeze(median(well.fMean, 3)));
                                    end
                                    mutantPile(end).fmax_med(j) = median(well.fMax);
                                    if isempty(well.paraArray)
                                        warning('GENIE:MissingData:ParaArray', 'Well %s has an empty paraArray.', well.name);
                                    else
                                        df_f = [well.paraArray.df_f];
                                        df_f = reshape(df_f, size(df_f, 1), numPulses, []);
                                        mutantPile(end).df_f_med = cat(3, mutantPile(end).df_f_med, median(df_f, 3));
                                        df_fnoise = mean(squeeze(std(df_f(1:25, :, :))), 2);
                                        try
                                            mutantPile(end).df_fnoise = horzcat(mutantPile(end).df_fnoise, df_fnoise);
                                        catch ME
                                            warning('GENIE:MissingData:DFFNoise', 'Not adding well %s to the mutant pile because of a df_fnoise size mismatch. (%s)', well.name, ME.message);
                                            %delete(h);
                                            %rethrow(ME);
                                        end
                                    end
                                end
                                
                                % dprime analysis and SNR, Hod 20131123,
                                % dprime for 1-FP added 20140603 HD
                                if strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96b')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96b-ERtag')||strcmp(passedWells(1,1).parent.protocol.name,'OGB1')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96c')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96z')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96bf')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96c')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96d')...
                                        ||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'GCaMP96uf')||strcmp(passedWells(1,1).parent.protocol.name,'mngGECO')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96u')||strcmp(passedWells(1,1).parent.protocol.name,'RCaMP96uf')%modified Hod 20140119, OGB1 SNR added 20140408
                                    [dprime,SNR]= construct.dprimeAndSNR(mutantPile(end).fmean,type); % IK modified 3/11/21 % construct.dprime(mutantPile(end).fmean,type);
                                    
                                    mutantPile(end).dprime=dprime;
                                    mutantPile(end).SNR=SNR;
                                    mutantPile(end).SNR_med=median(SNR,2);
                                    mutantPile(end).es50=es50; %added by Hod 20140119
                                end
                                
                                if strcmp(mutantPile(end).construct, control.name)
                                    controlPile = mutantPile(end);
                                end
                            end
                        end
                        
                        waitbar(i / length(constructs), h);
                    end
                    
                    for i = 1:wbRow.getLastCellNum()
                        wbCell = headerRow.getCell(i - 1);
                        if ~isempty(wbCell)
                            wbCell.setCellStyle(headerStyle);
                        end
                        sheet.autoSizeColumn(i - 1);
                    end
                end
            catch ME
                disp(getReport(ME));
                errorMessage = ME.message;
            end
            
            delete(h);
            fclose(fid);
            fclose(wellsFid);
            
            if isempty(errorMessage)
                resultsDir = fullfile(obj.pipelinePaths.primary, 'Analysis');
                
                % Move the text files to their final location
                movefile([dataAllTempName '_data_all.txt'], fullfile(resultsDir, [dataAllName '.txt']));
                movefile([dataAllTempName '_data_all_wells.txt'], fullfile(resultsDir, [dataAllName '_wells.txt']));
                
                % Save the spreadsheet version of the file.
                % IK 20201212 commented out below b/c it's throwing errors
                fileStream = java.io.FileOutputStream(fullfile(resultsDir, [dataAllName '.xlsx']));
                obj.dataAllWB.write(fileStream);
                fileStream.close();
                
                if createPileAllUpTo && ~isempty(controlPile)
                    pile.control = controlPile;
                    pile.mutant = mutantPile; %#ok<STRNU>
                    save(fullfile(resultsDir, pileUpToName), '-struct', 'pile', '-v7.3');  %make sure large data set is saved
                end
            else
                errordlg(['An error occurred while creating the data_all file.' char(10) char(10) errorMessage], 'NAA Curation', 'modal');
                
                % Get rid of the temp files.
                delete([dataAllTempName '_data_all.txt'], [dataAllTempName '_data_all_wells.txt']);
            end
            
            % Clear the cell styles since they are tied to the workbook.
            obj.dataAllCellStyles = {};
        end
        
        
        function style = getCellStyle(obj, pValue, value, isValue)
            import org.apache.poi.xssf.usermodel.*;
            
            if isempty(obj.dataAllCellStyles)
                format = obj.dataAllWB.createDataFormat();
                
                % Create the fonts
                % IK 20201212 commenting out setColor because it's throwing
                % errors
                font = cell(7, 1);
                font{1} = obj.dataAllWB.createFont();
                % font{1}.setColor(XSSFColor([255 0 0]));     % bright red
                font{2} = obj.dataAllWB.createFont();
                % font{2}.setColor(XSSFColor([0 0 255]));     % bright blue
                font{3} = obj.dataAllWB.createFont();
                % font{3}.setColor(XSSFColor([255 96 0]));    % medium orange
                font{4} = obj.dataAllWB.createFont();
                % font{4}.setColor(XSSFColor([0 96 255]));    % medium blue
                font{5} = obj.dataAllWB.createFont();
                % font{5}.setColor(XSSFColor([255 192 0]));   % light orange
                font{6} = obj.dataAllWB.createFont();
                % font{6}.setColor(XSSFColor([0 192 255]));   % light blue
                font{7} = obj.dataAllWB.createFont();       % default is black
                
                % Create styles for indicating p-values.
                obj.dataAllCellStyles = cell(7, 2);
                for i = 1:7
                    obj.dataAllCellStyles{i, 1} = obj.dataAllWB.createCellStyle();
                    obj.dataAllCellStyles{i, 1}.setFont(font{i});
                    obj.dataAllCellStyles{i, 1}.setDataFormat(format.getFormat('0.00'));
                    
                    obj.dataAllCellStyles{i, 2} = obj.dataAllWB.createCellStyle();
                    obj.dataAllCellStyles{i, 2}.setFont(font{i});
                    obj.dataAllCellStyles{i, 2}.setDataFormat(format.getFormat('0.000000000'));
                end
            end
            
            if pValue < 0.001
                if value > 1
                    row = 1;
                else
                    row = 2;
                end
            elseif pValue < 0.01
                if value > 1
                    row = 3;
                else
                    row = 4;
                end
            elseif pValue < 0.05
                if value > 1
                    row = 5;
                else
                    row = 6;
                end
            else
                row = 7;
            end
            
            if isValue
                col = 1;
            else
                col = 2;
            end
            
            style = obj.dataAllCellStyles{row, col};
        end
        
        
        function createFailedWells(obj, ~, ~)
            % Make sure the current object is saved.
            if ~isempty(obj.inspector)
                inspectedObject = obj.inspector.object;
                if ~isempty(inspectedObject) && inspectedObject.saveDelegate().isModified()
                    % Prompt the user to save the changes or cancel.
                    objectClass = class(inspectedObject.saveDelegate());
                    choice = questdlg(['This ' class(inspectedObject.saveDelegate()) ' has been modified.'], ['Save ' objectClass], ...
                                      'Save', 'Cancel', 'Save');
                    if strcmp(choice, 'Save')
                        if ~obj.saveCurrentObject()
                            warndlg(['The ' objectClass ' could not be saved.'], 'GENIE NAA Curation', 'modal');
                            return;
                        end
                    else
                        return;
                    end
                end
            end
            
            dataFilter = obj.getDataFilter('Failed Wells');
            if isempty(dataFilter)
                return
            end
            
            if isfield(dataFilter, 'minImagingDate')
                dateStamp = datestr(now, 'yyyymmdd');
                failedWellsName = sprintf('failed_wells_%s_%s', dateStamp, dataFilter.protocol.name);
            elseif isfield(dataFilter, 'plateSet')
                if dataFilter.plateSet.parent == obj.plateSetsRoot
                    dateStamp = dataFilter.plateSet.name;
                else
                    dateStamp = dataFilter.plateSet.parent.name;
                end
                failedWellsName = sprintf('failed_wells_%s_%s', dateStamp, dataFilter.protocol.name);
            end
            
            % Prompt the user for where to save the file.
            % TODO: always write to the GENIE share?
            fileName = [failedWellsName '.xlsx'];
            [fileName, parentDir] = uiputfile(fileName, 'Save the failed wells file to:');
            if ~ischar(fileName)
                return
            end
            failedWellsPath = fullfile(parentDir, fileName);
            
            obj.loadAllWells(dataFilter);
            
            % Import what we need from the POI jars so we can create the .xlsx file.
            import org.apache.poi.ss.usermodel.*;
            import org.apache.poi.xssf.usermodel.*;
            
            % Create the workbook, worksheets and their header rows.
            failuresWB = org.apache.poi.xssf.usermodel.XSSFWorkbook();
            constructSheet = failuresWB.createSheet('Constructs');
            constructSheet.createFreezePane(0, 1);
            headerRow = constructSheet.createRow(0);
            headerRow.createCell(0).setCellValue('Construct');
            headerRow.createCell(1).setCellValue('Failure Count');
            wellSheet = failuresWB.createSheet('Wells');
            wellSheet.createFreezePane(0, 1);
            headerRow = wellSheet.createRow(0);
            headerRow.createCell(0).setCellValue('Construct');
            headerRow.createCell(1).setCellValue('Assay Date');
            headerRow.createCell(2).setCellValue('Plate');
            headerRow.createCell(3).setCellValue('Well');
            headerRow.createCell(4).setCellValue('Failure Reason');
            
            % Get the list of constructs.
            constructs = Construct.all();
            constructNames = {constructs.name};

            % Only use the constructs indicated by the protocol.
            matches = false(1, length(constructs));
            matches(strcmp(constructNames, dataFilter.protocol.controlConstruct.name)) = true; % TODO: multiple controls?
            for filter = dataFilter.protocol.dataAllFilters
                filterMatches = cellfun(@(m) ~isempty(m), regexp(constructNames, filter));
                matches = matches | filterMatches;
            end
            constructs = constructs(matches);
            constructNames = {constructs.name};

            % Sort by the construct name parts (e.g. '10.5' should come before '10.31')
            parts = regexp(constructNames, '\.', 'split');
            partsMat = zeros(length(parts), 2);
            for i = 1:length(parts)
                partsMat(i, 1) = str2double(parts{i}(1));
                if length(parts{i}) > 1
                    partsMat(i, 2) = str2double(parts{i}(2));
                end
            end
            [~, ind] = sortrows(partsMat);
            constructs = constructs(ind);

            % Loop through each construct and add rows to the sheets.
            constructCount = 0;
            wellCount = 0;
            for i = 1:length(constructs)
                construct = constructs(i);
                failedWells = construct.failedWells(dataFilter);
                
                if ~isempty(failedWells)
                    constructRow = constructSheet.createRow(constructCount + 1);
                    constructRow.createCell(0).setCellValue(construct.name);
                    constructRow.createCell(1).setCellValue(length(failedWells));
                    constructCount = constructCount + 1;

                    for j = 1:length(failedWells)
                        well = failedWells(j);
                        wellRow = wellSheet.createRow(wellCount + 1);
                        wellRow.createCell(0).setCellValue(well.construct.name);
                        wellRow.createCell(1).setCellValue(well.assayDate);
                        wellRow.createCell(2).setCellValue(well.plate.name);
                        wellRow.createCell(3).setCellValue(well.name);
                        if isempty(well.failureReason)
                            wellRow.createCell(4).setCellValue('Other');
                        else
                            wellRow.createCell(4).setCellValue(well.failureReason.name);
                        end
                        wellCount = wellCount + 1;
                    end
                end
            end            
            
            % Bold the header cells and auto-size all of the columns.
            headerStyle = failuresWB.createCellStyle();
            headerStyle.setAlignment(CellStyle.ALIGN_CENTER);
            headerFont = failuresWB.createFont();
            headerFont.setBoldweight(Font.BOLDWEIGHT_BOLD);
            headerStyle.setFont(headerFont);
            for i = 0:1
                wbCell = constructSheet.getRow(0).getCell(i);
                wbCell.setCellStyle(headerStyle);
                constructSheet.autoSizeColumn(i);
            end
            for i = 0:4
                wbCell = wellSheet.getRow(0).getCell(i);
                wbCell.setCellStyle(headerStyle);
                wellSheet.autoSizeColumn(i);
            end
            
            fileStream = java.io.FileOutputStream(failedWellsPath);
            failuresWB.write(fileStream);
            fileStream.close();
        end
        
    end
    
end
