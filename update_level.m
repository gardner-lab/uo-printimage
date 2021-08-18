function update_level(level_params)

%updates the hexapod coordinate system, using level_params as it's "true"
%level

%level_params: 1x6 array with X, Y, Z, U, V, and W hexapod values that
%reflect desired level. X Y Z should be kept 0. 
global STL

fprintf('Changing leveling parameters to:\n')
disp(level_params)

STL.motors.hex.C887.CCL(1, 'advanced');
STL.motors.hex.C887.KEN('zero');
STL.motors.hex.C887.KLD('level', 'x y z u v w', level_params);
STL.motors.hex.C887.KEN('level');
STL.motors.hex.C887.CCL(0, 'advanced');