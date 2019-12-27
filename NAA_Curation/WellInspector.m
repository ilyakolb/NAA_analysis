classdef WellInspector < ObjectInspector
    
    properties (Constant)
        objectClass = 'Well'
    end
    
    properties
        detailsPanel
        imageryLayerPopUp
        showCellsCheckBox
        passFailPopUp
        dffPlotAxes
        f0PlotAxes
        
        wellAxes
        
        imageryLayer = 0;
        dffPlotLineHandles
        dffPlotMeanLineHandle
        dffPlotMedianLineHandle
    end
    
    properties (Dependent)
        well
    end
    
    methods
        
        function createInterface(obj)
            obj.detailsPanel = uipanel(obj.panel, ...
                'BorderType', 'none', ...
                'Position', [0 0 0.1 1]);
            uicontrol(obj.detailsPanel, ...
                'Style', 'text', ...
                'FontSize', 12, ...
                'Units', 'normalized', ...
                'Position', [0.01 0.95 0.33 0.03], ...
                'HorizontalAlignment', 'left', ...
                'String', 'Imagery Layer:');
            obj.imageryLayerPopUp = uicontrol(obj.detailsPanel, ...
                'Style', 'popup', ...
                'FontSize', 12, ...
                'String', 'Base', ...
                'Units', 'normalized', ...
                'Position', [0.3 0.95 0.65 0.03], ...
                'Callback', @(hObject, event)imageryLayerPopUpWasChanged(obj, event));
            obj.showCellsCheckBox = uicontrol(obj.detailsPanel, ...
                'Style', 'checkbox', ...
                'FontSize', 12, ...
                'Units', 'normalized', ...
                'Position', [0.01 0.9 0.90 0.03], ...
                'String', 'Show cell bodies', ...
                'Value', 0, ...
                'Callback', @(hObject, event)showCellsBoxWasChecked(obj, event));
            uicontrol(obj.detailsPanel, ...
                'Style', 'text', ...
                'FontSize', 12, ...
                'Units', 'normalized', ...
                'Position', [0.01 0.85 0.35 0.03], ...
                'HorizontalAlignment', 'left', ...
                'String', 'Failure Reason:');
            obj.passFailPopUp = uicontrol(obj.detailsPanel, ...
                'Style', 'popup', ...
                'FontSize', 12, ...
                'String', 'None', ...
                'Units', 'normalized', ...
                'Position', [0.3 0.85 0.65 0.03], ...
                'Callback', @(hObject, event)passFailPopUpWasChanged(obj, event));
            obj.dffPlotAxes = axes('Parent', obj.detailsPanel, ...
                'OuterPosition', [0.01 0.4 0.98 0.4], ...
                'Color', 'none', ...
                'Box', 'off');
            obj.f0PlotAxes = axes('Parent', obj.detailsPanel, ...
                'OuterPosition', [0.01 0.0 0.98 0.4], ...
                'Color', 'none', ...
                'Box', 'off');
            obj.wellAxes = axes('Parent', obj.panel, ...
                                'OuterPosition', [0.1 0 0.9 1], ...
                                'Position', [0.1 0 0.9 1], ...
                                'Color', 'none', ...
                                'Box', 'off');
        end
        
        function load(obj, imageryLayer)
            if nargin >= 2
                obj.imageryLayer = imageryLayer;
            end
            
            if obj.well.canBeModified()
                enableString = 'on';
            else
                enableString = 'off';
            end
            
            % Update the imagery layer choices
            popUpString = 'Base';
            for i = 1:length(obj.well.plate.protocol.nAP)
                popUpString = sprintf('%s|%d FP', popUpString, obj.well.plate.protocol.nAP(i));
            end
            set(obj.imageryLayerPopUp, 'String', popUpString);
            
            
            if isempty(obj.well.cellList)
                set(obj.showCellsCheckBox, 'Enable', 'off', 'Value', false, 'String', 'Show cell bodies (none detected)');
            else
                set(obj.showCellsCheckBox, 'Enable', 'on', 'String', sprintf('Show cell bodies (%d detected)', length(obj.well.cellList)));
            end
            
            try
                obj.drawPlots();
            catch ME
                disp(getReport(ME));
            end
            obj.drawWellImage();
            
            % Populate the pass/fail pop-up menu.
            reasons = FailureReason.all();
            reasons = {'None' reasons.name, 'Unknown'};
            if obj.well.passed
                value = 1;                  % = 'None'
            elseif isempty(obj.well.passed) || isempty(obj.well.failureReason)
                value = length(reasons);    % = 'Unknown'
            else
                value = find(strcmp(reasons, obj.well.failureReason.name));
            end
            set(obj.passFailPopUp, 'String', reasons, 'Value', value, 'Enable', enableString);
        end
        
        
        function drawPlots(obj)
            if isempty(obj.well.paraArray)
                cla(obj.dffPlotAxes);
                cla(obj.f0PlotAxes);
            else
                % Update the df/f plot.
                if obj.imageryLayer == 0
                    layer = ceil(length(obj.well.plate.protocol.nAP) / 2);  % TODO: or add a new protocol property?
                else
                    layer = obj.imageryLayer;
                end
                
                nTime = length(obj.well.paraArray(1).df_f);
                nTrial = size(obj.well.paraArray, 1) / length(obj.well.plate.protocol.nAP);
                fs = 35;
                
                df_f = reshape([obj.well.paraArray.df_f], [nTime, length(obj.well.plate.protocol.nAP), nTrial, length(obj.well.cellList)]);
                min_df_f = min(df_f(:));
                max_df_f = max(df_f(:));
                df_f = df_f(:, layer, 1, :);
                
                squeezed_df_f = squeeze(df_f);
                if isempty(obj.dffPlotLineHandles)
                    axes(obj.dffPlotAxes);
                    hold off;
                    obj.dffPlotLineHandles = plot((1:nTime) / fs, squeezed_df_f, 'color', [1, 1, 1] * 0.6);
                    hold on;
                    obj.dffPlotMeanLineHandle = plot((1:nTime) / fs, squeeze(mean(df_f, 4)), 'linewidth', 3);
                    obj.dffPlotMedianLineHandle = plot((1:nTime) / fs, squeeze(median(df_f, 4)), 'r', 'linewidth', 3);
                    set(gca, 'XLim', [0 nTime / fs], 'YLim', [min_df_f max_df_f]);
                    
                    % Update the f0 plot
                    axes(obj.f0PlotAxes);
                    f0 = [obj.well.paraArray.f0];
                    f0 = reshape(f0, size(obj.well.paraArray));
                    plot(f0, 'b');
                    hold on;
                    plot(mean(f0, 2), 'r', 'LineWidth', 2);
                    title('f0')
                else
                    for i = 1:length(obj.dffPlotLineHandles)
                        set(obj.dffPlotLineHandles(i), 'YData', squeezed_df_f(:, i));
                    end
                    set(obj.dffPlotMeanLineHandle, 'YData', squeeze(mean(df_f, 4)));
                    set(obj.dffPlotMedianLineHandle, 'YData', squeeze(median(df_f, 4)));
                end
            end
        end
        
        
        function drawWellImage(obj)
            showCells = get(obj.showCellsCheckBox, 'Value');
            drawWellInAxes(obj.well, obj.wellAxes, obj.imageryLayer, showCells, true);
        end
        
        
        function w = get.well(obj)
            w = obj.object;
        end
        
        
        function unload(obj)
            % TODO: would it be useful to maintain the layer while browsing wells?
            obj.imageryLayer = 0;
            set(obj.imageryLayerPopUp, 'String', 'Base');
            cla(obj.dffPlotAxes);
            cla(obj.f0PlotAxes);
            obj.dffPlotLineHandles = [];
            obj.dffPlotMeanLineHandle = [];
            obj.dffPlotMedianLineHandle = [];
        end
        
        
        function desc = objectDescription(obj)
            desc = objectDescription@ObjectInspector(obj);
            
            if ~isempty(obj.well)
                desc = sprintf('%s: %s', obj.well.plate.name, desc);
            end
        end
        
        
        function set.imageryLayer(obj, newLayer)
            if newLayer ~= obj.imageryLayer
                obj.imageryLayer = newLayer;
                
                try
                    obj.drawPlots();
                catch ME
                    disp(getReport(ME));
                end
                
                obj.drawWellImage();

                obj.updateDescription();
                
                set(obj.imageryLayerPopUp, 'Value', obj.imageryLayer + 1); %#ok<MCSUP>
            end
        end
        
        
        function imageryLayerPopUpWasChanged(obj, ~)
            newLayer = get(obj.imageryLayerPopUp, 'Value') - 1;
            obj.imageryLayer = newLayer;
        end
        
        
        function showCellsBoxWasChecked(obj, ~)
            obj.drawWellImage();
        end
        
        
        function passFailPopUpWasChanged(obj, ~)
            reasons = get(obj.passFailPopUp, 'String');
            choice = get(obj.passFailPopUp, 'Value');
            if choice == 1
                obj.well.setPassed(true, FailureReason(reasons{choice}));
            elseif strcmp(reasons{choice}, 'Unknown')
                obj.well.setPassed([]);   % TODO: should this be allowed?
            else
                obj.well.setPassed(false, FailureReason(reasons{choice}));
            end
            obj.drawWellImage();
        end
        
        
        function handleKeyPress(obj, keyEvent)
            if ~isempty(obj.well)
                plateSize = size(obj.well.plate.wells);
                wellRow = obj.well.position(1);
                wellCol = obj.well.position(2);
                
                curationUI = NAA_curation();
                
                if strcmp(keyEvent.Key, 'leftarrow')
                    wellCol = wellCol - 1;
                    if wellCol == 0
                        wellCol = plateSize(2);
                        wellRow = wellRow - 1;
                        if wellRow == 0
                            wellRow = plateSize(1);
                        end
                    end
                    curationUI.inspectObject(obj.well.plate.wells{wellRow, wellCol}, obj.imageryLayer);
                elseif strcmp(keyEvent.Key, 'uparrow')
                    if length(keyEvent.Modifier) == 1 && strcmp(keyEvent.Modifier{1}, 'alt')
                        if obj.imageryLayer == 0
                            beep;
                        else
                            obj.imageryLayer = obj.imageryLayer - 1;
                        end
                    else
                        wellRow = wellRow - 1;
                        if wellRow == 0
                            wellRow = plateSize(1);
                            wellCol = wellCol - 1;
                            if wellCol == 0
                                wellCol = plateSize(2);
                            end
                        end
                        curationUI.inspectObject(obj.well.plate.wells{wellRow, wellCol}, obj.imageryLayer);
                    end
                elseif strcmp(keyEvent.Key, 'rightarrow')
                    wellCol = wellCol + 1;
                    if wellCol > plateSize(2)
                        wellCol = 1;
                        wellRow = wellRow + 1;
                        if wellRow > plateSize(1)
                            wellRow = 1;
                        end
                    end
                    curationUI.inspectObject(obj.well.plate.wells{wellRow, wellCol}, obj.imageryLayer);
                elseif strcmp(keyEvent.Key, 'downarrow')
                    if length(keyEvent.Modifier) == 1 && strcmp(keyEvent.Modifier{1}, 'alt')
                        if obj.imageryLayer == length(obj.well.plate.protocol.nAP)
                            beep;
                        else
                            obj.imageryLayer = obj.imageryLayer + 1;
                        end
                    else
                        wellRow = wellRow + 1;
                        if wellRow > plateSize(1)
                            wellRow = 1;
                            wellCol = wellCol + 1;
                            if wellCol > plateSize(2)
                                wellCol = 1;
                            end
                        end
                        curationUI.inspectObject(obj.well.plate.wells{wellRow, wellCol}, obj.imageryLayer);
                    end
                elseif strcmp(keyEvent.Key, 'space') || strcmp(keyEvent.Key, 'escape')
                    curationUI.inspectObject(obj.well.plate, obj.well);
                elseif strcmp(keyEvent.Character, '=') || strcmp(keyEvent.Key, 'return')
                    if ~obj.well.canBeModified()
                        beep;
                    else
                        obj.well.setPassed(true);
                        obj.drawWellImage();
                    end
                elseif strcmp(keyEvent.Character, '-') || strcmp(keyEvent.Key, 'backspace')
                    if ~obj.well.canBeModified()
                        beep;
                    else
                        failureReason = pickFailureReason(obj.well);
                        if ~isempty(failureReason)
                            obj.well.setPassed(false, failureReason);
                            obj.drawWellImage();
                        end
                    end
                end
            end
        end
        
        
        function handleResize(obj, newPosition)
            minSidePanelWidth = 200;
            margin = 20;
            axesSize = newPosition(4) - margin * 2;
            sidePanelWidth = newPosition(3) - axesSize - margin;
            if sidePanelWidth < minSidePanelWidth
                axesSize = newPosition(3) - minSidePanelWidth - margin;
            end
            axesPos = [(newPosition(3) - axesSize - margin) / newPosition(3), ...
                       (newPosition(4) - axesSize) / newPosition(4) / 2, ...
                       axesSize / newPosition(3), ...
                       axesSize / newPosition(4)];
            set(obj.wellAxes, 'OuterPosition', axesPos, 'Position', axesPos);
            
            set(obj.detailsPanel, 'Position', [0 0 axesPos(1) 1]);
        end
        
        
        function handleMouseWheelScroll(obj, scrollEvent)
            % Move between the imagery layers.
            newLayer = obj.imageryLayer + scrollEvent.VerticalScrollCount;
            newLayer = min(max(newLayer, 0), length(obj.well.plate.protocol.nAP));
            obj.imageryLayer = newLayer;
        end
        
    end
    
end
