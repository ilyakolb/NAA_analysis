function enablePOI
    % Set up the Java environment so the the POI API can be used to read/write Office documents.
    %
    % A good tutorial is at <http://poi.apache.org/spreadsheet/quick-guide.html>
    % The Java docs are at <http://poi.apache.org/apidocs/index.html>
    %
    % Beware: The first time this function is called "clear java" will be called which blows away breakpoints, 
    %         clears global values, etc. If you are debugging it's recommended to call enablePOI manually before 
    %         starting your debug session.
    
    existingPaths = javaclasspath;
    path = mfilename('fullpath');
    [path, ~, ~] = fileparts(path);
    jarNames = dir(fullfile(path, '*.jar'));
    for i = 1:length(jarNames)
        jarPath = fullfile(path, jarNames(i).name);
        if ~ismember(jarPath, existingPaths)
            % javaaddpath() calls "clear java" internally
            javaaddpath(jarPath);
        end
    end
end