L=1.2;
POWER=29;

xstart=2.49;
ystart=.4;
zstart=-.086;

for (zs=-.01:.002:.02)
zs
STL.motors.hex.C887.MOV('X Y Z', [xstart ystart zstart+zs]);
%  hSI.hBeams.powers=[.1 POWER];
 hexapod_wait();
STL.motors.hex.C887.MOV('X Y Z', [xstart ystart+L zstart+zs]);
 hexapod_wait();
STL.motors.hex.C887.MOV('X Y Z', [xstart+L ystart+L zstart+zs]);
 hexapod_wait();
STL.motors.hex.C887.MOV('X Y Z', [xstart+L ystart zstart+zs]);
 hexapod_wait();
STL.motors.hex.C887.MOV('X Y Z', [xstart ystart zstart+zs]);
 hexapod_wait();
 
end
STL.motors.hex.C887.MOV('X Y Z', [xstart ystart zstart+zs]);
hexapod_wait();
%  hSI.hBeams.powers=[.1 0];