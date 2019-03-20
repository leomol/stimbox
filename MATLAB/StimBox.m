% 2019-02-25. Leonardo Molina.
% 2019-03-20. Last modified.
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
        
        function bytes = encodeStop()
            bytes = zeros(1, 1, 'uint8');
        end
        
        function bytes = encodeTone(stimPin, startState, duration0, duration1, repetitions, speakerPin, toneDuration, toneFrequency)
            toneDuration = round(toneDuration * 1e6);
            bytes = zeros(1, 23, 'uint8');
            bytes(1) = 1;
            bytes(2:14) = encodePulse(stimPin, startState, duration0, duration1, repetitions);
            bytes(15) = bitand(bitshift(speakerPin,    -00), 255);
            bytes(16) = bitand(bitshift(toneDuration,  -24), 255);
            bytes(17) = bitand(bitshift(toneDuration,  -16), 255);
            bytes(18) = bitand(bitshift(toneDuration,  -08), 255);
            bytes(19) = bitand(bitshift(toneDuration,  -00), 255);
            bytes(20) = bitand(bitshift(toneFrequency, -24), 255);
            bytes(21) = bitand(bitshift(toneFrequency, -16), 255);
            bytes(22) = bitand(bitshift(toneFrequency, -08), 255);
            bytes(23) = bitand(bitshift(toneFrequency, -00), 255);
        end
        
        function bytes = encodeNoise(stimPin, startState, duration0, duration1, repetitions, speakerPin, noiseDuration, noiseMinFrequency, noiseMaxFrequency)
            noiseDuration = round(noiseDuration * 1e6);
            bytes = zeros(1, 27, 'uint8');
            bytes(1) = 2;
            bytes(2:14) = encodePulse(stimPin, startState, duration0, duration1, repetitions);
            bytes(15) = bitand(bitshift(speakerPin,        -00), 255);
            bytes(16) = bitand(bitshift(noiseDuration,     -24), 255);
            bytes(17) = bitand(bitshift(noiseDuration,     -16), 255);
            bytes(18) = bitand(bitshift(noiseDuration,     -08), 255);
            bytes(19) = bitand(bitshift(noiseDuration,     -00), 255);
            bytes(20) = bitand(bitshift(noiseMinFrequency, -24), 255);
            bytes(21) = bitand(bitshift(noiseMinFrequency, -16), 255);
            bytes(22) = bitand(bitshift(noiseMinFrequency, -08), 255);
            bytes(23) = bitand(bitshift(noiseMinFrequency, -00), 255);
            bytes(24) = bitand(bitshift(noiseMaxFrequency, -24), 255);
            bytes(25) = bitand(bitshift(noiseMaxFrequency, -16), 255);
            bytes(26) = bitand(bitshift(noiseMaxFrequency, -08), 255);
            bytes(27) = bitand(bitshift(noiseMaxFrequency, -00), 255);
        end
    end
end
        
function bytes = encodePulse(stimPin, startState, duration0, duration1, repetitions)
    duration0 = round(duration0 * 1e6);
    duration1 = round(duration1 * 1e6);
    bytes = zeros(1, 13, 'uint8');
    bytes(01) = bitor(stimPin, bitshift(startState, 7));
    bytes(02) = bitand(bitshift(duration0,   -24), 255);
    bytes(03) = bitand(bitshift(duration0,   -16), 255);
    bytes(04) = bitand(bitshift(duration0,   -08), 255);
    bytes(05) = bitand(bitshift(duration0,   -00), 255);
    bytes(06) = bitand(bitshift(duration1,   -24), 255);
    bytes(07) = bitand(bitshift(duration1,   -16), 255);
    bytes(08) = bitand(bitshift(duration1,   -08), 255);
    bytes(09) = bitand(bitshift(duration1,   -00), 255);
    bytes(10) = bitand(bitshift(repetitions, -24), 255);
    bytes(11) = bitand(bitshift(repetitions, -16), 255);
    bytes(12) = bitand(bitshift(repetitions, -08), 255);
    bytes(13) = bitand(bitshift(repetitions, -00), 255);
end