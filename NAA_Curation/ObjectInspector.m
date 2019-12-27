classdef ObjectInspector < handle
    
    properties (Constant, Abstract)
        objectClass
    end
    
    properties
        panel
        object
    end
    
    
    methods
        
        function obj = ObjectInspector(varargin)
            curationUI = NAA_curation();
            obj.panel = uipanel(curationUI.inspectionPanel, ...
                'BorderType', 'none', ...
                'Position', [0.0 0.0 1.0 0.97], ... % leaving room for the title above
                'Visible', 'off', ...
                'HitTest', 'off');
            
            obj.createInterface();
        end
        
        
        function i = inspectObject(obj, object, varargin)
            i = true;
            
            if isempty(obj.object) || isempty(object) || object ~= obj.object
                curationUI = NAA_curation();
                set(0, 'CurrentFigure', curationUI.mainWindow);
                
                % Remove the current object from the UI.
                obj.unload();

                obj.object = object;

                if ~isempty(object)
                    % Load the new object into the UI.
                    obj.load(varargin{:});
                end

                set(curationUI.inspectionTitle, 'String', obj.objectDescription());
            end
        end
        
        
        function desc = objectDescription(obj)
            if isempty(obj.object)
                desc = 'No object is being inspected';
            elseif strncmp(obj.object.name, class(obj.object), length(class(obj.object)))
                desc = obj.object.name;
            else
                desc = [class(obj.object) ' ' obj.object.name];
            end
        end
        
        
        function updateDescription(obj)
            % TODO: use a listener instead?
            curationUI = NAA_curation();
            set(curationUI.inspectionTitle, 'String', obj.objectDescription());
        end
        
        
        function handleKeyPress(obj, keyEvent) %#ok<INUSD,MANU>
            % Handle any keyboard events if desired.
        end
        
        
        function handleMouseClick(obj, mouseLoc, mouseEvent) %#ok<INUSD,MANU>
            % Handle any mouse events if desired.
        end
        
        
        function handleMouseWheelScroll(obj, scrollEvent) %#ok<INUSD,MANU>
            % Handle any scroll wheel events if desired.
        end
        
        
        function handleResize(obj, newPosition) %#ok<INUSD,MANU>
            % Manually resize any UI in the panel if needed.
        end
        
    end
    
    
    methods (Abstract)
        createInterface(obj);
        load(obj);
        unload(obj);
    end
end
