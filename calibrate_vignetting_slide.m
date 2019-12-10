function [] = calibrate_vignetting_slide(hObject, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    handles = guihandles(hObject);
            
    if ~STL.logistics.simulated & ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents calibrating.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    
    %% Print the test object
    height = 50;
    sz = 400;  % STL.bounds_1(1) / STL.print.zoom_best;
    safety_margin = 10;
    % FIXME also set zoom=?
    
    updateSTLfile(handles, 'STL files/cube.stl');
    set(handles.lockAspectRatio, 'Value', 0);
    if any(STL.print.size ~= [sz sz height])
        set(handles.size1, 'String', sprintf('%d', sz));
        set(handles.size2, 'String', sprintf('%d', sz));
        set(handles.size3, 'String', sprintf('%d', height));
        STL.print.rescale_needed = true;
        update_dimensions(handles);
    end
    update_gui(handles);
    
    %success = true; % Use this to just scan+fit an already-printed cube
    success = print_Callback(hObject, [], handles);
    
    if ~success
        warning('Failed to print. Please fix something.');
        return;
    end
    
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos - (height - 3);
    
    desc = sprintf('%s_%s', get(handles.slide_filename, 'String'), get(handles.slide_filename_series, 'String'));
    
    
    poly_order = 4;

    n_sweeps = 17;
    how_much_to_include = 10; % How many microns +- perpendicular to the direction of the sliding motion
    FOV = 666; % microns
    scanspeed_mms = 0.3; % mm/s of the sliding stage
    frame_rate = 15.21; % Hz
    frame_spacing_um = scanspeed_mms * 1000 / frame_rate;
    

    hSI.hFastZ.enable = 0;
    hSI.hStackManager.numSlices = 1;
    
    xc = STL.print.voxelpos_wrt_fov{1,1,1}.x;
    yc = STL.print.voxelpos_wrt_fov{1,1,1}.y;
    p = STL.print.voxelpower_adjustment;
    save(sprintf('slide_%s_adj', desc), 'xc', 'yc', 'p');

    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        waitbar(0, wbar, 'Measuring polymerisation...', 'CreateCancelBtn', 'cancel_button_callback');
    else
        wbar = waitbar(0, 'Measuring polymerisation...', 'CreateCancelBtn', 'cancel_button_callback');
        set(wbar, 'Units', 'Normalized');
        wp = get(wbar, 'Position');
        wp(1:2) = STL.logistics.wbar_pos(1:2);
        set(wbar, 'Position', wp);
        drawnow;
    end

    if true
        %% First: take a snapshot.
        set(handles.messages, 'String', 'Taking snapshot of current view...');
        
        hSI.hStackManager.framesPerSlice = 100;
        hSI.hScan2D.logAverageFactor = 100;
        hSI.hChannels.loggingEnable = true;
        hSI.hScan2D.logFramesPerFileLock = true;
        hSI.hScan2D.logFileStem = sprintf('slide_%s_image', desc);
        hSI.hScan2D.logFileCounter = 1;
        hSI.hRoiManager.scanZoomFactor = 1;
        
        if ~STL.logistics.simulated
            hSI.startGrab();
            
            while ~strcmpi(hSI.acqState,'idle')
                pause(0.1);
            end
        end
        
        hSI.hScan2D.logAverageFactor = 1;
        hSI.hStackManager.framesPerSlice = 1;
        hSI.hChannels.loggingEnable = false;
    end
    
    if exist('vignetting_cal.tif', 'file')
        tiffCal = double(imread('vignetting_cal.tif'));
    else
        warning('No baseline calibration file ''vignetting_cal.tif'' found.');
        tiffCal = ones(512, 512);
    end
    
    % If the hexapod is in 'rotation' coordinate system,
    % wait for move to finish and then switch to 'ZERO'.
    if STL.motors.hex.connected
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:5), 'LEVEL')
            hexapod_wait();
            STL.motors.hex.C887.KEN('ZERO');
        end
    end
    
    sweep_halfsize = sz/2 + 100; % x halfsize
    sweep_pos = linspace(-(sz/2 - safety_margin - how_much_to_include), (sz/2 - safety_margin - how_much_to_include), n_sweeps); % y positions

    % Positions for the sliding measurements:
    pos = stitching_get_position_um();

    %% Measure brightness along X axis
    
    % This should be in the base leveling coordinate system

    x = [];
    y = [];
    z = [];

    for sweep = 1:n_sweeps
        
        if STL.logistics.abort
            % The caller has to unset STL.logistics.abort
            % (and presumably return).
            disp('Aborting due to user.');
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
            
            move(STL.motors.stitching, pos(1:2), 20);
            hSI.hStackManager.numSlices = 1;
            hSI.hFastZ.enable = false;
            hSI.hBeams.enablePowerBox = false;
            hSI.hRoiManager.scanZoomFactor = 1;
            if ~STL.logistics.simulated
                while ~strcmpi(hSI.acqState,'idle')
                    pause(0.1);
                end
            end
            
            break;
        end

        if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
            waitbar(((sweep+1) / (n_sweeps+1)), wbar, sprintf('Pass %d of %d...', sweep, n_sweeps));
        end
        

        move(STL.motors.stitching, pos(1:2) + [-sweep_halfsize sweep_pos(sweep)], 20);
        set(handles.messages, 'String', sprintf('Sliding along current view (%d/%d)...', sweep, n_sweeps));
        
        % Time taken for the scan will be sweep_halfsize / 100 um/s; frame rate is
        % 15.21 Hz (can't figure out where that is in hSI, but somewhere...)
        scantime = 2*sweep_halfsize / (scanspeed_mms * 1000);
        scanframes = ceil(scantime * frame_rate);
        hSI.hStackManager.framesPerSlice = scanframes;
        hSI.hChannels.loggingEnable = true;
        hSI.hScan2D.logFramesPerFileLock = true;
        hSI.hScan2D.logAverageFactor = 1;
        hSI.hRoiManager.scanZoomFactor = 1;
        hSI.hScan2D.logFileStem = sprintf('sliding', desc);
        hSI.hScan2D.logFileCounter = 1;
        
        if ~STL.logistics.simulated
            hSI.startGrab();
        end
        
        move(STL.motors.stitching, pos(1:2) + [sweep_halfsize sweep_pos(sweep)], scanspeed_mms);
        
        while ~strcmpi(hSI.acqState,'idle')
            pause(0.1);
        end
        
        % Load the file and process it
        
        tiffX = [];
        i = 0;
        try
            while true
                i = i + 1;
                if i == 2
                    tiffX(1000,1,1) = 0;
                end
                t = imread(sprintf('sliding_00001_00001.tif'), i);
                tiffX(i,:,:) = double(t) ./ tiffCal;
            end
        catch ME
        end
        tiffX = tiffX(1:i-1,:,:);
        middle = round(size(tiffX, 3)/2);
        pixelposY = linspace(-FOV/2, FOV/2, size(tiffX, 2));
        indicesY = find(pixelposY > -how_much_to_include ...
            & pixelposY < how_much_to_include);
        
        % Normalise brightness
        scanposX = (0:(size(tiffX, 1) - 1)) * frame_spacing_um - sweep_halfsize;
        baseline_indices = find(scanposX > sz / 2 + 20); % background (well outside the printed object)
        baselineX = mean(mean(tiffX(baseline_indices, indicesY, middle), 2), 1);
        tiffX = tiffX/baselineX;
        bright_x = mean(tiffX(:, indicesY, middle), 2);
        i = find(scanposX > -(sz/2 - safety_margin) & scanposX < (sz/2 - safety_margin));
        x = [x scanposX(i)'];
        y = [y ones(size(i))'*-sweep_pos(sweep)]; % When hexapod (understage) is at y, we're looking at object at -y
        z = [z bright_x(i)];
        
    end

    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        STL.logistics.wbar_pos = get(wbar, 'Position');
        delete(wbar);
    end
    
    
    hSI.hStackManager.framesPerSlice = 1;
    hSI.hChannels.loggingEnable = false;
    move(STL.motors.stitching, pos(1:2), 5);    

    set(handles.messages, 'String', 'Processing fit...');
    [xData, yData, zData] = prepareSurfaceData( x, y, z );
    ft = fittype( sprintf('poly%d%d', poly_order, poly_order ));
    [fitresult, gof] = fit( [xData, yData], zData, ft );
    if ~isfield(STL.calibration, 'vignetting_fit')
        STL.calibration.vignetting_fit = {};
    end
    STL.calibration.vignetting_fit{end+1} = fitresult;
    
    save(sprintf('slide_%s_fit', desc), 'fitresult', 'x', 'y', 'z', 'xData', 'yData', 'zData');
    

    % Show how many calibration functions there are
    %set(handles.menu_clear_vignetting_compensation, ...
    %    'Label', ...
    %    sprintf('Clear vignetting compensation [%d]', length(STL.calibration.vignetting_fit)));
    disp(sprintf('~ You now have %d vignetting compensators.', length(STL.calibration.vignetting_fit)));
    
    if true
        % Plot fit with data.
        figure(41);
        h = plot( fitresult, [xData, yData], zData );
        legend( h, 'untitled fit 1', 'z vs. x, y', 'Location', 'NorthEast' );
        % Label axes
        xlabel x
        ylabel y
        zlabel z
        grid on
        view( -32.7, 15.6 );
    end
    
    set(handles.messages, 'String', '');
    
    
    vigfit = STL.calibration.vignetting_fit;
    save('printimage_last_vignetting_fit', 'vigfit');
    
    %measure_brightness_Callback(hObject, [], handles);
    move(STL.motors.stitching, pos(1:2));
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
end