function delta_level(level_params)

% Updates coordinate system used by hexapod, to level the hexapod
% 
% Initially queries the coordinate system used when PrintImage is first
% started (stored in STl.motors.hex.leveling), and updates the desired
% leveling parameters. Tracks the coordinate system being used by the
% hexapod after each update to leveling parameters, so that new updates are
% correctly interpreted as relative changes rather than absolute values.
% 
% level_params: 1x6 array with X, Y, Z, U, V, and W hexapod values that
% reflect desired change in level from the current printimage level. X Y Z
% should be kept 0. User should pass in the full 1x6 array, but technically
% only 4th and 5th values (U and V) are modified. Must pass the inverse of
% desired U/V change - e.g., if you find hexapod is level at U = -5 and V =
% 3, pass [0 0 0 5 -3 0].
% 
% 
% NOTE: NEED TO UPDATE THE ABSOLUTE NUMBERS IN PRINTIMAGE_CONFIG WHEN DONE
% if you want to save the level parameters.

global STL

if ~isfield(STL.motors.hex, 'tracklevel')
    STL.motors.hex.tracklevel = STL.motors.hex.leveling;
end

STL.motors.hex.tracklevel(4:5) = STL.motors.hex.tracklevel(4:5) + level_params(4:5);  

fprintf('Changing leveling in U by %d, V by %d.\n', (level_params(4)), (level_params(5))) %is it confusing to 'un-invert' here?

STL.motors.hex.C887.CCL(1, 'advanced');
STL.motors.hex.C887.KEN('zero');
STL.motors.hex.C887.KLD('level', 'x y z u v w', STL.motors.hex.tracklevel);
STL.motors.hex.C887.KEN('level');
STL.motors.hex.C887.CCL(0, 'advanced');

fprintf('To save leveling parameters, change STL.motors.hex.leveling in printimage_config to:\n')
disp(STL.motors.hex.tracklevel)
end