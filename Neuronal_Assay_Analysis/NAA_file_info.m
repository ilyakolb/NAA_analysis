function info=NAA_file_info(filename)
    % Trim off any extension
    [~, filename, ~] = fileparts(filename);
    
    % Split the name by underscores.
    tokens = textscan(filename, '%s', 'delimiter', '_');
    
    % Assign the pieces to the appropriate fields of the info struct.
    if strncmpi(tokens{1}{1}, 'autofocusgraph', length('autofocusgraph'))
        % My best guess at field names...
        [info.type, info.well, info.focal_distance, info.focal_units, info.detail] = tokens{1}{:};
    elseif strncmpi(tokens{1}{1}, 'autofocusref', length('autofocusref'))
        % My best guess at field names...
        [info.type, info.well, info.focal_distance, info.focal_units, info.position, info.x_position, info.y_position] = tokens{1}{:};
    elseif length(tokens{1}) == 4 || (length(tokens{1}) == 5 && strcmp(tokens{1}{4}, 'badxsgfile'))
        [info.plate, info.well, info.construct, ~] = tokens{1}{:};
    elseif length(tokens{1}) == 9
        [info.plate, info.well, info.buffer, info.drug, info.volume, info.stim_volt, info.stim_pulse, info.illumination, info.trial] = tokens{1}{:};
    elseif length(tokens{1}) == 10
        [info.plate, info.well, info.construct, info.buffer, info.drug, info.volume, info.stim_volt, info.stim_pulse, info.illumination, info.trial] = tokens{1}{:};
    elseif length(tokens{1}) == 11
        % IK replaced 11/16/19: info.illumination not setting properly (not
        % big deal though)
        % [info.plate, info.well, info.construct, info.buffer, info.drug, info.volume, info.stim_volt, info.stim_pulse, ~, info.illumination, info.trial] = tokens{1}{:};
        [info.plate, info.well, info.construct, info.buffer, info.drug, info.volume, info.stim_volt, info.stim_pulse, info.illumination, ~, info.trial] = tokens{1}{:};
    else
        error('Filename parsing failed for: %s', filename);
    end
    
    if isfield(info, 'construct')
        info.construct = regexprep(info.construct, '([0-9])dot([0-9])', '$1.$2');
    end
end
