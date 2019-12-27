classdef FailureReason < Singleton
    
    properties
        wells = Well.empty(1, 0)
    end
    
    
    methods
        
        function obj = FailureReason(name)
            obj = obj@Singleton(name);
            
            % TODO: make sure Other and Unknown stay at the end of the list?
        end
        
        
        function addWell(obj, well)
            obj.wells(end + 1) = well;
            obj.wells = sort(obj.wells);
        end
        
        
        function removeWell(obj, well)
            for i = 1:length(obj.wells)
                if obj.wells(i) == well
                    obj.wells(i) = [];
                    break;
                end
            end
        end
        
        
        function fw = filteredWells(obj, dataFilter)
            if isfield(dataFilter, 'minImagingDate')
                if ischar(dataFilter.minImagingDate)
                    dataFilter.minImagingDate = str2double(dataFilter.minImagingDate);
                end
                fw = obj.wells(arrayfun(@(well) well.plate.protocol == dataFilter.protocol && ...
                                                str2double(well.imagingDate) >= dataFilter.minImagingDate, ...
                                                obj.wells));
            elseif isfield(dataFilter, 'plateSet')
                % TODO: more than one plate set?
                fw = obj.wells(arrayfun(@(well) well.plate.protocol == dataFilter.protocol && ...
                                                (well.plate.parent == dataFilter.plateSet || well.plate.parent.parent == dataFilter.plateSet), ...
                                                obj.wells));
            end
        end
        
    end
    
    
    methods (Static)
        
        function i = all()
            i = Singleton.all('FailureReason');
        end
        
    end
    
end