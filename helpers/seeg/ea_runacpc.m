function out = ea_runacpc(options)
%     preproc_files = cellfun(@(x) options.subj.preproc.anat.preop.(x), fieldnames(options.subj.preproc.anat.preop), 'uni', 0);
%     app = LeG_ACPCGUI('NiftiFile', preproc_files{1});   % and optionally:
%     out = 1;

    preopFields = fieldnames(options.subj.preproc.anat.preop);

    preprocFiles = cellfun( ...
        @(x) options.subj.preproc.anat.preop.(x), ...
        preopFields, ...
        'UniformOutput', false);

    app = LeG_ACPCGUI('NiftiFile', preprocFiles{1});

    % Stop ea_autocoord here until the AC/PC window is closed.
    waitfor(app.MainFigure);

    % Continue only after the user finishes AC/PC.
    out = 1;
end
