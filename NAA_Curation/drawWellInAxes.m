function drawWellInAxes(well, wellAxes, imageryLayer, showCells, drawAnnotation)
    if nargin < 3 || imageryLayer == 0
        prevUnits = get(wellAxes, 'Units');
        set(wellAxes, 'Units', 'pixels');
        pos = get(wellAxes, 'Position');
        set(wellAxes, 'Units', prevUnits);
        % On a 17" MacBook Pro pos(3) == 204 pixels for a 4x6 plate.
        if pos(3) < 256
            wellImage = well.thumbnail;
        else
            wellImage = well.overlayImage;
        end
        colorLimits = [];
    else
        if isempty(well.responseMap)
            wellImage = [];
        else
            wellImage = well.responseMap(:, :, imageryLayer);
        end
        colorLimits = [0, well.plate.protocol.cLimHigh(imageryLayer)];
    end
    if isempty(wellImage)
        wellImage = zeros(512, 512, 3);
    end
    
    [imageToolboxAvailable, ~] = license('checkout', 'image_toolbox');
    if showCells && ~isempty(well.cellList) && imageryLayer == 0 && imageToolboxAvailable
        % Draw the outline of the cell bodies.
        % TODO: handle non-zero imagery layers
        ss = size(wellImage);
        wellImage = reshape(wellImage, [], 3);
        for i = 1:length(well.cellList)
            BW = false(ss(1:2));
            BW(well.cellList(i).pixel_list) = true;
            B = bwperim(BW, 4);
            shadow = circshift(B, [1 1]);
            shadow(1, :) = false;
            shadow(:, 1) = false;
            wellImage(shadow, :) = 0;
            wellImage(B, 1) = 1;
            wellImage(B, 2) = 1;
            wellImage(B, 3) = 0;
        end
        wellImage = reshape(wellImage, ss);
    end
    
    parent = get(wellAxes, 'Parent');
    while ~strcmp(get(parent, 'Type'), 'figure')
        parent = get(parent, 'Parent');
    end
    set(0, 'CurrentFigure', parent);
    set(gcf, 'CurrentAxes', wellAxes);
    if isempty(colorLimits)
        image(wellImage, 'HitTest', 'off');  
        set(wellAxes, 'CLimMode', 'auto');
    else
        imagesc(wellImage, 'HitTest', 'off');  
        set(wellAxes, 'CLim', colorLimits);
    end
    axis image;
    set(wellAxes, 'XTick', [], 'YTick', []);    % TODO: necessary?
    
    if showCells && ~isempty(well.cellList) && ~imageToolboxAvailable
        % Just draw a circle centered on the cell body.
        cellXs = arrayfun(@(x) x.center(2), well.cellList);
        cellYs = arrayfun(@(x) x.center(1), well.cellList);
        hold on
        scatter(cellXs + 0.5, cellYs + 0.5, ones(1, length(well.cellList)) * 200, 'LineWidth', 1, 'MarkerEdgeColor', 'black');
        scatter(cellXs, cellYs, ones(1, length(well.cellList)) * 200, 'LineWidth', 1, 'MarkerEdgeColor', 'yellow');
    end

    % Draw the annotation indicator
    if drawAnnotation
        if isempty(well.passed)
            label = '?';
            color = 'yellow';
        elseif well.passed
            label = '\surd'; % a check mark
            color = 'green';
        else
            label = 'X';
            color = 'red';
        end
        % First draw slightly larger in black to give the indicator a shadow to make it easier to see.
        text(size(wellImage, 2), size(wellImage, 1), label, 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'black', ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
        text(size(wellImage, 2), size(wellImage, 1), label, 'FontSize', 15, 'FontWeight', 'bold', 'Color', color, ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
    end
end

