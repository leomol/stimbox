% 2019-02-25. Leonardo Molina.
% 2019-02-25. Last modified.
classdef StimBox < handle
    properties (Constant)
        baudrate = 115200
    end
    
    properties (Dependent)
        device
    end
    
    methods
        function obj = StimBox(port)
            % StimBox(port)
            % Create a connection to the given serial port.
            
            delete(obj.device);
            StimBox.setSession(struct('device', serial(port, 'Baudrate', StimBox.baudrate)));
            fopen(obj.device);
        end
        
        function delete(obj)
            if isvalid(obj.device)
                fclose(obj.device);
                delete(obj.device);
            end
        end
        
        function device = get.device(~)
            session = StimBox.getSession();
            device = session.device;
        end
        
        function write(obj, varargin)
            % StimBox.write(bytes)
            % Write bytes to the serial port.
            data = cat(1, varargin{:});
            if numel(data) > 0
                data = max(0, min(255, data));
                data = cast(data, 'double');
                fwrite(obj.device, data, 'uint8');
            end
        end
    end
    
    methods (Static)
        function session = getSession()
            global stimBoxSession;
            if ~isstruct(stimBoxSession)
                port = 'COMX';
                stimBoxSession = struct('device', serial(port, 'Baudrate', StimBox.baudrate));
            end
            session = stimBoxSession;
        end
        
        function setSession(session)
            global stimBoxSession;
            stimBoxSession = session;
        end
        
        function bytes = encode(pin, state, duration0, duration1, repetitions)
            duration0 = round(duration0 * 1e3);
            duration1 = round(duration1 * 1e3);
            bytes = zeros(1, 10, 'uint8');
            bytes(01) = bitor(pin, bitshift(state, 7));
            bytes(02) = bitand(bitshift(duration0, -16), 255);
            bytes(03) = bitand(bitshift(duration0, -08), 255);
            bytes(04) = bitand(bitshift(duration0, -00), 255);
            bytes(05) = bitand(bitshift(duration1, -16), 255);
            bytes(06) = bitand(bitshift(duration1, -08), 255);
            bytes(07) = bitand(bitshift(duration1, -00), 255);
            bytes(08) = bitand(bitshift(repetitions, -16), 255);
            bytes(09) = bitand(bitshift(repetitions, -08), 255);
            bytes(10) = bitand(bitshift(repetitions, -00), 255);
        end
    end
end