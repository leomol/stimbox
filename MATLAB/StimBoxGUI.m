% 2019-02-25. Leonardo Molina.
% 2019-02-28. Last modified.
classdef StimBoxGUI < handle
    properties (Access = private)
        handles
        stimBox
        pin = 2
        startState = 1
        colors = struct('success', [1.00, 1.00, 1.00], 'failure', [1.00, 0.25, 0.25])
        
        tone = [2250, 1]
        duration0 = 1
        duration1 = 1
        repetitions = 10
        port = 'COM7'
        status = 'disconnected'
        ticker
    end
    
    properties (Dependent)
        connected
    end
    
    methods
        function obj = StimBoxGUI()
            className = mfilename('class');
            obj.handles.figure = figure('Name', className, 'MenuBar', 'none', 'NumberTitle', 'off', 'CloseRequestFcn', @(~, ~)obj.figureClosed);
            
            w = 150;
            h = 30;
            
            uicontrol('Position', [0, 6 * h, w, h], 'Style', 'Text', 'String', 'Tone duration (s):');
            obj.handles.tone(2) = uicontrol('Position', [w, 6 * h, w, h], 'Style', 'Edit', 'String', sprintf('%d', obj.tone(2)), 'Callback', @(h, ~)obj.validate(h));
            
            uicontrol('Position', [0, 5 * h, w, h], 'Style', 'Text', 'String', 'Tone frequency (Hz):');
            obj.handles.tone(1) = uicontrol('Position', [w, 5 * h, w, h], 'Style', 'Edit', 'String', sprintf('%d', obj.tone(1)), 'Callback', @(h, ~)obj.validate(h));
            
            uicontrol('Position', [0, 4 * h, w, h], 'Style', 'Text', 'String', 'Duration OFF (s):');
            obj.handles.duration0 = uicontrol('Position', [w, 4 * h, w, h], 'Style', 'Edit', 'String', sprintf('%d', obj.duration0), 'Callback', @(h, ~)obj.validate(h));
            
            uicontrol('Position', [0, 3 * h, w, h], 'Style', 'Text', 'String', 'Duration ON (s):');
            obj.handles.duration1 = uicontrol('Position', [w, 3 * h, w, h], 'Style', 'Edit', 'String', sprintf('%d', obj.duration1), 'Callback', @(h, ~)obj.validate(h));
            
            uicontrol('Position', [0, 2 * h, w, h], 'Style', 'Text', 'String', 'Repetitions:');
            obj.handles.repetitions = uicontrol('Position', [w, 2 * h, w, h], 'Style', 'Edit', 'String', sprintf('%d', obj.repetitions), 'Callback', @(h, ~)obj.validate(h));
            
            uicontrol('Position', [0, 1 * h, w, h], 'Style', 'Text', 'String', 'Port:');
            obj.handles.port = uicontrol('Position', [w, 1 * h, w, h], 'Style', 'Edit', 'String', obj.port, 'Callback', @(h, ~)obj.validate(h));
            
            obj.handles.button = uicontrol('Position', [w, 0 * h, w, h], 'Style', 'PushButton', 'String', 'Start', 'Callback', @(h, ~)obj.toggle);
            
            p = obj.handles.figure.Position;
            obj.handles.figure.Position = [p(1), p(2), 2 * w, 7 * h];
            
            obj.updateGUI();
        end
        
        function delete(obj)
            delete(obj.ticker);
            obj.stop();
            pause(5e-3);
            obj.figureClosed();
        end
        
        function success = connect(obj, port)
            h = obj.handles.port;
            if isobject(obj.stimBox) && isvalid(obj.stimBox)
                delete(obj.stimBox);
            end
            try
                obj.stimBox = StimBox(port);
                obj.stimBox.register('DataReceived', @obj.onDataReceived);
                success = true;
            catch e
                errordlg(e.message, sprintf('%s - Error', mfilename('class')), 'modal');
                success = false;
            end
            if success
                obj.port = port;
                h.BackgroundColor = obj.colors.success;
                obj.handles.button.Enable = 'off';
                obj.ticker = Ticker.Delay(@(~, ~)obj.tickerCallback(), 1);
                obj.status = 'connected';
                obj.updateGUI();
            else
                h.String = obj.port;
                h.BackgroundColor = obj.colors.failure;
                obj.status = 'disconnected';
                obj.updateGUI();
            end
        end
        
        function beep(obj)
            Tools.tone(obj.tone(1), obj.tone(2));
        end
        
        function connected = get.connected(obj)
            connected = isobject(obj.stimBox) && isvalid(obj.stimBox.device) && strcmp(obj.stimBox.device.Status, 'open');
        end
        
        function stop(obj)
            obj.write(StimBox.encode(obj.pin, 0, 0, 0, 0));
        end
        
        function start(obj)
            obj.write(StimBox.encode(obj.pin, obj.startState, obj.duration0, obj.duration1, obj.repetitions));
        end
    end
    
    methods (Access = private)

        function tickerCallback(obj)
            obj.stop()
            obj.handles.button.Enable = 'on';
        end
        
        function figureClosed(obj)
            delete(obj.handles.figure);
            delete(obj.stimBox);
        end
        
        function write(obj, bytes)
            if obj.connected
                obj.stimBox.write(bytes);
            end
        end
        
        function onDataReceived(obj, state)
            if state
                obj.beep();
            end
        end
        
        function toggle(obj)
            switch obj.status
                case 'connected'
                    obj.start();
                    obj.status = 'sent';
                    obj.updateGUI();
                case 'idle'
                    if obj.connect(obj.port)
                        obj.status = 'connected';
                    end
                    obj.updateGUI();
                case 'disconnected'
                    obj.connect(obj.port);
                case 'sent'
                    obj.stop();
                    obj.status = 'connected';
                    obj.updateGUI();
            end
        end
        
        function updateGUI(obj)
            switch obj.status
                case {'connected', 'idle'}
                    obj.handles.button.String = 'Start';
                case 'disconnected'
                    obj.handles.button.String = 'Connect';
                case 'sent'
                    obj.handles.button.String = 'Stop';
            end
        end
        
        function validate(obj, h)
            switch h
                case obj.handles.tone(2)
                    [number, success] = validateRange(h.String, 0, 60);
                    if success
                        obj.tone(2) = number;
                        h.BackgroundColor = obj.colors.success;
                    else
                        h.String = sprintf('%.2f', obj.tone(2));
                        h.BackgroundColor = obj.colors.failure;
                    end
                case obj.handles.tone(1)
                    [number, success] = validateRange(h.String, 1e2, 5e3);
                    if success
                        obj.tone(1) = number;
                        h.BackgroundColor = obj.colors.success;
                    else
                        h.String = sprintf('%d', obj.tone(1));
                        h.BackgroundColor = obj.colors.failure;
                    end
                case obj.handles.duration0
                    [number, success] = validateRange(h.String, 0, 4294.95);
                    if success
                        obj.duration0 = number;
                        h.BackgroundColor = obj.colors.success;
                    else
                        h.String = sprintf('%.2f', obj.duration0);
                        h.BackgroundColor = obj.colors.failure;
                    end
                case obj.handles.duration1
                    [number, success] = validateRange(h.String, 0, 4294.95);
                    if success
                        obj.duration1 = number;
                        h.BackgroundColor = obj.colors.success;
                    else
                        h.String = sprintf('%.2f', obj.duration1);
                        h.BackgroundColor = obj.colors.failure;
                    end
                case obj.handles.repetitions
                    [number, success] = validateInteger(h.String, 0, 4294967295);
                    if success
                        obj.repetitions = number;
                        h.BackgroundColor = obj.colors.success;
                    else
                        h.String = sprintf('%.2f', obj.repetitions);
                        h.BackgroundColor = obj.colors.failure;
                    end
                case obj.handles.port
                    obj.connect(h.String);
            end
        end
    end
end

function [number, success] = validateRange(text, minValue, maxValue)
    try
        number = str2double(text);
        success = numel(number) == 1 & ~isnan(number) & ~isinf(number) & number >= minValue & number <= maxValue;
    catch
        number = 0;
        success = false;
    end
end

function [number, success] = validateInteger(text, minValue, maxValue)
    try
        number = str2double(text);
        success = numel(number) == 1 & ~isnan(number) & ~isinf(number) & number >= minValue & number <= maxValue & number == round(number);
    catch
        number = 0;
        success = false;
    end
end