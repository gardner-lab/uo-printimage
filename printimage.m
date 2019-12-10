function varargout = printimage(varargin)
    % PRINTIMAGE MATLAB code for printimage.fig
    %      PRINTIMAGE, by itself, creates a new PRINTIMAGE or raises the existing
    %      singleton*.
    %
    %      H = PRINTIMAGE returns the handle to a new PRINTIMAGE or the handle to
    %      the existing singleton*.
    %
    %      PRINTIMAGE('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in PRINTIMAGE.M with the given input arguments.
    %
    %      PRINTIMAGE('Property','Value',...) creates a new PRINTIMAGE or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before printimage_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to printimage_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help printimage
    
    % Last Modified by GUIDE v2.5 22-Nov-2019 13:15:39
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @printimage_OpeningFcn, ...
        'gui_OutputFcn',  @printimage_OutputFcn, ...
        'gui_LayoutFcn',  [] , ...
        'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
    
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end




function printimage_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    
    clear -global STL;
    global STL;
    
    % Add a menubar
    %hObject.MenuBar = 'none';
    handles.menu_file = uimenu(hObject, 'Label', 'File');
    handles.menu_file_OpenSTL = uimenu(handles.menu_file, 'Label', 'Load STL', 'Callback', @chooseSTL_Callback);
    handles.menu_file_LoadState = uimenu(handles.menu_file, 'Label', 'Load State', 'Callback', @LoadState_Callback);
    handles.menu_file_SaveState = uimenu(handles.menu_file, 'Label', 'Save State', 'Callback', @SaveState_Callback);
    
    handles.menu_calibrate = uimenu(hObject, 'Label', 'Calibrate');
    handles.menu_calibrate_set_hexapod_level =  uimenu(handles.menu_calibrate, 'visible', 'off', 'Label', 'Save hexapod leveling coordinates', 'Callback', @hexapod_set_leveling);
    handles.menu_calibrate_reset_rotation_to_centre = uimenu(handles.menu_calibrate, 'visible', 'off', 'Label', 'Reset hexapod to [ 0 0 0 0 0 0 ]', 'Callback', @hexapod_reset_to_centre);
    handles.menu_calibrate_add_bullseye  = uimenu(handles.menu_calibrate, 'visible', 'off', 'Label', 'MOM--PI alignment', 'Callback', @align_stages);
    handles.menu_calibrate_rotation_centre = uimenu(handles.menu_calibrate, 'visible', 'off', 'Label', 'Save hexapod-centre alignment', 'Callback', @set_stage_true_rotation_centre_Callback);
    handles.menu_calibrate_vignetting_compensation_save_baseline = uimenu(handles.menu_calibrate, 'visible', 'off', 'Label', 'Save baseline image', 'Callback', @calibrate_vignetting_save_baseline_Callback);
    handles.menu_calibrate_vignetting_compensation = uimenu(handles.menu_calibrate, 'visible', 'off', 'Label', 'Calibrate vignetting compensation', 'Callback', @calibrate_vignetting_slide);
    handles.menu_restore_last_vignetting_compensation = uimenu(handles.menu_calibrate, 'Label', 'Restore last vignetting compensation', 'Callback', @calibrate_vignetting_restore);
    handles.menu_clear_vignetting_compensation = uimenu(handles.menu_calibrate, 'Label', 'Clear vignetting compensation', 'Callback', @clear_vignetting_compensation_functions);
    
    handles.menu_test = uimenu(hObject, 'Label', 'Test');
    handles.menu_test_linearity = uimenu(handles.menu_test, 'Label', 'Stitching Stage Linearity', 'Callback', @test_linearity_Callback);
    
    handles.menu_debug = uimenu(hObject, 'Label', 'Debug');
    handles.menu_debug_disarm =  uimenu(handles.menu_debug, 'Label', 'Disarm ScanImage''s PrintImage hook (return control to ScanImage)', 'Callback', @disarm_callback);

    try
        hSI = evalin('base', 'hSI');
        fprintf('Scanimage %s.%s\n', hSI.VERSION_MAJOR, hSI.VERSION_MINOR); % If the fields don't exist, this will throw an error and dump us into simulation mode.
        if isfield(hSI, 'simulated')
            if hSI.simulated
                error('Catch me!');
            end
        end
        STL.logistics.simulated = false;
    catch ME
        % Run in simulated mode.
        
        % To voxelise offline (e.g. big stitching jobs on a fast cluster),
        % the marked parameters should all be grabbed from the hSI
        % structure created by ScanImage on the r3D2 machine, or defined
        % here as you wish and copied manually to the r3D2 machine. FIXME
        % easy to copy to target
        
        % FIXME scanZoomFactor will probably only remain the same with
        % stitched items, for which the auto-zoom doesn't happen. If it
        % does auto-zoom, PrintImage will probably recalculate and
        % revoxelise, but if you're not doing stitching, then voxelising
        % one metavoxel is fast anyway, so there's probably no major need
        % to voxelise on a faster computer.
        STL.logistics.simulated = true;
        STL.logistics.simulated_pos = [ 0 0 0 0 0 0 ];
        hSI.simulated = true;
        hSI.hRoiManager.linesPerFrame = 512; % define here as desired
        hSI.hRoiManager.scanZoomFactor = 2.3; % define here as desired
        hSI.hRoiManager.imagingFovUm = [-333 -333; 0 0; 333 333]; % copy from hSI
        hSI.hScan_ResScanner.fillFractionSpatial = 0.9; % copy from hSI
        hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B = 152; % copy from hSI (available after a Focus)
        hSI.hMotors.motorPosition = 10000 * [ 1 1 1 ];
        STL.motors.hex.range = repmat([-10 10], 6, 1);

        assignin('base', 'hSI', hSI);
    end
    
    set(gcf, 'CloseRequestFcn', @clean_shutdown);
    
    STL.logistics.wbar_pos = [.05 .85];
    hSI.hDisplay.roiDisplayEdgeAlpha = 0.1;

    
    %% From this point onward, STL vars are not supposed to be user-configurable
    
    set_up_params();
    %foo = questdlg(sprintf('Stage rotation centre set to [%s ]. Ok?', ...
    %    sprintf(' %d', STL.motors.mom.understage_centre)), ...
    %    'Stage setup', 'Yes', 'No', 'Yes');
    %switch foo
    %    case 'Yes'
    %        ;
    %    case 'No'
    %        STL.motors.mom.understage_centre = [];
    %end
    
    
    if ~STL.logistics.simulated
        switch STL.motors.special
            case 'hex_pi'
                hexapod_pi_connect();
                set(handles.panel_rotation_hexapod, 'Visible', 'on');
            case 'rot_esp301'
                rot_esp301_connect();
                set(handles.panel_rotation_infinite, 'Visible', 'on');
            case 'none'
                ;
            otherwise
                warning('STL.motors.special: I don''t know what a ''%s'' is.', STL.motors.special);
        end
        
        if STL.motors.hex.connected
            set(handles.menu_calibrate_set_hexapod_level, 'visible', 'on');
            set(handles.menu_calibrate_reset_rotation_to_centre, 'visible', 'on');
            set(handles.menu_calibrate_add_bullseye, 'visible', 'on');
            set(handles.menu_calibrate_rotation_centre, 'visible', 'on');
            set(handles.menu_calibrate_vignetting_compensation, 'visible', 'on');
            set(handles.menu_calibrate_rotation_centre, 'visible', 'on');
            STL.motors.hex.C887.SST('x', .05)
            STL.motors.hex.C887.SST('y', .05)
            STL.motors.hex.C887.SST('z', .01)
        end
    end
    
    
    % ScanImage freaks out if we pass an illegal command to its motor stage
    % controller--and also if I can't move up the required amount, I
    % probably shouldn't drop the fastZ stage. Error out:
    zpos = hSI.hMotors.motorPosition(3);
%     while zpos < 500
%         foo = questdlg('Please safely drop the MOM''s Z axis to at least 500 microns.', ...
%             'Stage setup', 'I did it', 'Cancel');
%         switch foo
%             case 'I did it'
%                 zpos = hSI.hMotors.motorPosition(3);
%             case 'Cancel'
%                 hexapod_pi_disconnect()
%                 return;
%         end
%     end
    
    % Disable this for PI...
    warning('Disabling warning "MATLAB:subscripting:noSubscriptsSpecified" because there will be A LOT of them!');
    evalin('base', 'warning(''off'', ''MATLAB:subscripting:noSubscriptsSpecified'');');
    
    STL.logistics.abort = false; % Bookkeeping; not user-configurable
    
    
    % Some parameters are only computed on grab. So do one.
    hSI.hStackManager.numSlices = 1;
    hSI.hFastZ.enable = false;
    hSI.hFastZ.actuatorLag = 13e-3; % Should calibrate with zstep = whatever you're going to use

    legal_beams = {};
    if STL.logistics.simulated
        STL.motors.mom.understage_centre = [10000 10000 6000];
        STL.motors.hex.tmp_origin = [0 0 0];
        legal_beams = -1;
    else
        evalin('base', 'hSI.startGrab()');
        while ~strcmpi(hSI.acqState, 'idle')
            pause(0.1);
        end
        
        % Get the list of legal beam channels
        for i = 1:length(hSI.hChannels.channelName)
            legal_beams{i} = sprintf('%d', i);
        end
        
        % I'm going to drop the fastZ stage to 420. To make that safe, first
        % I'll move the slow stage up in order to create sufficient clearance
        % (with appropriate error checks).
        foo = hSI.hMotors.motorPosition - [0 0 (STL.print.fastZhomePos - hSI.hFastZ.positionTarget)];
        if foo(3) < 0
            foo(3) = 0;
        end
        move('mom', foo);
        hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
    end
    set(handles.whichBeam, 'String', legal_beams);
    
    
    addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));
%     addlistener(handles.rotate_infinite_slider, 'Value', 'PreSet', @(~,~)rotate_by_slider_show_Callback(hObject, [], handles));
    
    guidata(hObject, handles);
    
    UpdateBounds_Callback([], [], handles);
        
    %hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
    %motorHold(handles, 'reset');
    
    if ~STL.logistics.simulated
        hSI.hFastZ.setHome(0);
    end
    %warning('Setting pixelsPerLine to 64 for faster testing.');
    %hSI.hRoiManager.pixelsPerLine = 64;
    hSI.hScan2D.bidirectional = false;
    hSI.hScan2D.linePhase = STL.calibration.ScanImage.ScanPhase;
    hSI.hScanner.linePhase = STL.calibration.ScanImage.ScanPhase;
    
    colormap(handles.axes2, 'gray');
    
%     imshow('deathstar.png','Parent',handles.axes3);
    
    guidata(hObject, handles);
end


% This sets up default values for user-configurable STL parameters. Then,
% if printimage_config.m exists, we load that, and replace all valid
% parameters' default values with the user-configured versions. If the user
% tries to configure a parameter for which there is no default defined
% here, the user configuration parameter is ignored and a warning issued.
function set_up_params()
    global STL;
    
    STL.print.zstep = 1;     % microns per step in z (vertical)
    STL.print.xaxis = 1;     % axis of raw STL over which the resonant scanner scans
    STL.print.zaxis = 3;     % axis of raw STL over which we print upwards (fastZ etc)
    STL.print.power = 0.5;
    STL.print.whichBeam = 1; % if scanimage gets to play with >1 laser...
    STL.print.size = [400 400 360];
    STL.print.zoom_min = 1;
    STL.print.zoom = 1;
    STL.print.zoom_best = 1;
    STL.print.armed = false;
    STL.preview.resolution = [120 120 120];
    STL.print.metavoxel_overlap = [8 8 8]; % Microns of overlap (positive is more overlap) in order to get good bonding
    STL.print.voxelise_needed = true;
    STL.preview.voxelise_needed = true;
    STL.print.invert_z = false;
    STL.print.motor_reset_needed = false;
    STL.preview.show_metavoxel_slice = NaN;
    STL.print.fastZhomePos = 420;

    STL.motors.stitching = 'hex'; % 'hex' is a hexapod (so far, only hex_pi), 'mom' is Sutter MOM
    STL.motors.special = 'hex_pi'; % So far: 'hex_pi', 'rot_esp301', 'none'
    STL.motors.rot.connected = false;
    STL.motors.rot.com_port = 'com4';
    STL.motors.mom.understage_centre = [12066 1.0896e+04 1.6890e+04];
    STL.motors.hex.user_rotate_velocity = 20;
    STL.motors.hex.pivot_z_um = 24900; % For hexapods, virtual pivot height offset of sample.
    STL.motors.hex.ip_address = '128.223.141.242';
    
    % Hexapod to image: [1 0 0] moves right
    %                   [0 1 0] moves down
    %                   [0 0 1] reduces height
    STL.motors.hex.axis_signs = [ 1 1 -1 ];
    STL.motors.hex.axis_order = [ 1 2 3 ];
    STL.motors.hex.leveling = [0 0 0 0 0 0]; % This leveling zero pos will be manually applied
    %STL.motors.mom.understage_centre = [11240 10547 19479]; % When are we centred over the hexapod's origin?
    STL.motors.hex.slide_level = [ 0 0 0 0 0 0 ]; % Slide is mounted parallel to optical axis
    STL.motors.hex.connected = false;

    % MOM to image: [1 0 0] moves down
    %               [0 1 0] moves left
    %               [0 0 1] reduces height
    % MOM to hex:
    STL.motors.mom.coords_to_hex = [0 1 0; ...
        -1 0 0; ...
        0 0 -1];
    STL.motors.mom.axis_signs = [ -1 1 -1 ];
    STL.motors.mom.axis_order = [ 2 1 3 ];

    % The Zeiss LCI PLAN-NEOFLUAR 25mm has a nominal working depth of
    % 380um.
    STL.calibration.lens_optical_working_distance = 380; % microns, for optical computations
    STL.calibration.lens_working_distance_safety_um = 15; % microns
    STL.calibration.pockelsFrequency = 3333333; % Frequency of Pockels cell controller

    % ScanImage's LinePhase adjustment. Save it here, just for good measure.
    STL.calibration.ScanImage.ScanPhase = 0;
    
    %%%%%
    %% Next, allow the user to override any of these:
    %%%%%
    
    params_file = 'printimage_config'; 
    load_params(params_file, 'STL');
    
    %%%%%
    %% Finally, compute any dependencies:
    %%%%%
    
    zbound = min(STL.calibration.lens_optical_working_distance - STL.calibration.lens_working_distance_safety_um, STL.print.fastZhomePos);
    STL.bounds_1 = [NaN NaN  zbound ];
    STL.print.bounds_max = [NaN NaN  zbound ];
    STL.print.bounds = [NaN NaN  zbound ];

end



function varargout = printimage_OutputFcn(hObject, eventdata, handles)
    varargout{1} = handles.output;
end



function chooseSTL_Callback(hObject, eventdata, handles)
    [FileName,PathName] = uigetfile('*.stl');
    
    if isequal(FileName, 0)
        return;
    end
    
    handles = guidata(gcbo);
    STLfile = strcat(PathName, FileName);
    set(handles.lockAspectRatio, 'Value', 1);
    set(gcf, 'Name', STLfile);
    updateSTLfile(handles, STLfile);
    update_3d_preview(handles);
end



function zslider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end




function printpowerpercent_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.power = str2double(get(hObject, 'String')) / 100;
    STL.print.power = min(max(STL.print.power, 0.01), 1);
    set(hObject, 'String', sprintf('%d', round(100*STL.print.power)));
end


function printpowerpercent_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function powertest_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents printing.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.motor_reset_needed
        set(handles.messages, 'String', 'CRUSH THE THING!!! Reset lens position before printing!');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.logistics.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
    
    %if isfield(STL, 'file') & ~isempty(STL.file) & STL.print.voxelise_needed
    %    voxelise(handles, 'print');
    %else
    %    STL.print.zoom_best = STL.print.zoom;
    %end
    
    hSI.hRoiManager.scanZoomFactor = STL.print.zoom;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
    
    
    gridx = 1;
    gridy = 1;
    gridn = gridx * gridy;
    low = str2double(get(handles.powertest_start, 'String'));
    high = str2double(get(handles.powertest_end, 'String'));
    
    if strcmp(handles.powertest_spacing.SelectedObject.String, 'Log')
        pow_incr = (high/low)^(1/((gridn)-1));
        powers = (low) * pow_incr.^[0:(gridn)-1];
        powers(end) = high; % In case roundoff error resulted in 100.0000001
    else
        powers = linspace(low, high, gridn);
    end
    
    sx = 1/gridx;
    sy = 1/gridy;
    bufferx = 0.025;
    buffery = 0.01;
    
    % A bunch of stuff needs to be set up for this. Should undo it all later!
    oldBeams = hSI.hBeams;
    hSI.hBeams.powerBoxes = hSI.hBeams.powerBoxes([]);
    
    
    for i = 1:gridy
        for j = 1:gridx
            ind = j+gridx*(i-1);
            
            pb.rect = [sx*(j-1)+bufferx sy*(i-1)+buffery sx-2*bufferx sy-2*buffery];
            pb.powers = powers(ind);
            pb.name = sigfig(powers(ind), 2);
            pb.oddLines = 1;
            pb.evenLines = 1;
            
            hSI.hBeams.powerBoxes(ind) = pb;
        end
    end
    
    % 100 microns high
    nframes = 100 / STL.print.zstep;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    %hSI.hFastZ.flybackTime = 25; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false; % This seems useless.
    hSI.hScan2D.bidirectional = false;
    hSI.hStackManager.numSlices = nframes;
    hSI.hBeams.powerLimits = 100;
    hSI.hBeams.enablePowerBox = true;
    
    motorHold(handles, 'on');

    hSI.startLoop();
    
    % Clean up
    while ~strcmpi(hSI.acqState,'idle')
        pause(0.1);
    end
    
    hSI.hBeams.enablePowerBox = false;
    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
    motorHold(handles, 'resetZ');
    
%     if get(handles.focusWhenDone, 'Value')
%         hSI.startFocus();
%     end
end



function powertest_start_Callback(hObject, eventdata, handles)
end


function powertest_start_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function powertest_end_Callback(hObject, eventdata, handles)
end


function powertest_end_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function powertest_spacing_lin_Callback(hObject, eventdata, handles)
end


function build_x_axis_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.preview.voxelise_needed = true;
    STL.print.voxelise_needed = true;
    
    STL.print.xaxis = get(hObject, 'Value');
    if STL.print.zaxis == STL.print.xaxis
        STL.print.zaxis = setdiff([1 2 3], STL.print.xaxis);
        STL.print.zaxis = STL.print.zaxis(1);
    end
    update_dimensions(handles);
end

function build_x_axis_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function build_z_axis_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.preview.voxelise_needed = true;
    STL.print.voxelise_needed = true;
    
    STL.print.valid = 0;
    STL.print.zaxis = get(hObject, 'Value');
    if STL.print.zaxis == STL.print.xaxis
        STL.print.xaxis = setdiff([1 2 3], STL.print.zaxis);
        STL.print.xaxis = STL.print.xaxis(1);
    end
    update_dimensions(handles);
end


function build_z_axis_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject, 'String', {'x', 'y', 'z'});
end



function setFastZ_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
end



function fastZhomePos_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.fastZhomePos = str2double(get(hObject, 'String'));
end


function fastZhomePos_CreateFcn(hObject, eventdata, handles)
    global STL;
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


%function fastZlower_Callback(hObject, eventdata, handles)
%    global STL;
%    hSI = evalin('base', 'hSI');
%    hSI.hFastZ.positionTarget = 420;
%    motorHold(handles, 'reset');
%end


function invert_z_Callback(hObject, eventdata, handles)
    global STL;
    
    set(handles.messages, 'String', 'Inverting Z...');
    
    STL.print.invert_z = get(hObject, 'Value');
    
    STL.print.rescale_needed = true;
    STL.preview.rescale_needed = true;
    update_3d_preview(handles);
    set(handles.messages, 'String', '');
end

function crushThing_Callback(hObject, eventdata, handles)
    hSI = evalin('base', 'hSI');
    motorHold(handles, 'resetZ');
end



function size1_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        update_dimensions(handles, 1, foo);
    end
end

function size1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function size2_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        update_dimensions(handles, 2, foo);
    end
end

function size2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end




function size3_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        update_dimensions(handles, 3, foo);
    end
end

function size3_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function whichBeam_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.whichBeam = get(hObject, 'Value');
end

function whichBeam_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function minGoodZoom_Callback(hObject, eventdata, handles)
    global STL;
    contents = cellstr(get(hObject,'String'));
    STL.print.zoom_min = str2double(contents{get(hObject, 'Value')});
    
    if STL.print.zoom < STL.print.zoom_min
        STL.print.zoom = STL.print.zoom_min;
    end
    
    possibleZooms = STL.print.zoom_min:0.1:6;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%g', possibleZooms(i));
        
        % Allows user choice of zoom to remain unchanged despite the indexing for this widget
        if abs(STL.print.zoom - possibleZooms(i)) < 1e-15
            zoomVal = i;
        end
    end
    
    STL.print.voxelise_needed = true;
    set(handles.printZoom, 'String', foo, 'Value', zoomVal);
    
    UpdateBounds_Callback(hObject, eventdata, handles);
end

function minGoodZoom_CreateFcn(hObject, eventdata, handles)
    % These are just some allowed values. Need 1 sigfig, so just add likely
    % candidates manually... Could do it more cleverly!
    possibleZooms = 1:0.1:2;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%g', possibleZooms(i));
    end
    set(hObject, 'String', foo, 'Value', 1);
end


function printZoom_Callback(hObject, eventdata, handles)
    global STL;
    
    contents = cellstr(get(hObject,'String'));
    STL.print.zoom = str2double(contents{get(hObject, 'Value')});
    
    STL.print.voxelise_needed = true;
    
    UpdateBounds_Callback(hObject, eventdata, handles);
end

function printZoom_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    global STL;
    possibleZooms = 1:0.1:4;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%g', possibleZooms(i));
    end
    set(hObject, 'String', foo, 'Value', 1);
end


function voxelise_preview_button_Callback(hObject, eventdata, handles)
    %update_dimensions(handles);
    zslider_Callback([], [], handles);
    update_3d_preview(handles);
end


function crushReset_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    STL.motors.mom.tmp_origin = move('mom');
    STL.motors.hex.tmp_origin = hexapod_get_position_um();
    STL.print.motor_reset_needed = false;
    set(handles.crushThing, 'BackgroundColor', 0.94 * [1 1 1]);
    set(handles.messages, 'String', '');
end


function abort_Callback(hObject, eventdata, handles)
    global STL;
    STL.logistics.abort = true;
end



function show_metavoxel_slice_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function voxelise_print_button_Callback(hObject, eventdata, handles)
    global STL;
    global wbar;
    
    voxelise(handles, 'print');
    if STL.logistics.abort
        STL.logistics.abort = false;
        set(handles.messages, 'String', 'Canceled.');
        set(handles.show_metavoxel_slice, 'String', 'NaN');
        
        return;
    end
    set(handles.show_metavoxel_slice, 'String', '1 1 1');
    STL.preview.show_metavoxel_slice = [1 1 1];
    zslider_Callback([], [], handles);
end


function test_linearity_Callback(varargin)
    global STL;
    global wbar;
    hSI = evalin('base', 'hSI');
    
    handles = guidata(gcbo);
    
    if ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents your test.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.motor_reset_needed
        set(handles.messages, 'String', 'CRUSH THE THING!!! Reset lens position before printing!');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    hexapos = hexapod_get_position_um();
    if any(abs(hexapos(1:3)) > 0.001)
        set(handles.messages, 'String', 'Hexapod position is [%s ], not [ 0 0 0 ]. Please fix that first');
        return;
    else
        set(handles.messages, 'String', '');
    end

    STL.motors.mom.tmp_origin = move('mom');
    STL.motors.hex.tmp_origin = hexapod_get_position_um();
    eval(sprintf('motor = STL.motors.%s', STL.motors.stitching));
    
    if STL.logistics.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
    
    hSI.hRoiManager.scanZoomFactor = 6;
    userPower = hSI.hBeams.powers;
    hSI.hBeams.powers = 1.3;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
    
    % A bunch of stuff needs to be set up for this. Should undo it all later!
    oldBeams = hSI.hBeams;
    hSI.hBeams.powerBoxes = hSI.hBeams.powerBoxes([]);
    
    ind = 1;
    %pb.rect = [0.46 0.46 0.08 0.08];
    pb.rect = [0.9 0.46 0.08 0.08];
    pb.powers = STL.print.power * 100;
    pb.name = 'hi';
    pb.oddLines = 1;
    pb.evenLines = 1;
    
    hSI.hBeams.powerBoxes(ind) = pb;
    
    nframes = 36;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    %hSI.hFastZ.flybackTime = 25; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false; % This seems useless.
    motorHold(handles, 'on');
    hSI.hScan2D.bidirectional = false;
    hSI.hStackManager.numSlices = nframes;
    hSI.hBeams.powerLimits = 100;
    hSI.hBeams.enablePowerBox = true;
    drawnow;
    
    [X Y] = meshgrid(0:1000:4000, 0:1000:4000);
    posns = [X(1:end) ; Y(1:end)];
    %rng(1234);
    
    metavoxel_counter = 0;
    metavoxel_total = prod(size(X));
    start_time = datetime('now');
    eta = 'next weekend';

        
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        waitbar(0, wbar, 'Printing...', 'CreateCancelBtn', 'cancel_button_callback');
    else
        wbar = waitbar(0, 'Printing...', 'CreateCancelBtn', 'cancel_button_callback');
        set(wbar, 'Units', 'Normalized');
        wp = get(wbar, 'Position');
        wp(1:2) = STL.logistics.wbar_pos(1:2);
        set(wbar, 'Position', wp);
        drawnow;
    end
    
    
    %posns = posns(:, randperm(prod(size(X))));
    posns = posns';
    
    STL.motors.hex.C887.VLS(1);

    for xy = 1:size(posns, 1)
        if STL.logistics.abort
            % The caller has to unset STL.logistics.abort
            % (and presumably return).
            disp('Aborting due to user.');
            move('hex', [ 0 0 ], 20);
            if ishandle(wbar) & isvalid(wbar)
                STL.logistics.wbar_pos = get(wbar, 'Position');
                delete(wbar);
            end
            if exist('handles', 'var');
                set(handles.messages, 'String', 'Canceled.');
                drawnow;
            end
            STL.logistics.abort = false;
            
            STL.print.armed = false;
            hSI.hStackManager.numSlices = 1;
            hSI.hFastZ.enable = false;
            hSI.hBeams.enablePowerBox = false;
            hSI.hRoiManager.scanZoomFactor = 1;
            hSI.hBeams.powers = userPower;
            if ~STL.logistics.simulated
                while ~strcmpi(hSI.acqState,'idle')
                    pause(0.1);
                end
            end
                    
            break;
        end
        
        

        newpos = posns(xy, :) + motor.tmp_origin(1:2);

        move(STL.motors.stitching, newpos, 2);
        
        hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
        
        hSI.startLoop();
        while ~strcmpi(hSI.acqState, 'idle')
            pause(0.1);
        end
        
        metavoxel_counter = metavoxel_counter + 1;
        if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
            current_time = datetime('now');
            eta_date = start_time + (current_time - start_time) / (metavoxel_counter / metavoxel_total);
            if strcmp(datestr(eta_date, 'yyyymmdd'), datestr(current_time, 'yyyymmdd'))
                eta = datestr(eta_date, 'HH:MM:SS');
            else
                eta = datestr(eta_date, 'dddd HH:MM');
            end
            
            waitbar(metavoxel_counter / metavoxel_total, wbar, sprintf('Printing. Done around %s.', eta));
        end
        
    end
    
    % Clean up
    hSI.hBeams.enablePowerBox = false;
    hSI.hRoiManager.scanZoomFactor = 1;
    hSI.hBeams.powers = userPower;
    motorHold(handles, 'resetXYZ');
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        STL.logistics.wbar_pos = get(wbar, 'Position');
        delete(wbar);
    end
end


function lockAspectRatio_Callback(hObject, eventdata, handles)
end


function preview_Callback(hObject, eventdata, handles)
    add_preview(handles);
end

function LoadState_Callback(varargin)
    global STL;
    
    % Some things should not be overwritten by the restored state:
    simulated = STL.logistics.simulated;
    STLmotors = STL.motors;
    
    
    [FileName,PathName] = uigetfile('*.mat');
    
    if isequal(FileName, 0)
        return;
    end
    
    load(strcat(PathName, FileName));
    
    % Restore the current stuff:
    STL.logistics.simulated = simulated;
    STL.motors = STLmotors;
    
    % Pull Y axis voxels from loaded file:
    hSI.hRoiManager.linesPerFrame = STL.print.resolution(2);
    % No need to pull zoom from loaded file, since the selected zoom is
    % stored in the STL, and ScanImage will be informed of it when printing
    % starts... I hope... (?)
    % hSI.hRoiManager.scanZoomFactor = 2.2; % define

    handles = guidata(gcbo);
    STLfile = strcat(PathName, FileName);
    update_gui(handles);
    update_3d_preview(handles);
    draw_slice(handles, get(handles.zslider, 'Value'));
end

function SaveState_Callback(varargin)
    global STL;
    uisave('STL', 'CurrentSTL');
end



function z_step_Callback(hObject, eventdata, handles)
    global STL;
    
    temp = str2double(get(hObject, 'String'));
    temp = floor(10*temp)/10;
    if (temp<0.1)
        temp = 0.1;
    elseif (temp > 10)
        temp = 10;
    end
    
    STL.print.zstep = temp;
    STL.print.voxelise_needed = true;
    set(hObject, 'String', num2str(temp,2));
    
end

function z_step_CreateFcn(hObject, eventdata, handles)
    global STL;
    
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
end



function search_Callback(hObject, eventdata, handles)
    global STL;
    global wbar;
    hSI = evalin('base', 'hSI');
    
    % Save user zoom factor. But at the end, should we restore it? Perhaps
    % not...
    if STL.logistics.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
    hSI.hRoiManager.scanZoomFactor = 1;
    
    if strcmpi(hSI.acqState, 'idle')
        hSI.startFocus();
    end
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        waitbar(0, wbar, 'Searching...', 'CreateCancelBtn', 'cancel_button_callback');
    else
        wbar = waitbar(0, 'Searching...', 'CreateCancelBtn', 'cancel_button_callback');
        set(wbar, 'Units', 'Normalized');
        wp = get(wbar, 'Position');
        wp(1:2) = STL.logistics.wbar_pos(1:2);
        set(wbar, 'Position', wp);
        drawnow;
    end
    
    positions = [];
    
    search_start_pos = hSI.hMotors.motorPosition;
    disp(sprintf('Search starting at [%d %d]', search_start_pos(1), search_start_pos(2)));
    
    motorFastMotionThreshold = Inf;
    stepsize_x = [500 0 0];
    stepsize_y = [0 500 0];
    direction = 1;
    nsteps_needed = 1;
    radius = 0;
    max_radius = 3000; % microns. Approximate due to laziness!
    
    while radius <= max_radius
        
        for nsteps_so_far_this_leg = 1:nsteps_needed
            if STL.logistics.abort
                if ishandle(wbar) & isvalid(wbar)
                    STL.logistics.wbar_pos = get(wbar, 'Position');
                    delete(wbar);
                end
                if exist('handles', 'var');
                    set(handles.messages, 'String', 'Stopped.');
                    drawnow;
                end
                STL.logistics.abort = false;
                return;
            end
            
            move('mom', hSI.hMotors.motorPosition + direction * stepsize_x);
            radius = sqrt(sum((hSI.hMotors.motorPosition(1:2) - search_start_pos(1:2)).^2));
            if radius >= max_radius
                break;
            end
            pause(0.3);
        end
        
        for nsteps_so_far_this_leg = 1:nsteps_needed
            if STL.logistics.abort
                if ishandle(wbar) & isvalid(wbar)
                    STL.logistics.wbar_pos = get(wbar, 'Position');
                    delete(wbar);
                end
                if exist('handles', 'var');
                    set(handles.messages, 'String', 'Stopped.');
                    drawnow;
                end
                STL.logistics.abort = false;
                return;
            end
            
            move('mom', hSI.hMotors.motorPosition + direction * stepsize_y);
            radius = sqrt(sum((hSI.hMotors.motorPosition(1:2) - search_start_pos(1:2)).^2));
            if radius >= max_radius
                break;
            end
            pause(0.3);
        end
        
        %scatter(positions(1,:), positions(2,:), 'Parent', handles.axes2);
        %set(handles.axes2, 'XLim', search_start_pos(1)+[-max_radius max_radius]*1.4, 'YLim', search_start_pos(2)+[-max_radius max_radius]*1.4);
        %drawnow;
        
        pos = hSI.hMotors.motorPosition;
        
        nsteps_needed = nsteps_needed + 1;
        direction = -direction;
    end
    
    if exist('handles', 'var');
        set(handles.messages, 'String', sprintf('Search radius limit %d um exceeded: r = %s um.', max_radius, sigfig(radius)));
        drawnow;
    end
    
    if ishandle(wbar) & isvalid(wbar)
        STL.logistics.wbar_pos = get(wbar, 'Position');
        delete(wbar);
    end
    
end

% This is used to calibrate the MOM-understage positions at 0.
function set_stage_true_rotation_centre_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    STL.motors.mom.understage_centre = hSI.hMotors.motorPosition;
    set(handles.messages, 'String', sprintf('Maybe add ''STL.motors.mom.understage_centre = [%s ]'' to your config.', ...
        sprintf(' %d', STL.motors.mom.understage_centre)));
end


% If the underlying object is rotated, we can servo to its new location (if
% we know the centre of rotation (see set_stage_rotation_centre_Callback).
function track_rotation_Callback(hObject, eventdata, handles)
    angle_deg = str2double(get(hObject, 'String'));
    track_rotation(handles, angle_deg);
end

function track_rotation(handles, angle_deg)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if ~isfield(STL.logistics, 'stage_centre') | isempty(STL.motors.mom.understage_centre)
        set(handles.messages, 'String', 'No stage rotation centre set. Do that first.');
        return;
    end
    
    % Always rotate about the current position!
    pos = hSI.hMotors.motorPosition(1:2);
    pos_relative = pos - STL.motors.mom.understage_centre(1:2);
    
    r = pi*angle_deg/180;
    rm(1:2,1:2) = [cos(r) sin(r); -sin(r) cos(r)];
    pos_relative = pos_relative * rm;
    try
        set(handles.messages, 'String','');
%         set(handles.rotate_infinite_textbox, 'String', '');
        move('mom', pos_relative + STL.motors.mom.understage_centre(1:2));
    catch ME
        ME
        set(handles.messages, 'String', 'The stage is not ready. Slow down!');
        rethrow(ME);
    end
end

function track_rotation_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function focusWhenDone_Callback(hObject, eventdata, handles)
end


function clean_shutdown(varargin)
    global STL;
    global wbar;
        
    try
        hSI = evalin('base', 'hSI');
        hSI.hRoiManager.scanZoomFactor = 1;
    end
    
    try
        fclose(STL.motors.rot.esp301);
    end
    
    %try
        hexapod_pi_disconnect();
    %end
    
    try
        delete(wbar);
    end
    
    clear -global STL;
    
    delete(gcf);
end


function hexapod_reset_to_centre(varargin)
    global STL;
    
    if ~STL.motors.hex.connected
        return;
    end
    
    % If the hexapod is in 'rotation' coordinate system,
    % wait for move to finish and then switch to 'ZERO'.
    [~, b] = STL.motors.hex.C887.qKEN('');
    if ~strcmpi(b(1:5), 'LEVEL')
        hexapod_wait();
        STL.motors.hex.C887.KEN('ZERO');
    end

    STL.motors.hex.C887.VLS(STL.motors.hex.user_rotate_velocity);
    STL.motors.hex.C887.MOV('x y z u v w', [0 0 0 0 0 0]);
    
    handles = guidata(gcbo);

    hexapod_wait(handles);
    update_gui(handles);
end



function hexapod_rotate_x_Callback(hObject, eventdata, handles)
    global STL;
    
    if ~STL.motors.hex.connected
        return;
    end

    hexapod_wait();
    %hexapod_set_rotation_centre_Callback();
    try
        %set(handles.messages, 'String', sprintf('Rotating U to %g', get(hObject, 'Value') * STL.motors.hex.range(4, 2)));
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:8), 'rotation')
            STL.motors.hex.C887.KEN('rotation');
        end
    catch ME
        set(handles.messages, 'String', 'Set the virtual rotation centre first.');
        return;
    end
    
    try
        STL.motors.hex.C887.VLS(STL.motors.hex.user_rotate_velocity);
        STL.motors.hex.C887.MOV('U', get(hObject, 'Value') * STL.motors.hex.range(4, 2));
    catch ME
        set(handles.messages, 'String', 'Given the hexapod''s state, that position is unavailable.');
        update_gui(handles);
    end
    hexapod_wait();
end

function hexapod_rotate_y_Callback(hObject, eventdata, handles)
    global STL;

    if ~STL.motors.hex.connected
        return;
    end

    hexapod_wait();

    %hexapod_set_rotation_centre_Callback();
    try
        %set(handles.messages, 'String', sprintf('Rotating V to %g', get(hObject, 'Value') * STL.motors.hex.range(5, 2)));
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:8), 'rotation')
            STL.motors.hex.C887.KEN('rotation');
        end
        STL.motors.hex.C887.VLS(STL.motors.hex.user_rotate_velocity);
        STL.motors.hex.C887.MOV('V', get(hObject, 'Value') * STL.motors.hex.range(5, 2));
    catch ME
        set(handles.messages, 'String', 'Given the hexapod''s state, that position is unavailable.');
        update_gui(handles);
    end
    hexapod_wait();
end

function hexapod_rotate_z_Callback(hObject, eventdata, handles)
    global STL;
    
    if ~STL.motors.hex.connected
        return;
    end

    %hexapod_set_rotation_centre_Callback();
    hexapod_wait();

    try
        %set(handles.messages, 'String', sprintf('Rotating W to %g', get(hObject, 'Value') * STL.motors.hex.range(6, 2)));
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:8), 'rotation')
            STL.motors.hex.C887.KEN('rotation');
        end

        STL.motors.hex.C887.VLS(STL.motors.hex.user_rotate_velocity);
        STL.motors.hex.C887.MOV('W', get(hObject, 'Value') * STL.motors.hex.range(6, 2));
    catch ME
        set(handles.messages, 'String', 'Given the hexapod''s state, that position is unavailable.');
        update_gui(handles);
    end
    hexapod_wait();
end

function hexapod_rotate_x_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function hexapod_rotate_y_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function hexapod_rotate_z_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

% During a drag of the slider, show the rotation angle that will be used if the drag ends now. This is for infinite-rotation
% devices (e.g. the esp301).
% function rotate_by_slider_show_Callback(hObject, eventdata, handles)
%     spos = get(handles.rotate_infinite_slider, 'Value');
%     sscaled = sign(spos) * 90^abs(spos);
%     set(handles.rotate_infinite_textbox, 'String', sprintf('%.3g', sscaled));
% end
% 
% % Do the actual rotation when the drag ends. For infinite-rotation devices (currently just the esp301).
% function rotate_infinite_slider_Callback(hObject, eventdata, handles)
%     global STL;
%     
%     spos = get(hObject, 'Value');
%     rotangle = sign(spos) * 90^abs(spos);
%     set(handles.rotate_infinite_textbox, 'String', sprintf('Target: %.3g', rotangle));
%     set(handles.rotate_infinite_slider, 'Value', 0);
%     
%     moveto_rel(STL.motors.rot.esp301, 3, -rotangle);
%     track_rotation(handles, rotangle);
% end
% 
% 
% function rotate_infinite_slider_CreateFcn(hObject, eventdata, handles)
%     if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%         set(hObject,'BackgroundColor',[.9 .9 .9]);
%     end
% end


% Set the virtual rotation centre to the point under the microscope lens.
% This is based on STL.motors.mom.understage_centre (MOM's coordinates when
% aligned to hexapod's true centre).
function hexapod_set_rotation_centre_Callback(varargin)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if ~STL.motors.hex.connected
        return;
    end

    head_position_rel = hSI.hMotors.motorPosition - STL.motors.mom.understage_centre;
    head_position_rel = head_position_rel * STL.motors.mom.coords_to_hex;
    head_position_rel(3) = STL.motors.hex.pivot_z_um;
    new_pivot_mm = head_position_rel / 1e3;
    %new_pivot_mm = [0 0 0];
    
    new_pivot_mm = new_pivot_mm .* [-1 -1 1];
    
    [~, b] = STL.motors.hex.C887.qKEN('');
    if ~strcmpi(b(1:5), 'LEVEL')
        hexapod_wait();
        STL.motors.hex.C887.KEN('ZERO');
    end
    
    try
        STL.motors.hex.C887.KSD('rotation', 'x y z', new_pivot_mm);
    catch ME
        rethrow(ME);
    end
end


function add_bullseye_Callback(hObject, eventdata, handles)
    add_bullseye();
end

function align_stages(hObject, eventdata, handles);
    global STL;
    hSI = evalin('base', 'hSI');
    
    % Make sure the hexapod is in the right coordinate system:
    % (2) should be in the Leveling system, (1) reset rotation coordinate
    % system to 0, (3) centre/zero it.

    STL.motors.hex.C887.KSD('rotation', 'X Y Z', [0 0 STL.motors.hex.pivot_z_um / 1e3]);

    [~, b] = STL.motors.hex.C887.qKEN('');
    if ~strcmpi(b(1:5), 'LEVEL')
        hexapod_wait();
        STL.motors.hex.C887.KEN('ZERO');
    end
    hexapod_wait();
    move('hex', [0 0 0 0 0 0], 10);
    hexapod_wait();
    
    handles = guidata(gcbo);
    add_bullseye();
    
    hexapod_reset_to_zero_rotation(handles);

    STL.motors.hex.C887.SPI('X Y Z', [0 0 0]);
end


function hexapod_zero_pos_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if ~STL.motors.hex.connected
        return;
    end
    
    hexapod_wait();
    STL.motors.hex.C887.MOV('X Y Z', [0 0 0]);
end


function clear_vignetting_compensation_functions(hObject, eventdata)
    global STL;
    handles = guihandles(hObject);
    
    % In case I hit the menu item by mistake:
    if isfield(STL.calibration, 'vignetting_fit')
        STL.calibration.vignetting_fit_backup = STL.calibration.vignetting_fit;
    end
    
    STL.calibration.vignetting_fit = {};
    disp('~ You now have no vignetting compensation functions.');
    %set(handles.menu_clear_vignetting_compensation, ...
    %    'Label', ...
    %    sprintf('Clear vignetting compensation [%d]', length(STL.calibration.vignetting_fit)));
end
    

% Obsolete! But saves an image of the blank field...
function calibrate_vignetting_save_baseline_Callback(hObject, eventdata)
        hSI = evalin('base', 'hSI');
        global STL;
        
        handles = guihandles(hObject);
        
        if ~STL.logistics.simulated & ~strcmpi(hSI.acqState,'idle')
            set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents calibrating.');
            return;
        else
            set(handles.messages, 'String', '');
        end
        
        set(handles.messages, 'String', 'Taking snapshot of current view...'); drawnow;
        
        hSI.hStackManager.framesPerSlice = 100;
        hSI.hScan2D.logAverageFactor = 100;
        hSI.hChannels.loggingEnable = true;
        hSI.hScan2D.logFramesPerFileLock = true;
        hSI.hScan2D.logFileStem = 'vignetting_cal';
        hSI.hScan2D.logFileCounter = 1;
        hSI.hRoiManager.scanZoomFactor = 1;
        
        if ~STL.logistics.simulated
            hSI.startGrab();
            
            while ~strcmpi(hSI.acqState,'idle')
                pause(0.1);
            end
        end

        hSI.hStackManager.framesPerSlice = 1;
        hSI.hChannels.loggingEnable = false;
        
        if false
            
            set(handles.messages, 'String', 'Computing fit...'); drawnow;
            
            % Left over from when this was a dropdown on the UI:
            % methods = cellstr(get(handles.vignetting_fit_method, 'String'));
            % method = methods{get(handles.vignetting_fit_method, 'Value')};
            method = 'interpolant';
            
            STL.calibration.vignetting_fit_from_image = fit_vignetting_falloff('vignetting_cal_00001_00001.tif', method, STL.bounds_1(1), handles);
            % Left over for when this was a checkbox
            %set(handles.vignetting_compensation, 'Value', 1, 'ForegroundColor', [0 0 0], ...
            %    'Enable', 'on');
            %STL.print.vignetting_compensation = get(handles.vignetting_compensation, 'Value');
        end
        
        s = get(handles.slide_filename_series, 'String');
        copyfile('vignetting_cal_00001_00001.tif', sprintf('vignetting_cal_%s.tif', s));
        copyfile('vignetting_cal_00001_00001.tif', 'vignetting_cal.tif');
        
        set(handles.messages, 'String', '');
        
end


function vignetting_compensation_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.print.vignetting_compensation = get(hObject, 'Value');
end


function vignetting_fit_method_Callback(hObject, eventdata, handles)
    
end

function vignetting_fit_method_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function calibrate_vignetting_restore(hObject, eventdata, handles)
    global STL;
    
    if exist('printimage_last_vignetting_fit.mat', 'file')
        load('printimage_last_vignetting_fit');
        vigfit
        STL.calibration.vignetting_fit = vigfit;
    else
        error('No previous fit file (printimage_last_vignetting_fit.m) found.');
    end
end


function slide_filename_Callback(hObject, eventdata, handles)
end

function slide_filename_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function centre_mom_Callback(hObject, eventdata, handles)
    global STL;
    set(handles.vignetting_compensation, 'Value', 1, 'ForegroundColor', [0 0 0], ...
        'Enable', 'on');
    move('mom', STL.motors.mom.understage_centre(1:2));
end


function slide_filename_series_Callback(hObject, eventdata, handles)
end

function slide_filename_series_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function brightness_height_Callback(hObject, eventdata, handles)
end

function brightness_height_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function level_slide_Callback(hObject, eventdata, handles)
    global STL;
    STL.motors.hex.C887.MOV('u v', STL.motors.hex.slide_level(4:5));
end

function disarm_callback(hObject, eventdata, handles)
    global STL;
    STL.print.armed = 0;
end

%%
%%%%%%%%%%%%%%%%% Change Hexapod Step Sizes %%%%%%%%%%%%%%%%%%%%

function hex_x_step_Callback(hObject, eventdata, handles)
    global STL;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        STL.motors.hex.C887.SST('x', foo)
    end
end

function hex_x_step_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% Y Step Size:

function hex_y_step_Callback(hObject, eventdata, handles)
    global STL;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        STL.motors.hex.C887.SST('y', foo)
    end
end

function hex_y_step_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% Z Step Size

function hex_z_step_Callback(hObject, eventdata, handles)
    global STL;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        STL.motors.hex.C887.SST('z', foo)
    end
end

function hex_z_step_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

