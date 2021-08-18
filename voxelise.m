function [] = voxelise(handles, target)

    global STL;
    hSI = evalin('base', 'hSI');
    %warning('Voxelising again (for %s)', target);
    
    global wbar;

    if exist('handles', 'var') & ~isempty(handles)
        set(handles.messages, 'String', sprintf('Re-voxelising %s...', target));
        drawnow;
    end
    
    % For motorstage printing: INTERFACE: set (1) max cube, (2) object size.
    % How many metavoxels are required? Set zoom to maximise fill given
    % the size. FIXME what about X and Y and Z having different fills?
    % Maybe add different zoom scaling for X and Y... later. For now,
    % choose to optimise X, because that's where we need it the most.
    
    % Max cube implies a min zoom level Zmin to eliminate vignetting.
    % If even, (1) zoom to best level >= Zmin and compute voxelisation centres
    % for all points in STL. Then cut a cube out of that and send it to be
    % printed, move stage, etc, iterating over [X Y Z].
    
    % UI variables: (1) Min safe zoom level to eliminate vignetting
    
    % Need to place voxels according to "actual" position given zoom level,
    % rather than normalising everything and zooming, because the latter
    % quantises.
    
    if strcmp(target, 'print') & STL.print.voxelise_needed
        
        
        if exist('hSI', 'var') & ~isempty(fieldnames(hSI.hWaveformManager.scannerAO))
            if ~STL.print.voxelise_needed
                set(handles.messages, 'String', '');
                return;
            end
            % When we create the scan, we must add 0 to the right edge of the
            % scan pattern, so that the flyback is blanked. Or is this
            % automatic?
            
            STL.print.resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
                hSI.hRoiManager.linesPerFrame ...
                round(STL.print.size(3) / STL.print.zstep)];

            
            % 0: compute maximum laser speed. This is the same as the
            % computation below, but for zoom=1. It's all just in aid of
            % finding the maximum speed, so we can scale power
            % appropriately. Yes, could be done elegantly, but
            % cut-and-paste is always elegant ;)
            xc_t = linspace(-1, 1, STL.print.resolution(1)); % On [-1 1] for asin()
            xc_t = xc_t * asin(hSI.hScan_ResScanner.fillFractionSpatial); % Relative times (as phase) for pixel centres
            xc = sin(xc_t); % Locations x = sin(t), t in [-pi/2...pi/2] --> x in [ -1...1], but zoomed in above so x in [-D...D]
            %STL.print.beam_speed_x = cos(xc_t); % Relative speed of focal point = dx/dt = cos(t)
            xc = xc / hSI.hScan_ResScanner.fillFractionSpatial; % Scale to workspace size: step 1 is back to [-1,1]
            xc = (xc + 1) / 2;  % Now on [0, 1]. This is now relative x locations, independent of zoom
            xc = xc * STL.bounds_1(1); % Now spans actual printing workspace (for zoom = 1)
            foo = diff(xc) * STL.calibration.pockelsFrequency;
            STL.calibration.beam_speed_max_um = max(foo);

                        
            % 1. Compute metavoxels based on user-selected print zoom:
            overlap_needed = (STL.print.size > STL.print.bounds);
            nmetavoxels = ceil((STL.print.size - STL.print.metavoxel_overlap) ./ (STL.print.bounds - STL.print.metavoxel_overlap.*overlap_needed));
            
            update_best_zoom(handles);
            
            if STL.logistics.simulated
                user_zoom = 1;
            else
                user_zoom = hSI.hRoiManager.scanZoomFactor;
            end
            hSI.hRoiManager.scanZoomFactor = STL.print.zoom_best;
            fov = hSI.hRoiManager.imagingFovUm;
            hSI.hRoiManager.scanZoomFactor = user_zoom;
            STL.print.bounds_best = STL.print.bounds;
            STL.print.bounds_best([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
            if STL.logistics.simulated
                STL.print.bounds_best([1 2]) = ceil(STL.print.bounds_best([1 2])/STL.print.zoom_best);
            end            

            STL.print.metavoxel_shift = STL.print.bounds_best - STL.print.metavoxel_overlap;
            % 4. Get voxel centres for metavoxel 0,0,0
            
            
            % X (resonant scanner) centres. Correct for sinusoidal
            % velocity. This computes the locations of pixel centres given
            % an origin at 0.
            
            % FIXME We should really compute pixel left-edges for 0-1
            % transitions and right-edges for 1-0. Maybe in the next
            % version.
            xc_t = linspace(-1, 1, STL.print.resolution(1)); % On [-1 1] for asin()
            xc_t = xc_t * asin(hSI.hScan_ResScanner.fillFractionSpatial); % Relative times (as phase) for pixel centres
            xc = sin(xc_t); % Locations x = sin(t), t in [-pi/2...pi/2] --> x in [ -1...1], but zoomed in above so x in [-D...D]
            %STL.print.beam_speed_x = cos(xc_t); % Relative speed of focal point = dx/dt = cos(t)
            xc = xc / hSI.hScan_ResScanner.fillFractionSpatial; % Scale to workspace size: step 1 is back to [-1,1]
            xc = (xc + 1) / 2;  % Now on [0, 1]. This is now relative x locations, independent of zoom
            xc = xc * STL.print.bounds_best(1); % Now spans actual printing workspace
            foo = diff(xc) * STL.calibration.pockelsFrequency;
            foo(end+1) = foo(1);
            
            STL.print.beam_speed_x = foo;
            beam_power_comp_x = ((foo - STL.calibration.beam_speed_max_um) * 0.8 ...
                + STL.calibration.beam_speed_max_um) ...
                / STL.calibration.beam_speed_max_um;

            figure(34);
            subplot(1,2,1);
            plot(1:length(foo), foo/(STL.calibration.beam_speed_max_um), 'r', ...
                1:length(foo), beam_power_comp_x, 'b');
            title('Beam speed vs max');
            legend('speed', 'power');
            set(gca, 'XLim', [1 length(foo)]);
            % Y (galvo) centres. FIXME as above
            yc = linspace(0, STL.print.bounds_best(2), hSI.hRoiManager.linesPerFrame);
            
            % Z centres aren't defined by zoom, but by zstep.
            zc = STL.print.zstep : STL.print.zstep : min([STL.print.bounds(3) STL.print.size(3)]);
            
            % 6. Feed each metavoxel's centres to voxelise
            
            STL.print.nmetavoxels = nmetavoxels;
            
            start_time = datetime('now');
            eta = 'next weekend';

           % if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
            %    waitbar(0, wbar, 'Voxelising...', 'CreateCancelBtn', 'cancel_button_callback');
            %else
            %    wbar = waitbar(0, 'Voxelising...', 'CreateCancelBtn', 'cancel_button_callback');
            %    set(wbar, 'Units', 'Normalized');
            %    wp = get(wbar, 'Position');
            %    wp(1:2) = STL.logistics.wbar_pos(1:2);
            %    set(wbar, 'Position', wp);
            %    drawnow;
            %end
            metavoxel_counter = 0;
            metavoxel_total = prod(STL.print.nmetavoxels);
            STL.print.voxelpos = {};
            STL.print.metavoxel_resolution = {};
            STL.print.metavoxels = {};
            STL.logistics.abort = false;
            
%             parfor mvx = 1:nmetavoxels(1) % parfor threw an error --
%             can't use with an embedded return command
            for mvx = 1:nmetavoxels(1)
                for mvy = 1:nmetavoxels(2)
                    for mvz = 1:nmetavoxels(3)
                        
                        % Voxels for each metavoxel:
                        
                        % Sadly, coordinates for the printed object are currently
                        % on [0,1], not real FOV coords. So this trasform is an
                        % approximation for now. But it's pretty good.
                        STL.print.voxelpos_wrt_fov{mvx, mvy, mvz}.x = xc - xc(end)/2;
                        STL.print.voxelpos_wrt_fov{mvx, mvy, mvz}.y = yc - yc(end)/2;
                        
                        % Positions for the voxels relative to the first
                        % metavoxel
                        STL.print.voxelpos{mvx, mvy, mvz}.x = xc + (mvx - 1) * STL.print.metavoxel_shift(1);
                        STL.print.voxelpos{mvx, mvy, mvz}.y = yc + (mvy - 1) * STL.print.metavoxel_shift(2);
                        STL.print.voxelpos{mvx, mvy, mvz}.z = zc + (mvz - 1) * STL.print.metavoxel_shift(3);
                        
                        xlength = numel(STL.print.voxelpos{mvx, mvy, mvz}.x);
                        ylength = numel(STL.print.voxelpos{mvx, mvy, mvz}.y);
                        zlength = numel(STL.print.voxelpos{mvx, mvy, mvz}.z);
% trial_0=1
% if trial_0 == true
 
if STL.print.ArrayVCad == true
                        A = parVOXELISE(...
                           STL.print.voxelpos{mvx, mvy, mvz}.x, ...
                           STL.print.voxelpos{mvx, mvy, mvz}.y, ...
                           STL.print.voxelpos{mvx, mvy, mvz}.z, ...
                           STL.print.mesh);
else  
                        A = current_VOXELISE(...
                            STL.print.voxelpos{mvx, mvy, mvz}.x, ...
                            STL.print.voxelpos{mvx, mvy, mvz}.y, ...
                            STL.print.voxelpos{mvx, mvy, mvz}.z, ...
                            STL.print.mesh);
end                      
                        % Placement: this lives here because I have
                        % parVOXELISE() checking for STL.logistics.abort as
                        % well---it will terminate early but not reset the
                        % abort flag.
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

                            return;
                        end
                        


                       
                        parfor vx = 1:xlength
                            zvector = A(vx,:,:);
                            for vy = 1:ylength
                                for vz = 1:(zlength-5)
                                    test1 = [zvector(1,vy,vz) ~zvector(1,vy,vz+1) zvector(1,vy,vz+2) zvector(1,vy,vz+3)];
                                    %test2 = [zvector(vz) ~zvector(vz+1) ~zvector(vz+2) zvector(vz+3) zvector(vz+4) zvector(vz+5)];
                                    if all(test1)
                                        zvector(1,vy,vz+1) = 1;
                                    elseif ~any(test1)
                                        zvector(1,vy,vz+1) = 0;
%                                     elseif ~any(test2)
%                                         zvector(vz+1) = 0;
%                                         zvector(vz+2) = 0;
%                                     elseif all(test2)
%                                         zvector(vz+1) = 1;
%                                         zvector(vz+2) = 1;
                                    end
                                end
                                
                            end
                            A(vx,:,:) = zvector;
                        end
                        
                        STL.print.metavoxels{mvx, mvy, mvz} = double(A);
                        %STL.print.metapower{mvx,mvy,mvz} = double(STL.print.metavoxels{mvx, mvy, mvz}) .* speed;
                                                
                        % Delete empty zstack slices if they are above
                        % something that is printed.
                        foo = sum(sum(STL.print.metavoxels{mvx, mvy, mvz}, 1), 2);
                        last_nonzero_slice = find(foo, 1, 'last');
                        STL.print.metavoxels{mvx, mvy, mvz} ...
                            = STL.print.metavoxels{mvx, mvy, mvz}(:, :, 1:last_nonzero_slice);
                        STL.print.voxelpos{mvx, mvy, mvz}.z = STL.print.voxelpos{mvx, mvy, mvz}.z(1:last_nonzero_slice);
                                                
                        % Printing happens at this resolution--we need to set up zstack height etc so printimage_modify_beam()
                        % produces a beam control vector of the right length.
                        STL.print.metavoxel_resolution{mvx, mvy, mvz} = size(STL.print.metavoxels{mvx, mvy, mvz});
                        
                        % Show progress
                        metavoxel_counter = metavoxel_counter + 1;
                        if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
                            current_time = datetime('now');
                            eta_date = start_time + (current_time - start_time) / (metavoxel_counter / metavoxel_total);
                            if strcmp(datestr(eta_date, 'yyyymmdd'), datestr(current_time, 'yyyymmdd'))
                                eta = datestr(eta_date, 'HH:MM:SS');
                            else
                                eta = datestr(eta_date, 'dddd HH:MM');
                            end
                            metavoxel_counter
                            metavoxel_total
                           % waitbar(metavoxel_counter / metavoxel_total, wbar, sprintf('Voxelising. Done around %s.', eta));
                        end                        
                    end
                end
            end

            if false
                figure(12);
                subplot(1,2,1);
                hold on;
                v = STL.print.metavoxels{1,1,1} .* speed(:,:,1:size(STL.print.metavoxels{1,1,1}, 3));
                vnot = (v > 0.01);
                v(vnot) = v(vnot) + 0.5*(1 - v(vnot));
                plot(v(:,256,10));
                hold off;
                legend('Pure cos', 'Vignetting', 'Combined', 'Ad-hoc');
                ylim([0.8 1.2]);
            end
            
            if STL.logistics.abort
                STL.logistics.abort = false;
            else
                STL.print.voxelise_needed = false;
                STL.print.valid = true;
            end
            
            if exist('handles', 'var') & ~isempty(handles)
                set(handles.messages, 'String', '');
                draw_slice(handles, 1);
                drawnow;
            end
            
            if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
                STL.logistics.wbar_pos = get(wbar, 'Position');
                delete(wbar);
            end

            
        else
            if exist('handles', 'var') & ~isempty(handles)
                set(handles.messages, 'String', 'Could not voxelise for printing: run an acquire first.');
            else
                warning('Could not voxelise for printing: run an acquire first.');
            end
        end
    elseif strcmp(target, 'preview') & STL.preview.voxelise_needed
        if ~STL.preview.voxelise_needed
            set(handles.messages, 'String', '');
            return;
        end

        STL.preview.resolution = [120 120 round(STL.print.size(3) / STL.print.zstep)];
        STL.preview.voxelpos.x = linspace(0, STL.print.size(1), STL.preview.resolution(1));
        STL.preview.voxelpos.y = linspace(0, STL.print.size(2), STL.preview.resolution(2));
        STL.preview.voxelpos.z = 0 : STL.print.zstep : STL.print.size(3);
        
        STL.preview.voxels = VOXELISE(STL.preview.voxelpos.x, ...
            STL.preview.voxelpos.y, ...
            STL.preview.voxelpos.z, ...
            STL.print.mesh);
        
        STL.preview.voxelise_needed = false;
        
        % Discard empty slices. This will hopefully be only the final slice, or
        % none. This might be nice for eliminating that last useless slice, but we
        % can't do that from printimage_modify_beam since the print is already
        % running.
        STL.preview.voxels = STL.preview.voxels(:, :, find(sum(sum(STL.preview.voxels, 1), 2) ~= 0));
        STL.preview.resolution(3) = size(STL.preview.voxels, 3);
    end
    
    if exist('handles', 'var') & ~isempty(handles)
        set(handles.messages, 'String', '');
        drawnow;
    end
            
    % Save what we've done... just in case...
    %disp('Saving voxelised file as LastVoxelised.mat');
    %save('LastVoxelised_dont_remove_this_until_last_one_is_rescued', 'STL');
end

% was used instead of the parfor after parVOXELISE, keeping it as backup    
function zvector = smoothen(zvector)
    for i=2:(numel(zvector)-3)
%         test1 = [zvector(i) ~zvector(i+1) ~zvector(i+2) zvector(i+3) zvector(i+4) zvector(i+5)];
%         if ~any(test1)
%             zvector(i+1) = 0;
%             zvector(i+2) = 0;
%         end
%         if all(test1)
%             zvector(i+1) = 1;
%             zvector(i+2) = 1;
%         end
        test2 = [zvector(i) ~zvector(i+1) zvector(i+2) zvector(i+3)];
        if all(test2)
            zvector(i+1) = 1;
        elseif ~any(test2)
            zvector(i+1) = 0;
        end
    end
end
