function hexapod_pi_connect()
    global STL;
    
    if ~strcmp(STL.motors.special, 'hex_pi')
        return;
    end
    
    %% Loading the PI_MATLAB_Driver_GCS2
    if     (strfind(evalc('ver'), 'Windows XP'))
        if (~exist('C:\Documents and Settings\All Users\PI\PI_MATLAB_Driver_GCS2','dir'))
            error('The PI_MATLAB_Driver_GCS2 was not found on your system. Probably it is not installed. Please run PI_MATLAB_Driver_GCS2_Setup.exe to install the driver.');
        else
            addpath('C:\Documents and Settings\All Users\PI\PI_MATLAB_Driver_GCS2');
        end
    elseif (strfind(evalc('ver'), 'Windows'))
        if (~exist('C:\Users\Public\PI\PI_MATLAB_Driver_GCS2','dir'))
            error('The PI_MATLAB_Driver_GCS2 was not found on your system. Probably it is not installed. Please run PI_MATLAB_Driver_GCS2_Setup.exe to install the driver.');
        else
            addpath('C:\Users\Public\PI\PI_MATLAB_Driver_GCS2');
        end
    end
    
    if ~isfield(STL, 'motors') | ~isfield(STL.motors, 'hex') | ~isfield(STL.motors.hex, 'Controller')
        STL.motors.hex.Controller = PI_GCS_Controller();
    end;
    
    if(~isa(STL.motors.hex.Controller, 'PI_GCS_Controller'))
        STL.motors.hex.Controller = PI_GCS_Controller();
    end
    
    
    %% Connecting to the C887
    
%     devicesTcpIp = STL.motors.hex.Controller.EnumerateTCPIPDevices()
%     nPI = length(devicesTcpIp);
%     if nPI ~= 1
%         error('%d PI controllers were found on the network. Choose one.');
%     end
%     disp(devicesTcpIp);
    
    
    % Parameters
    % You MUST EDIT AND ACITVATE the parameters to make your system run properly:
    % 1. Activate the connection type
    % 2. Set the connection settings
    
    % Connection settings
    STL.motors.hex.use_RS232_Connection    = false;
    STL.motors.hex.use_TCPIP_Connection    = true;
    
    
    if (STL.motors.hex.use_RS232_Connection)
        STL.motors.hex.comPort = 1;          % Look at the device manager to get the right COM port.
        STL.motors.hex.baudRate = 115200;    % Look at the manual to get the right baud rate for your controller.
    end
    
    if (STL.motors.hex.use_TCPIP_Connection)
        %devicesTcpIp = Controller.EnumerateTCPIPDevices('')
        STL.motors.hex.ip = STL.motors.hex.ip_address;  % Use "devicesTcpIp = Controller.EnumerateTCPIPDevices('')" to get all PI controller available on the network.
        STL.motors.hex.port = 50000;           % Is 50000 for almost all PI controllers
    end
    
    
    %if ~isfield(STL.motors.hex, 'connected') | ~STL.motors.hex.connected
    %try
    %    hexapod_pi_disconnect();
    %catch ME
    %end
    
    % output true of hexapod is already connected
    if (isfield(STL.motors.hex, 'C887')) & STL.motors.hex.C887.IsConnected
        STL.motors.hex.connected = true;
    end
    
    % try to connect if hexapod is not connected
    if (~STL.motors.hex.connected)
        if (STL.motors.hex.use_RS232_Connection)
            STL.motors.hex.C887 = STL.motors.hex.Controller.ConnectRS232(STL.motors.hex.comPort, STL.motors.hex.baudRate);
        end
        
        if (STL.motors.hex.use_TCPIP_Connection)
            STL.motors.hex.C887 = STL.motors.hex.Controller.ConnectTCPIP(STL.motors.hex.ip, STL.motors.hex.port);
        end
    end
    
    %% Configuration and referencing
    
    % Query controller identification
    STL.motors.hex.C887.qIDN()
    
    % Query controller axes
    availableaxes = STL.motors.hex.C887.qSAI_ALL();
    if(isempty(availableaxes))
        error('No axes available');
    end
    
    all_axes = 'X Y Z U V W';

    % Reference stage
    fprintf('Referencing hexapod axes... ');
    if any(STL.motors.hex.C887.qFRF(all_axes) == 0)
        STL.motors.hex.C887.FRF(all_axes);
    end
    
    while any(STL.motors.hex.C887.qFRF(all_axes) == 0)
        pause(0.1);
    end
    
    % This is required to get the range?!?
    STL.motors.hex.C887.CCL(1, 'advanced');
    STL.motors.hex.C887.KEN('zero');
    STL.motors.hex.range = [STL.motors.hex.C887.qTMN(all_axes) STL.motors.hex.C887.qTMX(all_axes)];
    STL.motors.hex.C887.KLD('level', all_axes, STL.motors.hex.leveling);
    STL.motors.hex.C887.KEN('level');
    STL.motors.hex.C887.KEN('PI_Base');
    STL.motors.hex.C887.CCL(0, 'advanced');

    fprintf('done.\n');
    
    % Looks like everything is in order:
    STL.motors.hex.connected = true;
    
    hexapos = hexapod_get_position_um();
%     if any(abs(hexapos(1:3)) > 1)
%         %set(handles.messages, 'String', 'Hexapod position is [%s ], not [ 0 0 0 ].');
%         mompos = move('mom');
%         
%         %error('Ben just added this code. Test it first!');
%         
%         % mompos(3): > is lower, hexapos(3): > is higher
%         mompos(3) = mompos(3) + hexapos(3);
%         if hexapos(3) < 0
%             % Move the hexapod up AFTER the lens makes room
%             move('mom', mompos);
%             move('hex', [0 0 0], 5);
%         else
%             % Move the hexapod down BEFORE the lens follows
%             move('hex', [0 0 0], 5);
%             move('mom', mompos);
%         end
%     else
%         %set(handles.messages, 'String', '');
%     end

    STL.motors.hex.C887.VLS(5);
    hexapod_set_leveling(STL.motors.hex.leveling);
    hexapod_reset_to_zero_rotation();
end
