% THIS IS NOT A REAL M FILE. It won't even process IF THEN ELSE statements,
% just variables as shown here.

STL.print.zstep = .5;     % microns per step in z (vertical)
STL.print.power = 0.8;   % Seems appropriate for 10 W laser, 0.5 um Z, 512 pix Y (hmmm)
STL.calibration.lens_optical_working_distance = 380;
STL.calibration.lens_working_distance_safety_um = 15;


%STL.motors.stitching = 'hex'; % 'mom' or 'hex'. DEFAULT is 'mom'
%STL.motors.special = 'hex_pi'; % 'hex_pi', 'rot_esp301', 'none'. DEFAULT is 'none'

STL.motors.hex.ip_address = '128.223.141.242';
STL.motors.hex.pivot_z_um = 36700;

% On r3D2:
% If brightness increases
%                         as X increases, increase V (pos 5)
%                         as Y increases, increase U (pos 4)
% If stitching stretches objects NW-SE, increase W
%%STL.motors.hex.leveling = [0 0 0 0.28 -0.365 -1.4]; % [ X Y Z U V W ]
%STL.motors.hex.leveling = [0 0 0 0.4 -0.52 -1.4]; % [ X Y Z U V W ]
%STL.motors.hex.leveling = [0 0 0 0 0 0.6]; % [ X Y Z U V W ] DM Edit
%STL.motors.hex.leveling = [0 0 0 .1 .06 0.6]; % [ X Y Z U V W ] RY Edit
STL.motors.hex.leveling = [0 0 0 0 0 1]; % [ X Y Z U V W ] RY edit 8/10/21; W is correct, U & V still unverified

%STL.motors.hex.leveling(4:5) = -(STL.motors.hex.leveling(4:5));

%STL.motors.hex.slide_level = [ 0 0 0 0.255 -0.09 0 ];


%STL.calibration.ScanImage.ScanPhase = -5.8e-6;
STL.calibration.ScanImage.ScanPhase = -1.6583e-06; %RY updated 8/8/21


STL.calibration.pockelsFrequency = 3333333; % Hz

%STL.motors.rot.com_port = 'com4';


STL.motors.mom.understage_centre = [12676 10480 16730]; % Where should MOM aim to see the understage's centre? 
