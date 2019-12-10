function hexapod_set_leveling(varargin)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if ~STL.motors.hex.connected
        return;
    end
    
    foo = hexapod_get_position_um();
    while any(abs(foo(1:3)) > 1)
        foo = questdlg('Please safely move the hexapod to [0 0 0].', ...
            'Stage setup', 'Cancel', 'I did it', 'Do it for me', 'Cancel');
        switch foo
            case 'I did it'
                foo = hexapod_get_position_um();
            case 'Do it for me'
                move('hex', [0 0 0]);
                foo = hexapod_get_position_um();
            case 'Cancel'
                return;
        end
    end

    STL.motors.hex.C887.CCL(1, 'advanced');
    STL.motors.hex.C887.KEN('zero'); % This restores leveling coords
    if nargin == 2
        STL.motors.hex.C887.KLF('level');
    elseif nargin == 1
        disp(sprintf('Setting leveling coords to [ %s]', sprintf('%g ', varargin{1})));
        STL.motors.hex.C887.KLD('level', 'x y z u v w', varargin{1});
    elseif nargin == 0
        disp(sprintf('Setting leveling coords to [ %s]', sprintf('%g ', STL.motors.hex.leveling)));
        STL.motors.hex.C887.KLD('level', 'x y z u v w', STL.motors.hex.leveling);
    end
    %[~,b] = STL.motors.hex.C887.qKEN('')
    %STL.motors.hex.leveling = hexapod_get_position;
    %STL.motors.hex.leveling(1:3) = [0 0 0];
    %STL.motors.hex.C887.KLD('level', 'x y z u v w', STL.motors.hex.leveling);
    STL.motors.hex.C887.KEN('level');
    STL.motors.hex.C887.CCL(0, 'advanced');
end
