classdef VirtualFileObject < handle
    
    properties
        parent
        children
        
        name
        path
    end
    
    
    methods
        
        function obj = VirtualFileObject(parent, path, name)
            obj.parent = parent;
            obj.children = {};  % must be cell array to support different classes of children
            obj.path = path;
            if nargin == 3
                obj.name = name;
            else
                [~, obj.name, ~] = fileparts(path);
            end
        end
        
        
        function i = icon(obj) %#ok<MANU>
            i = [];
        end
        
        
        function c = canBeModified(obj)
            if isempty(obj.parent)
                c = true;
            else
                c = obj.parent.canBeModified();
            end
        end
        
        
        function m = isModified(obj) %#ok<MANU>
            m = false;
        end
        
        
        function d = saveDelegate(obj)
            % Override to return another object that is responsible for saving any changes to this object.
            d = obj;
        end
        
        
        function [didSave, errorMessage] = save(obj)
            if obj.saveDelegate() ~= obj
                % Let the delegate do the saving.
                [didSave, errorMessage] = obj.saveDelegate.save();
            else
                didSave = false;
                errorMessage = 'Saving has not been implemented for this type of object.';
            end
        end
        
        
        function a = ancestors(obj)
            if isempty(obj.parent)
                a = {};
            else
                a = {obj.parent};
                while ~isempty(a{end}.parent)
                    a{end + 1} = a{end}.parent; %#ok<AGROW>
                end
            end
        end
        
        
        function delete(obj)
            for i = 1:length(obj.children)
                delete(obj.children{i});
            end
        end
        
    end
end