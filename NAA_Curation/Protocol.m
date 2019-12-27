classdef Protocol < Singleton
    
    properties
        indicator   % e.g. 'GCaMP'
        
        nAP = [1, 2, 3, 5, 10, 20, 40, 80, 160]
        cLimHigh = [0.3, 0.5, 0.7, 0.9, 1.5, 3, 4, 6, 7]
        coef = [0.000156495712052491, 0.000752251925568609, 0.00156955997851363, 0.00343005020191577, 0.00800609214678007, 0.0115718348677763, 0.0123973396650655, 0.00672647509218113, 0.000433082719367492; ...
                0.0121190451275125,   0.0263129805214887,   0.0553574289830683,  0.138634898664620,   0.404445111394460,   1.12422834926618,   2.40307110395149,   4.25944240563536,    5.52673794794599];
        
        wellDims = [4, 6];
        
        controlConstruct = Construct('10.1');
        
        dataAllFilters = {'.*'};
    end
    
    
    methods
        
        function obj = Protocol(name, indicator, nAP, cLimHigh, coef, wellDims, control)
            obj = obj@Singleton(name);
            
            if nargin > 1
                obj.indicator = indicator;
                if nargin > 2
                    obj.nAP = nAP;
                    obj.cLimHigh = cLimHigh;
                    obj.coef = coef;
                    obj.wellDims = wellDims;
                    obj.controlConstruct = control;
                end
            end
        end
        
    end
    
    
    methods (Static)
        
        function i = all()
            i = Singleton.all('Protocol');
        end
        
        function e = exists(name)
            e = Singleton.exists('Protocol', name);
        end
    end
    
end