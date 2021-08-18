% logpile stitching automation
% h = printimage in matlab command line before calling
function autostitchOS(stepsizex, stepsizey, numstepsx, numstepsy,h)
    handles=guihandles(h);
    start = hexapod_get_position_um();
    pos = hexapod_get_position_um();
    for count1 = 1:numstepsx
        for count2 = 1:numstepsy
            hexapod_wait();
            print_Callback(h, [], handles);
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
        
        
