classdef PlateInspector < ObjectInspector
    
    properties (Constant)
        objectClass = 'Plate'
    end
    
    properties
        wellAxes
        wellLabels
        selectionAxes
        selectionRect
        
        selectedWells
        
        imageryLayer
        
        lastClickTime
        lastFailureReason
    end
    
    
    properties (Dependent)
        plate
    end
    
    
    methods
        
        function createInterface(obj)
            % Create an axes for drawing the selection for the current well.
            obj.selectionAxes = axes('Parent', obj.panel, ...
                                     'Units', 'normalized', ...
                                     'OuterPosition', [0 0 1 1], ...
                                     'Position', [0 0 1 1], ...
                                     'Color', 'none', ...
                                     'Box', 'off', ...
                                     'HitTest', 'off');
            axis([0 1 0 1]);
            axis off
            obj.selectionRect = rectangle('Position', [-1 0 1 1], ...
                                          'FaceColor', [0.5 0.75 1.0], ...
                                          'EdgeColor', [0.20 0.5 1.0], ...
                                          'Curvature', 0.05);
            
            obj.imageryLayer = 0;
            obj.lastClickTime = now;
        end
        
        
        function p = get.plate(obj)
            p = obj.object;
        end
        
        
        function load(obj, varargin)
            % TODO: the waitbar calls actually slow things down if all of the imagery has already been loaded,
            %       figure out some way not to show it in that case.
            h = waitbar(0, 'Loading wells...', 'vis', 'off', 'WindowStyle', 'modal');
            
            % Center the waitbar over the main window
            ui = NAA_curation();
            mainWindowPos = get(ui.mainWindow, 'Position');
            centerPos = [mainWindowPos(1) + mainWindowPos(3) / 2, mainWindowPos(2) + mainWindowPos(4) / 2];
            hPos = get(h, 'Position');
            set(h, 'Position', [centerPos(1) - hPos(3) / 2, centerPos(2) - hPos(4) / 2, hPos(3), hPos(4)]);
            set(h, 'Visible', 'on');
            drawnow
            
            plateSize = obj.plate.protocol.wellDims;
            
            if isempty(obj.wellAxes) || any(size(obj.wellAxes) ~= plateSize)
                % Get rid of the previous axes.
                if ~isempty(obj.wellAxes)
                    delete(obj.wellAxes{:});
                    delete(obj.wellLabels{:});
                end
                obj.wellAxes = {};
                obj.wellLabels = {};
                
                % Create new axes.
                axesWidth = 1.0 / plateSize(2);
                axesHeight = 1.0 / plateSize(1);
                for row = 1:plateSize(1)
                    for col = 1:plateSize(2)
                        obj.wellAxes{row, col} = axes('Parent', obj.panel, ...
                                                      'Position', [axesWidth * (col - 1) + axesWidth * 0.1, ...
                                                                   1.0 - axesHeight * row + axesHeight * 0.1, ...
                                                                   axesWidth * 0.8, axesHeight * 0.8], ...
                                                      'Color', 'none', ...
                                                      'Box', 'off', ...
                                                      'HitTest', 'off');  %#ok<LAXES>
                        axis off;
                        obj.wellLabels{row, col, 1} = uicontrol('Parent', obj.panel, ...
                                                                'Units', 'normalized', ...
                                                                'Position', [axesWidth * (col - 0.9), 1.0 - axesHeight * row, axesWidth * 0.4, axesHeight * 0.1], ...
                                                                'Style', 'text', ...
                                                                'HorizontalAlignment', 'left', ...
                                                                'String', '');
                        obj.wellLabels{row, col, 2} = uicontrol('Parent', obj.panel, ...
                                                                'Units', 'normalized', ...
                                                                'Position', [axesWidth * (col - 0.5), 1.0 - axesHeight * row, axesWidth * 0.4, axesHeight * 0.1], ...
                                                                'Style', 'text', ...
                                                                'HorizontalAlignment', 'right', ...
                                                                'String', '');
                    end
                end
                
            end
            
            % Load the well imagery.
            obj.drawWells(h);
            
            delete(h);
            
            if length(varargin) == 1 && varargin{1}.parent == obj.plate
                % Select the supplied well.
                obj.selectWell(varargin{1}); 
            else
                % Select the first well.
                obj.selectWell(obj.plate.wells{1, 1});
            end
        end
        
        
        function drawWells(obj, waitBarH)
            plateSize = obj.plate.protocol.wellDims;
            for row = 1:plateSize(1)
                for col = 1:plateSize(2)
                    obj.drawWell(obj.plate.wells{row, col});
                end
                    
                if nargin == 2
                    waitbar(row / plateSize(1), waitBarH);
                end
            end
        end
        
        
        function drawWell(obj, well)
            wellAx = obj.wellAxes{well.position(1), well.position(2)};
            drawWellInAxes(well, wellAx, obj.imageryLayer, false, true);
            h = title(wellAx, well.name, 'FontUnits', 'points', 'FontSize', 12, 'FontWeight', 'bold');
            titlePos = get(h, 'Position');
            titlePos(2) = 4;
            set(h, 'Position', titlePos);
            if isempty(well.construct)
                label1 = '';
            else
                label1 = well.construct.name;
            end
            if well.passed
                label2 = well.description;
            elseif ~well.passed
                if isempty(well.failureReason)
                    label2 = 'Unknown';
                else
                    label2 = well.failureReason.name;
                end
            else
                label2 = '';
            end
            set(obj.wellLabels{well.position(1), well.position(2), 1}, 'String', label1);
            set(obj.wellLabels{well.position(1), well.position(2), 2}, 'String', label2);
        end
        
        
        function selectWell(obj, well)
            if isempty(well)
                obj.selectWells([]);
            else
                obj.selectWells([well.position(2), well.position(1), 1, 1]);
            end
        end
        
        
        function selectWells(obj, wellRange)
            if ~isempty(obj.selectedWells)
                bgColor = get(0, 'defaultUicontrolBackgroundColor');
                for c = obj.selectedWells(1):obj.selectedWells(1) + obj.selectedWells(3) - 1
                    for r = obj.selectedWells(2):obj.selectedWells(2) + obj.selectedWells(4) - 1
                        set(obj.wellLabels{r, c, 1}, 'BackgroundColor', bgColor);
                        set(obj.wellLabels{r, c, 2}, 'BackgroundColor', bgColor);
                    end
                end
            end
            
            obj.selectedWells = wellRange;
            
            if isempty(obj.selectedWells)
                % Hide the selection axes by moving it off screen.
                newPosition = [-1 0 1 1];
            else
                % Move the indicator to the current selection.
                plateSize = size(obj.plate.wells);
                axesSize = 1.0 ./ plateSize;
                newPosition = [axesSize(2) * (obj.selectedWells(1) - 1.0), ...
                               1.0 - axesSize(1) * (obj.selectedWells(2) + obj.selectedWells(4) - 1), ...
                               axesSize(2) * obj.selectedWells(3), ...
                               axesSize(1) * obj.selectedWells(4)];
                
                % Color the label backgrounds the same as the selection axes.
                for c = obj.selectedWells(1):obj.selectedWells(1) + obj.selectedWells(3) - 1
                    for r = obj.selectedWells(2):obj.selectedWells(2) + obj.selectedWells(4) - 1
                        set(obj.wellLabels{r, c, 1}, 'BackgroundColor', [0.5 0.75 1.0]);
                        set(obj.wellLabels{r, c, 2}, 'BackgroundColor', [0.5 0.75 1.0]);
                    end
                end
            end
            
            set(obj.selectionRect, 'Position', newPosition);
        end
        
        
        function unload(obj)
            % Clear out the well images and titles.
            for i = 1:numel(obj.wellAxes)
                ax = obj.wellAxes{i};
                cla(ax);
                axis(ax, 'off');
                title(ax, '');
            end
            
            obj.imageryLayer = 0;
            obj.selectWell([]);
        end
        
        
        function desc = objectDescription(obj)
            desc = objectDescription@ObjectInspector(obj);
            
            if ~isempty(obj.plate)
                if obj.imageryLayer == 0
                    desc = sprintf('%s (Base)', desc);
                else
                    desc = sprintf('%s (%d FP)', desc, obj.plate.protocol.nAP(obj.imageryLayer));
                end
            end
        end
        
        
        function handleKeyPress(obj, keyEvent)
            if ~isempty(obj.plate)
                if ~isempty(obj.selectedWells)
                    wellRow = obj.selectedWells(2) + obj.selectedWells(4) - 1;
                    wellCol = obj.selectedWells(1) + obj.selectedWells(3) - 1;
                end
                plateSize = size(obj.plate.wells);
                
                if strcmp(keyEvent.Key, 'leftarrow')
                    if isempty(obj.selectedWells)
                        wellRow = plateSize(2);
                        wellCol = plateSize(1);
                    else
                        wellCol = wellCol - 1;
                        if wellCol == 0
                            wellCol = plateSize(2);
                            wellRow = wellRow - 1;
                            if wellRow == 0
                                wellRow = plateSize(1);
                            end
                        end
                    end
                    obj.selectWell(obj.plate.wells{wellRow, wellCol});
                elseif strcmp(keyEvent.Key, 'uparrow')
                    if isempty(obj.selectedWells)
                        wellRow = plateSize(2);
                        wellCol = plateSize(1);
                    else
                        wellRow = wellRow - 1;
                        if wellRow == 0
                            wellRow = plateSize(1);
                            wellCol = wellCol - 1;
                            if wellCol == 0
                                wellCol = plateSize(2);
                            end
                        end
                    end
                    obj.selectWell(obj.plate.wells{wellRow, wellCol});
                elseif strcmp(keyEvent.Key, 'rightarrow')
                    if isempty(obj.selectedWells)
                        wellRow = 1;
                        wellCol = 1;
                    else
                        wellCol = wellCol + 1;
                        if wellCol > plateSize(2)
                            wellCol = 1;
                            wellRow = wellRow + 1;
                            if wellRow > plateSize(1)
                                wellRow = 1;
                            end
                        end
                    end
                    obj.selectWell(obj.plate.wells{wellRow, wellCol});
                elseif strcmp(keyEvent.Key, 'downarrow')
                    if isempty(obj.selectedWells)
                        wellRow = 1;
                        wellCol = 1;
                    else
                        wellRow = wellRow + 1;
                        if wellRow > plateSize(1)
                            wellRow = 1;
                            wellCol = wellCol + 1;
                            if wellCol > plateSize(2)
                                wellCol = 1;
                            end
                        end
                    end
                    obj.selectWell(obj.plate.wells{wellRow, wellCol});
                elseif strcmp(keyEvent.Key, 'space')
                    curationUI = NAA_curation();
                    if obj.selectedWells(3) == 1 && obj.selectedWells(4) == 1
                        well = obj.plate.wells{obj.selectedWells(2), obj.selectedWells(1)};
                        curationUI.inspectObject(well);
                    else
                        % More than one well is selected.
                        beep
                    end
                elseif strcmp(keyEvent.Character, '=') || strcmp(keyEvent.Key, 'return')
                    if isempty(obj.selectedWells) || ~obj.plate.canBeModified()
                        beep;
                    else
                        for c = obj.selectedWells(1):obj.selectedWells(1) + obj.selectedWells(3) - 1
                            for r = obj.selectedWells(2):obj.selectedWells(2) + obj.selectedWells(4) - 1
                                well =  obj.plate.wells{r, c};
                                if ~isempty(well.summary)
                                    well.setPassed(true);
                                    obj.drawWell(well);
                                end
                            end
                        end
                    end
                elseif strcmp(keyEvent.Character, '-') || strcmp(keyEvent.Key, 'backspace')
                    if isempty(obj.selectedWells) || ~obj.plate.canBeModified()
                        beep;
                    else
                        if length(keyEvent.Modifier) == 1 && strcmp(keyEvent.Modifier{1}, 'alt') && ~isempty(obj.lastFailureReason)
                            failureReason = obj.lastFailureReason;
                        else
                            failureReason = pickFailureReason(obj.plate.wells{obj.selectedWells(2), obj.selectedWells(1)});
                        end
                        for c = obj.selectedWells(1):obj.selectedWells(1) + obj.selectedWells(3) - 1
                            for r = obj.selectedWells(2):obj.selectedWells(2) + obj.selectedWells(4) - 1
                                well =  obj.plate.wells{r, c};
                                well.setPassed(false, failureReason);
                                obj.drawWell(well);
                            end
                        end
                        
                        if ~isempty(failureReason)
                            obj.lastFailureReason = failureReason;
                        end
                    end
                end
            end
        end
        
        
        function handleMouseClick(obj, mouseLoc, ~)
            % Figure out which well is under the mouse.
            plateSize = size(obj.plate.wells);
            axesSize = 1.0 ./ plateSize;
            wellCol = ceil(mouseLoc(1) / axesSize(2));
            wellRow = ceil(mouseLoc(2) / axesSize(1));
            
            if now - obj.lastClickTime > 1 / 24 / 60 / 60 * 0.4 % 0.4 seconds
                % It's a single-click so just select the well.
                
                if strcmp(get(gcf, 'SelectionType'), 'extend')
                    % Extend the selection to include the clicked well.
                    newRange = [min([obj.selectedWells(1), wellCol]), ...
                                min([obj.selectedWells(2), wellRow]), ...
                                max([obj.selectedWells(1) + obj.selectedWells(3) - 1, wellCol]), ...
                                max([obj.selectedWells(2) + obj.selectedWells(4) - 1, wellRow])];
                    newRange(3) = newRange(3) - newRange(1) + 1;
                    newRange(4) = newRange(4) - newRange(2) + 1;
                    obj.selectWells(newRange);
                else
                    % Just selecte the clicked well.
                    obj.selectWell(obj.plate.wells{wellRow, wellCol});
                end
            else
                % It's a double-click so inspect the well.
                curationUI = NAA_curation();
                curationUI.inspectObject(obj.plate.wells{wellRow, wellCol});
            end
            
            % Remember the time of this click so we can tell if the next one is a double.
            obj.lastClickTime = now;
        end
        
        
        function handleMouseWheelScroll(obj, scrollEvent)
            % Move between the base and ??? imagery.
            
            obj.imageryLayer = obj.imageryLayer + scrollEvent.VerticalScrollCount;
            
            obj.imageryLayer = min(max(obj.imageryLayer, 0), length(obj.plate.protocol.nAP));
            obj.drawWells();
            
            obj.updateDescription();
        end
        
    end
    
end