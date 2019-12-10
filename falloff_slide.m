function falloff_slide(RELOAD)

% 400e: compensator uses factor 1.
% 400f: compensator uses factor 2.
% 400g: compensator uses factor 1.5.
% 400h: compensator uses factor 1.5, poly order = 4 all through.
% 400i: compensator uses factor 1.5, poly order = 4 all through, +cos^3

collection = '400h'; % Or "series" in the UI, but that's a MATLAB function
sz = 400;

methods = {};
methods{end+1} = 'None';
methods{end+1} = 'Speed';
%methods{end+1} = 'SpeedCos';
%methods{end+1} = 'SpeedCos3';
%methods{end+1} = 'fit';
%methods{end+1} = 'both';
%methods{end+1} = 'both2';
%methods{end+1} = 'type';
methods{end+1} = 'Iteration 1';
methods{end+1} = 'Iteration 2';
%methods{end+1} = 'Iteration 3';


if nargin == 0
    RELOAD = false;
end

methods_long = methods;
how_much_to_include = 0.95; % How much of the printed structure's size perpendicular to the direction of the sliding motion

FOV = 666; % microns
speed = 200; % um/s of the sliding stage
frame_rate = 15.21; % Hz
frame_spacing = speed / frame_rate;
sweep_halfsize = 400;

colours = [0 0 0; ...
    1 0 0; ...
    0 0.5 0; ...
    0 0 1; ...
    0 1 1; ...
    1 1 0];
%colours = distinguishable_colors(length(methods));

image_crop_x = 10;
image_crop_y = 40;

figure(23);
if exist('p', 'var')
    delete(p);
end

p = panel();

last_filename = sprintf('last_falloff_%s.mat', collection);

tic
if RELOAD & exist(last_filename, 'file')
    load(last_filename);
else
    if exist(sprintf('vignetting_cal_%s.tif', collection), 'file')
        tiffCal = double(imread(sprintf('vignetting_cal_%s.tif', collection)));
    elseif exist(sprintf('vignetting_cal_%s_00001_00001.tif', collection), 'file')
        tiffCal = double(imread(sprintf('vignetting_cal_%s_00001_00001.tif', collection)));
    elseif exist(sprintf('vignetting_cal.tif', collection), 'file')
        tiffCal = double(imread('vignetting_cal.tif'));
    else
        warning('No baseline calibration file ''%s'' found.', ...
            sprintf('vignetting_cal_%s.tif', collection));
        tiffCal = ones(512, 512);
    end
    
    for f = 1:length(methods)
        try
            tiffS{f} = double(imread(sprintf('slide_%s_%s_image_00001_00001.tif', methods{f}, collection)));
            disp(sprintf('Loaded ''slide_%s_%s_image_00001_00001.tif''', methods{f}, collection));
            methodsValid(f) = 1;
        catch ME
            disp(sprintf('Could not load ''slide_%s_%s_image_00001_00001.tif''', methods{f}, collection));
            methodsValid(f) = 0;
            continue;
        end
        tiffS{f} = tiffS{f} ./ tiffCal;
        tiffS{f} = tiffS{f}(1+image_crop_y:end-image_crop_y, 1+image_crop_x:end-image_crop_x);
        
        try
            tiffAdj{f} = load(sprintf('slide_%s_%s_adj.mat', methods{f}, collection));
            % Oops. I saved the whole thing, which means one copy per
            % Zstack layer.
            tiffAdj{f}.p = tiffAdj{f}.p(:,:,1);
            
            tiffFit{f} = load(sprintf('slide_%s_%s_fit.mat', methods{f}, collection));
        catch ME
            ME
        end
        
        if false
        
        tiffX{f} = [];
        i = 0;
        try
            while true
                i = i + 1;
                if i == 2
                    tiffX{f}(1000,1,1) = 0;
                end
                t = imread(sprintf('slide_%s_%s_x_00001_00001.tif', methods{f}, collection), i);
                tiffX{f}(i,:,:) = double(t) ./ tiffCal;
            end
        catch ME
        end
        tiffX{f} = tiffX{f}(1:i-1,:,:);
        
        
        middle = round(size(tiffX{f}, 3)/2);
        pixelpos = linspace(-FOV/2, FOV/2, size(tiffX{f}, 2));
        indices = find(pixelpos > -how_much_to_include * sz / 2 ...
            & pixelpos < how_much_to_include * sz / 2);
        
        % Normalise brightness. The starting position (sweep_halfsize) is from
        % printimage.m: how much is the stage commanded to move before
        % starting the acquisition?
        scanposX = (0:(size(tiffX{f}, 1) - 1)) * frame_spacing - sweep_halfsize;
        baseline_indices = find(scanposX > sz / 2 + 20);
        baselineX = mean(mean(tiffX{f}(baseline_indices, indices, middle), 2), 1);
        tiffX{f} = tiffX{f}/baselineX;
        
        % Show the image as scanned
        %imgx = squeeze(tiffX{f}(:, :, middle));
        %imgx = imgx(:, 1+image_crop_y:end-image_crop_y);
        %imagesc(scanposX, 1:size(imgx, 2), imgx');
        
        bright_x(f,:) = mean(tiffX{f}(:, indices, middle), 2);
        bright_x_std(f,:) = std(tiffX{f}(:,indices, middle), [], 2);
        
        
        slid_img_x{f} = tiffX{f}(1:end);
        
        tiffY{f} = zeros(size(tiffX{f}));
        i = 0;
        try
            while true
                i = i + 1;
                t = imread(sprintf('slide_%s_%s_y_00001_00001.tif', methods{f}, collection), i);
                tiffY{f}(i,:,:) = double(t) ./ tiffCal;
            end
        catch ME
        end
                
        % Normalise brightness
        scanposY = (0:(size(tiffX{f}, 1) - 1)) * frame_spacing - sweep_halfsize;
        %baseline_indices = find(scanposY > -50 & scanposY < 50);
        baselineY = mean(mean(tiffY{f}(baseline_indices, middle, indices), 3), 1);
        tiffY{f} = tiffY{f}/baselineY;
        
        
        bright_y(f,:) = mean(tiffY{f}(:, middle, indices), 3);
        bright_y_std(f,:) = std(tiffY{f}(:, middle, indices), [], 3);
        end
    end
    
%    save(last_filename, 'tiffCal', 'tiffX', 'tiffY', ...
%        'tiffS', 'tiffAdj', 'tiffFit', 'scanposX', 'scanposY', ...
%        'baselineX', 'baselineY', 'methodsValid', ...
%        'methods', 'methods_long', 'bright_x', 'bright_y', ...
%        'bright_x_std', 'bright_y_std', 'indices', 'baseline_indices');
end
%disp(sprintf('Loaded data in %d seconds. StdDev n = %d.', round(toc), length(indices)));
disp(sprintf('Loaded data in %d seconds.', round(toc)));


letter = 'c';
for i = find(methodsValid)
    letter = char(letter+1);
    methods2{i} = sprintf('(%c) %s', letter, methods_long{i});
end

p.pack('v', {20 [] }, 1);
p(1,1).marginbottom = 100;
%make_sine_plot_3(p(1,1));
make_sine_plot_4(p(1,1), tiffAdj, methods, methodsValid, colours);



p(2,1).pack(1, sum(methodsValid));

c = 0;
for f = find(methodsValid)
    c = c + 1;
    
    centreX = round(length(tiffAdj{f}.xc) / 2);
    centreY = round(length(tiffAdj{f}.yc) / 2);
    tiffAdj{f}.p = tiffAdj{f}.p / tiffAdj{f}.p(centreX, centreY);
    
    p(2,1, 1,c).pack({24 34 []}, 1);
    h_axes = p(2,1, 1,c, 1,1).select();
    cla;
    
    if exist('tiffAdj', 'var') & length(tiffAdj) >= f & ~isempty(tiffAdj{f})
        if true
            % Show power compensation function as a colormap

            [~,cf] = contourf(tiffAdj{f}.xc, -tiffAdj{f}.yc, tiffAdj{f}.p', 100, ...
                'LineColor', 'none');
            cffig = get(cf, 'Parent');
            set(cffig, 'XTick', [-200 0 200], 'YTick', [-200 0 200], ...
                'YAxisLocation', 'right');
            cffigpos = get(cffig, 'Position');
            %surf(tiffAdj{f}.xc, tiffAdj{f}.yc, tiffAdj{f}.p');
            axis equal xy ;
            
            colo = colorbar('Location', 'WestOutside');
            set(colo, 'Position', (get(colo, 'Position') + [-0.02 0 0 0]) .* [1 0 1 0] + cffigpos .* [0 1 0 0.9]);
            if c == 1
                colo.Label.String = 'Power';
                %title(colo, 'Power');
            end
            if c >= 3
                caxis([0.7 1.8]);
            end
            %caxis([0.2 1.8]);

            title(methods2{f});
        else
            % Show power compensation function as a surface
            
            h = surf(tiffAdj{f}.xc(1:10:end), tiffAdj{f}.yc(1:30:end), ...
                tiffAdj{f}.p(1:10:end,1:30:end)');
            %cffigpos = get(get(cf, 'Parent'), 'Position');
            %surf(tiffAdj{f}.xc, tiffAdj{f}.yc, tiffAdj{f}.p');
            %axis equal ij off;
            %colormap jet;
            %colo = colorbar('Location', 'WestOutside');
            %set(colo, 'Position', get(colo, 'Position') .* [1 0 1 0] + cffigpos .* [0 1 0 1]);
            xlabel('x');
            ylabel('y');
            if c == 1
                zlabel('Power');
            end
            set(gca, 'xlim', [-220 220], 'ylim', [-220 220], 'zlim', [0.5 2], ...
                'xtick', [-200 0 200], 'ytick', [-200 0 200]);
            title(methods2{f});
        end
    end
    
            
    p(2,1, 1,c, 2,1).select();
    cla;
    
    foo = tiffS{f};
    % Manual gain control
    %foo = max(foo - 0.4, 0.65);
    foo = tiffS{f};
    %foo(1,1) = 0; % Stupid kludge: image() isn't scaling right; force imagesc() to do so.
    %foo = min(foo, 1);
    %foo = max(foo, 0.4);
    imagesc(foo);
    caxis([0.37 1]);
    %caxis(-[0.8 0.37]);
    axis tight equal ij off;
    
    p(2,1, 1,c, 3,1).select();
    %h = plot( tiffFit{f}.fitresult );
    %hold on;
    foo = tiffFit{f};
    foo.z = [];
    try 
        for i = 1:2:size(foo.x, 1)
            foo.z(ceil(i/2),:) = mean(tiffFit{f}.z(i:i+1, :), 1);
        end
    end
    s = surf(tiffFit{f}.x(1:2:end,:), tiffFit{f}.y(1:2:end,:), tiffFit{f}.z(1:2:end,:));
    %s = surf(foo.x(1:2:end-1,:), foo.y(1:2:end-1,:), foo.z);
    caxis([0.4 0.6]);
    cffig = get(s, 'Parent');
    set(cffig, 'XTick', [-200 0 200], 'YTick', [-200 0 200]);
    xlabel x
    ylabel y
    if c == 1
        zlabel Brightness
    end
    grid on
    view( -60, 60 );
    set(gca, 'ZLim', [0.4 0.8]);

    drawnow;
end


colormap jet;

if false
    p(3,1).pack(1, {42 42 []}); % Third is for the shared legend
    p(3,1,1,1).select();
    cla;
    h = [];
    hold on;
    
    for f = find(methodsValid)
        H = shadedErrorBar(scanposX, ...
            bright_x(f,:), ...
            1.96*bright_x_std(f,:)/sqrt(length(indices)), ...
            'lineprops', {'Color', colours(f,:)}, ...
            'transparent', 1);
        h(end+1) = H.mainLine;
    end
    hold off;
    axis tight;
    grid on;
    ylimits = get(gca, 'YLim');
    set(gca, 'XLim', [-400 400]);
    
    letter = letter + 1;
    title(sprintf('(%c) X brightness', letter));
    xlabel('\mu{}m');
    ylabel('relative brightness');
    
    p(3,1,1,2).select();
    cla;
    h = [];
    hold on;
    scanposY = (1:size(bright_y, 2)) * frame_spacing - sweep_halfsize;
    for f = 1:length(methods)
        if ~methodsValid(f)
            continue;
        end
        
        H = shadedErrorBar(scanposY, ...
            bright_y(f,:), ...
            1.96*bright_y_std(f,:)/sqrt(length(indices)), ...
            'lineprops', {'Color', colours(f,:)}, ...
            'transparent', 1);
        h(end+1) = H.mainLine;
    end
    hold off;
    axis tight;
    set(gca, 'XLim', [-400 400]);
    grid on;
    %legend(h, methods_long(find(methodsValid)), 'Location', 'EastOutside');
    letter = letter + 1;
    title(sprintf('(%c) Y brightness', letter));
    xlabel('\mu{}m');
    %ylabel('relative brightness');
    
    ylimits2 = get(gca, 'YLim');
    ylimits = [min(ylimits(1), ylimits2(1)) max(ylimits(2), ylimits2(2))];
    set(gca, 'YLim', ylimits);
    p(3,1,1,1).select();
    set(gca, 'YLim', ylimits);
    
    ah = p(3,1,1,3).select();
    axis off;
    l = legend(ah, h, methods_long(find(methodsValid)), 'Location', 'West');
end

%Figure sizing
%pos = get(gcf, 'Position');
%set(gcf, 'Units', 'inches', 'Position', [pos(1) pos(2) 10 8])
%p.export('BeamGraph.png', '-w240', '-a1.1');
%p.export('BeamGraph.eps', '-w240', '-a1.2');
