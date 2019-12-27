classdef RoguesGallery < Singleton
    
    properties
        mainWindow
        
        failureLabel
        failurePopUp
        exampleCountLabel
        loadAllExamplesButton
        
        galleryAxes
        scroller
        
        rowCount = 4
        columnCount = 6
    end
    
    
    methods
        
        function obj = RoguesGallery()
            obj = obj@Singleton();
            
            if isempty(obj.mainWindow)
                % Build the interface the first time this method is called.
                
                obj.buildInterface();
            end
        end
        
        
        function buildInterface(obj)
            % Restore the window position if possible.
            addlProps = {};
            if ispref('GENIE_NAA_Curation', 'RoguesWindow_Position')
                prevPos = getpref('GENIE_NAA_Curation', 'RoguesWindow_Position', []);
                if ~isempty(prevPos)
                    addlProps = {'Position', prevPos};
                end
            end
            
            % Create the main window.
            obj.mainWindow = figure(...
                'Units', 'points', ...
                'Menubar', 'none', ...
                'Name', 'GENIE NAA Rogue''s Gallery', ...
                'NumberTitle', 'off', ...
                'Color', get(0,'defaultUicontrolBackgroundColor'), ...
                'CloseRequestFcn', @(hObject, eventdata)closeRequestFcn(obj, hObject, eventdata), ...
                'WindowButtonUpFcn', @(hObject, eventdata)mouseButtonWasPressed(obj, hObject, eventdata), ...
                'WindowScrollWheelFcn', @(hObject, eventdata)mouseWheelWasScrolled(obj, hObject, eventdata), ...
                'ResizeFcn', @(hObject, eventdata)windowWasResized(obj, hObject, eventdata), ...
                'Position', [100 100 1024 768], ...     % default, may get overriden by addlProps
                'UserData', [], ...
                'Tag', 'figure', ...
                addlProps{:});
            
            obj.failureLabel = uicontrol(obj.mainWindow, ...
                'Style','text', ...
                'Position',[0 743 150 20], ...
                'FontSize', 14.0, ...
                'HorizontalAlignment', 'right', ...
                'String', 'Show examples of:');
            
            reasons = FailureReason.all();
            obj.failurePopUp = uicontrol(obj.mainWindow, ...
                'Style','popup', ...
                'Position',[160 743 250 22], ...
                'FontSize', 12.0, ...
                'String', {reasons.name}, ...
                'Callback', @(hObject, eventdata)failureReasonWasChosen(obj, hObject, eventdata));
            
            obj.exampleCountLabel = uicontrol(obj.mainWindow, ...
                'Style','text', ...
                'Position',[160 + 250 + 10 743 150 20], ...
                'FontSize', 14.0, ...
                'HorizontalAlignment', 'left', ...
                'String', '%d examples found');
            
            % TODO: add a pop-up to filter by protocol?
            
            obj.loadAllExamplesButton = uicontrol(obj.mainWindow, ...
                'Style', 'pushbutton', ...
                'Position', [919 743 100 22], ...
                'String', 'Load All Examples', ...
                'Callback', @(hObject, eventdata)loadAllExamples(obj, hObject, eventdata));
            
            obj.galleryAxes = axes('OuterPosition', [0 0 1008 738]);
            
            obj.scroller = uicontrol(obj.mainWindow, ...
                'Style', 'slider', ...
                'Position', [1008, 0, 16, 738], ...
                'Value', 1, ...
                'Callback', @(hObject, eventdata)scrollBarWasChanged(obj, hObject, eventdata));
            
            obj.drawExamples();
        end
        
        
        function windowWasResized(obj, ~, ~)
            windowPos = get(obj.mainWindow, 'Position');
            
            labelPos = get(obj.failureLabel, 'Position');
            labelPos(2) = windowPos(4) - 25;
            set(obj.failureLabel, 'Position', labelPos);
            
            popUpPos = get(obj.failurePopUp, 'Position');
            popUpPos(2) = windowPos(4) - 25;
            set(obj.failurePopUp, 'Position', popUpPos);
            
            labelPos = get(obj.exampleCountLabel, 'Position');
            labelPos(2) = windowPos(4) - 25;
            set(obj.exampleCountLabel, 'Position', labelPos);
            
            loadAllExamplesPos = get(obj.loadAllExamplesButton, 'Position');
            loadAllExamplesPos(1) = windowPos(3) - 5 - loadAllExamplesPos(3);
            loadAllExamplesPos(2) = windowPos(4) - 25;
            set(obj.loadAllExamplesButton, 'Position', loadAllExamplesPos);
            
            axesPos = [0 0 windowPos(3) windowPos(4) - 30];
            set(obj.galleryAxes, 'OuterPosition', axesPos);
            
            scrollerPos = [windowPos(3) - 16 0 16 windowPos(4) - 30];
            set(obj.scroller, 'Position', scrollerPos);
            
            % TODO: vary rows/columns based on window height/width and min/max size of a thumbnail.
        end
        
        
        function keyWasPressed(obj, ~, eventData)
            % TODO: navigate by arrows keys
            % TODO: 
        end
        
        
        function mouseButtonWasPressed(obj, ~, eventData)
            % TODO
        end
        
        
        function wellWasClicked(obj, ~, ~, well)
            selType = get(obj.mainWindow, 'SelectionType');
            if strcmp(selType, 'open')
                ui = NAA_curation();
                ui.inspectObject(well);
            end
        end
        
        
        function mouseWheelWasScrolled(obj, ~, eventData)
            % TODO
        end
        
        
        function scrollBarWasChanged(obj, ~, ~)
            obj.drawExamples();
        end
        
        
        function closeRequestFcn(obj, ~, ~)
            % Remember the window position.
            setpref('GENIE_NAA_Curation', 'RoguesWindow_Position', get(obj.mainWindow, 'Position'));
            delete(obj.mainWindow);
            obj.mainWindow = [];
            
            % Delete the singleton interface object.
            delete(obj);
        end
        
        
        function loadAllExamples(obj, ~, ~)
            ui = NAA_curation();
            ui.loadAllWells();
            
            obj.drawExamples();
        end
        
        
        function failureReasonWasChosen(obj, ~, ~)
            % Update the min/max of the scroll bar.
            reasonNames = get(obj.failurePopUp, 'String');
            reasonIndex = get(obj.failurePopUp, 'Value');
            reasonName = reasonNames{reasonIndex};
            examples = FailureReason(reasonName).wells;
            rows = ceil(length(examples) / obj.columnCount);
            if rows > obj.rowCount
                set(obj.scroller, 'Min', 1, 'Max', rows - 3, 'Value', rows - 3, 'SliderStep', [1 / (rows - 2), 4 / (rows - 2)], 'Visible', 'on');
            else
                set(obj.scroller, 'Min', 1, 'Max', 2, 'Value', 2, 'Visible', 'off');
            end
            obj.drawExamples();
        end
        
        
        function drawExamples(obj)
            % Get the list of examples for the current selection.
            % TODO: use position of scroller.
            reasonNames = get(obj.failurePopUp, 'String');
            reasonIndex = get(obj.failurePopUp, 'Value');
            reasonName = reasonNames{reasonIndex};
            examples = FailureReason(reasonName).wells;
            
            if isempty(examples)
                set(obj.exampleCountLabel, 'String', 'No examples found');
            elseif length(examples) == 1
                set(obj.exampleCountLabel, 'String', '1 example found');
            else
                set(obj.exampleCountLabel, 'String', [num2str(length(examples)) ' examples found']);
            end
            
            maxValue = get(obj.scroller, 'Max');
            rowStart = round(maxValue - get(obj.scroller, 'Value') + 1);
            
            % Draw the examples
            for r = 1:obj.rowCount
                for c = 1:obj.columnCount
                    index = (rowStart - 1) * obj.columnCount + (r - 1) * obj.columnCount + c;
                    subplot(obj.rowCount, obj.columnCount, (r - 1) * obj.columnCount + c);  %, 'Box', 'off');
                    axis off;
                    if index <= length(examples)
                        well = examples(index);

                        drawWellInAxes(well, gca, 0, false, false);
                        
                        title(gca, [well.plate.name ': ' well.name], 'FontSize', 12, 'Interpreter', 'none');
                        set(gca, 'ButtonDownFcn', @(hObject, eventdata)wellWasClicked(obj, hObject, eventdata, well));
                    else
                        cla(gca);
                        title('');
                        set(gca, 'ButtonDownFcn', []);
                    end
                end
            end
        end
    end
    
end
