%% MEGATRUSS
% Large scale hexapod and piezo driven print
% Version 2020 03 12
%
% h = printimage in matlab command line before calling
% function megatruss(stepsizex, stepsizey, numstepsx, numstepsy,h)
%     handles=guihandles(h);
%note, use h=printimage to access GUI data below
function megatruss(Vlaser,VelocityX,PX)
global STL


 %1) Setup the laser raster only with zoom of choice
    %note base values to return to.
    
    %set to desired
    Vraster=Vlaser;
    %Vzoom=
    %Vgalvo = 0
    
 %2) Hex
    %Hex velocity
    %Hex distance in assuming raster is in the y direction

        start = hexapod_get_position_um(); %get inital location to return to
%     pos=start;
%     pos = pos + [ 0 1 0 0 0 0 ];
%     move('hex', pos);

      STL.motors.hex.C887.VLS(VelocityX);
      STL.motors.hex.C887.MOV('X', PX); 

%       hexapod_wait();
    
    
%     %turn back on later, code from Aaron for doing multiple steps
%     pos = hexapod_get_position_um();
%     for count1 = 1:numstepsx
%         for count2 = 1:numstepsy
%             hexapod_wait();
%             print_Callback(h, [], handles);
%             hexapod_wait();
%             pos = pos + [ 0 stepsizey 0 0 0 0 ];
%             move('hex', pos);
%         end
%         pos = pos - (numstepsy*[ 0 stepsizey 0 0 0 0 ]);
%         pos = pos + [ stepsizex 0 0 0 0 0 ];
%         move('hex', pos);
%     end
    
%     move('hex', start);
end
        
        
