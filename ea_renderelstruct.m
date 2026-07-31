function [el_render, el_label, elSide] = ea_renderelstruct(options,resultfig,elstruct,pt,el_render,el_label)
% Wrapper function to render lead trajectories based on elstruct
if ~exist('elstruct','var')
    [coords_mm,trajectory,markers] = ea_load_reconstruction(options);
    elstruct(1).coords_mm = coords_mm;
    elstruct(1).trajectory = trajectory;
    elstruct(1).name = options.patientname;
    elstruct(1).markers = markers;
end

if ~exist('pt','var')
    pt = 1;
end

popts = options;
if strcmp(options.leadprod,'group')
    [popts.root, popts.patientname] = fileparts(options.patient_list{pt});
    popts.root = [popts.root, filesep];
    recon = ea_regexpdir([options.patient_list{pt}, filesep, 'reconstruction'], ['^', popts.patientname,'_desc-reconstruction\.mat$'], 0, 'file');
    popts.subj.recon.recon = recon{1};
    popts = ea_detsides(popts);
end

elSide = popts.sides;
el_render = struct([]);
el_label = [];

% Detect LeGUI/SEEG reconstruction from reco structure
isLeGUI = false;

if isfield(popts, 'subj') && ...
        isfield(popts.subj, 'recon') && ...
        isfield(popts.subj.recon, 'recon') && ...
        isfile(popts.subj.recon.recon)

    R = load(popts.subj.recon.recon, 'reco');

    isLeGUI = isfield(R, 'reco') && ...
              isfield(R.reco, 'props') && ...
              ~isempty(R.reco.props) && ...
              ~isfield(R.reco, 'electrode');
end
% If reconmethod is unavailable, inspect reconstruction.mat directly
if ~isLeGUI && isfield(popts, 'subj') && ...
        isfield(popts.subj, 'recon') && ...
        isfield(popts.subj.recon, 'recon') && ...
        isfile(popts.subj.recon.recon)

    R = load(popts.subj.recon.recon, 'reco');

    if isfield(R, 'reco')
        hasStandardDBSElectrode = isfield(R.reco, 'electrode') && ...
                                 ~isempty(R.reco.electrode);

        hasSEEGCoordinates = isfield(R.reco, 'native') && ...
                            isfield(R.reco.native, 'coords_mm') && ...
                            numel(R.reco.native.coords_mm) > 2;

        hasMultipleProps = false;

        if isfield(R.reco, 'props') && ~isempty(R.reco.props)
            try
                if isstruct(R.reco.props) && ...
                        isfield(R.reco.props, 'elmodel')
                    models = string({R.reco.props.elmodel});
                    hasMultipleProps = any(strcmpi(models, "Multiple"));
                end
            catch
            end
        end

        isLeGUI = (~hasStandardDBSElectrode && hasSEEGCoordinates) || ...
                  hasMultipleProps;
    end
end

% LeGUI/SEEG renderer handles all electrode coordinate cells itself
if isLeGUI
    set(0, 'CurrentFigure', resultfig);

    ea_trajectory_seeg(elstruct(pt), popts);

    el_render = struct( ...
        'elpatch', [], ...
        'ellabel', [], ...
        'eltype', []);

    el_label = [];
    return;
end

% for side = elSide
% elSide = popts.sides;
%
% for side=elSide
%     try
%         pobj = ea_load_electrode(options.subj.recon.recon, side);
%         pobj.hasPlanning = 1;
%         pobj.showPlanning = strcmp(options.leadprod,'or');
%     end
%     pobj.pt = pt;
%     pobj.options = popts;
%     pobj.elstruct = elstruct(pt);
%     pobj.showMacro = 1;
%     pobj.side = side;
%
%     set(0,'CurrentFigure',resultfig);
%     if ~exist('el_render','var') || ~isobject(el_render)
%         el_render = struct([]);
%     end
%     if isfield(options, 'reconmethod') && isequal(options.reconmethod, 'LeGUI (Davis 2021)')
%         ea_trajectory(pobj); % Option for if you want to visualize the
%         actual electrodes as opposed to spheres
for side = elSide

    try
        pobj = ea_load_electrode(popts.subj.recon.recon, side);
        pobj.hasPlanning = 1;
        pobj.showPlanning = strcmp(popts.leadprod, 'or');
    catch ME
        warning('Could not load electrode %d: %s', side, ME.message);
        continue;
    end

    pobj.pt = pt;
    pobj.options = popts;
    pobj.elstruct = elstruct(pt);
    pobj.showMacro = 1;
    pobj.side = side;

    set(0, 'CurrentFigure', resultfig);

    if ~exist('el_render', 'var') || isempty(el_render)
        el_render = ea_trajectory(pobj);
    else
        el_render(end+1) = ea_trajectory(pobj);
    end

    if ~exist('el_label', 'var') || isempty(el_label)
        el_label = el_render(end).ellabel;
    else
        el_label(end+1) = el_render(end).ellabel;
    end
end

end