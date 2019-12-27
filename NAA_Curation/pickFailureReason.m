function r = pickFailureReason(well)
    reasons = FailureReason.all();
    [choice, ok] = listdlg('PromptString', ['Why did well ' well.name ' fail?'], ...
                           'SelectionMode', 'single', ...
                           'ListSize', [240 200], ...
                           'ListString', {reasons.name});
    if ok
        r = reasons(choice);
    else
        r = [];
    end
end
