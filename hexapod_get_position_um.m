function [pos] = hexapod_get_position_um()
    global STL;
    
    if STL.logistics.simulated
        pos = STL.logistics.simulated_pos;
        return;
    end
        
    if ~STL.motors.hex.connected
        pos = NaN * [ 0 0 0 0 0 0 ];
        return;
    end
    
    % If the hexapod is in 'rotation' coordinate system,
    % wait for move to finish and then switch to 'ZERO'.
    [~, b] = STL.motors.hex.C887.qKEN('');
    if ~strcmpi(b(1:5), 'LEVEL')
        hexapod_wait();
        STL.motors.hex.C887.KEN('ZERO');
        hexapod_wait();
    end
    
    pos = STL.motors.hex.C887.qPOS('x y z u v w');
    pos = pos' * diag([1000 1000 1000 1 1 1]);
end
