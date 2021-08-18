% logpile stitching automation
% h = printimage in matlab command line before calling
function autostitch_boxes(stepsizex, stepsizey, numstepsx, numstepsy,h)
 global STL;
    handles=guihandles(h);
    start = hexapod_get_position_um();
    pos = hexapod_get_position_um();
    indexbox=0;
    for count1 = 1:numstepsx
        for count2 = 1:numstepsy
            indexbox=indexbox+1;
            hexapod_wait();
            
            [a1,b1,c1]=size(STL.print.metavoxels{1,1,1});
            
            
            nzv=[100 100 200 200 300 300];
            XV =[5 10 5 10 5 10];
            YV=[15 30 15 30 15 30];
            
            nz=nzv(indexbox);
            wx=2; %wall thickness in X
            wy=6; %wall thickness in Y
            B=40; %base thickness in slices

            X=XV(indexbox); %Box dimension in pixels
            Y=YV(indexbox);% Boxdimension in pixels
            Z=nz; %Boxdimension in slices
            bufX=10;% offset of the first box must be larger than wx
            bufY=30;%offset of the first box must be larger than wy
            
            A=array_voxelise(a1,b1,Z,wx,wy,B,X,Y,Z,10,30);
             [a1,b1,c1]=size(STL.print.metavoxels{1,1,1})
            size(A)
           %array_voxelise(lX,lY,lZ,wx,wy,B,X,Y,Z,bufX,bufY,varargin)
           

            
       
            STL.print.voxelpos{1, 1, 1}.z = STL.print.zstep*1:(nz+B);
            STL.print.metavoxels{1,1,1}=A;
            STL.print.metavoxel_resolution{1, 1, 1} = size(STL.print.metavoxels{1, 1, 1}); 
            %print_Callback(h, [], handles);
            
hSI = evalin('base', 'hSI');           
hSI.hRoiManager.scanZoomFactor =2;
hSI.hFastZ.enable = 1;
hSI.hStackManager.numSlices = nz;
hSI.hStackManager.stackZStepSize = -STL.print.zstep;
hSI.hFastZ.flybackTime = 0.025; % SHOULD BE IN MACHINE_DATA_FILE?!?!
hSI.hStackManager.stackReturnHome = false;
hSI.hScan2D.bidirectional = false;
STL.print.voxelise_needed=0;
STL.print.mvx_now=1
STL.print.mvy_now=1
STL.print.mvz_now=1

%evalin('base', 'hSI.startLoop()');

 resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
        hSI.hRoiManager.linesPerFrame ...
       nz];
    if ~isfield(STL.print, 'resolution') | any(resolution ~= STL.print.resolution)
        STL.print.voxelise_needed = true;
    end
    
    

                    
                    % 4a. Await callback from the user function "acqModeDone" or "acqAbort"? Or
                    % constantly poll... :(
                    while ~strcmpi(hSI.acqState,'idle')
                        pause(0.1);
                    end
                    
            
            hexapod_wait();
            pos = pos + [ 0 stepsizey 0 0 0 0 ];
            move('hex', pos);
        end
        pos = pos - (numstepsy*[ 0 stepsizey 0 0 0 0 ]);
        pos = pos + [ stepsizex 0 0 0 0 0 ];
        move('hex', pos);
    end
    move('hex', start);
end
        
        
