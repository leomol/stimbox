% 2019-02-25. Leonardo Molina.
% 2019-02-28. Last modified.
classdef StimBox < Event
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
            
            StimBox.setDevice(serial(port, 'Baudrate', StimBox.baudrate));
            ticker = Ticker.Repeat(@obj.read, 2 * Ticker.dt);
            StimBox.setTicker(ticker);
            try
                fopen(obj.device);
            catch e
                delete(ticker);
                rethrow(e);
            end
        end
        
        function delete(obj)
            if isvalid(obj.device)
                fclose(obj.device);
                delete(obj.device);
            end
        end
        
        function device = get.device(~)
            device = StimBox.getSession().device;
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
    
    methods (Access = private)
        function read(obj)
            if isvalid(obj.device)
                nb = obj.device.BytesAvailable;
                if nb > 0
                    bytes = fread(obj.device, nb, 'uint8');
                    for b = 1:nb
                        obj.invoke('DataReceived', bytes(b));
                    end
                end
            end
            drawnow();
        end
    end
    
    methods (Static)
        function session = getSession()
            global stimBoxSession;
            if ~isstruct(stimBoxSession)
                port = 'COMX';
                stimBoxSession = struct();
                stimBoxSession.device = serial(port, 'Baudrate', StimBox.baudrate);
                stimBoxSession.device.Timeout = Ticker.dt;
                stimBoxSession.ticker = [];
            end
            session = stimBoxSession;
        end
        
        function setDevice(device)
            global stimBoxSession;
            previousDevice = StimBox.getSession().device;
            if isobject(previousDevice) && isvalid(previousDevice)
                fclose(previousDevice);
                delete(previousDevice);
            end
            stimBoxSession.device = device;
        end
        
        function setTicker(ticker)
            global stimBoxSession;
            previousTicker = StimBox.getSession().ticker;
            if isobject(previousTicker)
                delete(previousTicker);
            end
            stimBoxSession.ticker = ticker;
        end
        
        function bytes = encode(pin, state, duration0, duration1, repetitions)
            duration0 = round(duration0 * 1e6);
            duration1 = round(duration1 * 1e6);
            bytes = zeros(1, 10, 'uint8');
            bytes(01) = bitor(pin, bitshift(state, 7));
            bytes(02) = bitand(bitshift(duration0, -24), 255);
            bytes(03) = bitand(bitshift(duration0, -16), 255);
            bytes(04) = bitand(bitshift(duration0, -08), 255);
            bytes(05) = bitand(bitshift(duration0, -00), 255);
            bytes(06) = bitand(bitshift(duration1, -24), 255);
            bytes(07) = bitand(bitshift(duration1, -16), 255);
            bytes(08) = bitand(bitshift(duration1, -08), 255);
            bytes(09) = bitand(bitshift(duration1, -00), 255);
            bytes(10) = bitand(bitshift(repetitions, -24), 255);
            bytes(11) = bitand(bitshift(repetitions, -16), 255);
            bytes(12) = bitand(bitshift(repetitions, -08), 255);
            bytes(13) = bitand(bitshift(repetitions, -00), 255);
        end
    end
end