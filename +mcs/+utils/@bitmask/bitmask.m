classdef bitmask < handle
    %
    %   Class:
    %   mcs.utils.bitmask
    %
    %   The purpose of this class is to facilitate entering of values for
    %   bit masks.
    %
    %   See Also
    %   --------
    %   mcs.stg.trigger
    
    properties (Hidden)
        fh
    end
    
    properties (SetObservable)
        values %array
        %This is the main property of this class
        %This stores the bit mask
        %e.g. setting bit 5 only would show up here as the value 16
        %since 1 => 1   (bit # => numeric value)
        %      2 => 2
        %      3 => 4
        %      4 => 8
        %      5 => 16, etc.
        
    end
    
    properties (Dependent)
        expanded_values
    end
    
    methods
        function value = get.expanded_values(obj)
            switch class(obj.values)
                case 'uint32'
                    n_max = 32;
                case 'uint64'
                    n_max = 64;
                otherwise
                    error('Unexpected type')
            end
            value = arrayfun(@(x) find(bitget(x,1:n_max)),obj.values,'un',0);
            value(cellfun('isempty',value)) = {[]};
        end
        function set.expanded_values(obj,value)
            %
            %d.trigger_settings.channel_maps.expanded_values{3} = 1:4
            
            if ~iscell(value)
                error('Input to expanded values must be a cell array')
            end
            
            obj.values = h__expandedToValue(obj,obj.fh,value);
        end
    end
    
    methods
        function obj = bitmask(value,varargin)
            %
            %   Inputs
            %   ------
            %   value : cell or array
            %       Array values are interpreted as being raw, but must
            %       use 'raw' flag
            %
            %   Optional Inputs
            %   ---------------
            %   raw : default false
            %       - true - input values are interpreted as being a
            %                bitmask => 5 => [0 1 0 1]
            %       - false - values are interpreted as comprising a set
            %                 which generates the bitmask
            %                           5 => [1 0 0 0 0];
            %   type : default 'uint32'
            %       The output data type. Set this based on the function
            %       you need to pass the bit mask to. Currently I think 
            %       the only type needed is 'uint32'
            %
            %   Example
            %   ---------------
            %   %Create an array where the first value
            %   %has:
            %   %#1 - first 4 bits set
            %   %#2 - bit 5
            %   %#3 - bit 6
            %   b = mcs.utils.bitmask({[1,2,3,4],5,6});
            %
            %   %Verification of 0 working
            %   b = mcs.utils.bitmask({1,0,6});
            %
            %   %Empty is ok as well
            %   temp = cell(1,4);
            %   temp{2} = [1 2];
            %   b = mcs.utils.bitmask(temp);
            %
            %   
            
            in.raw = false;
            in.type = 'uint32';
            in = mcs.sl.in.processVarargin(in,varargin);
            
            if in.raw
                
                switch class(value)
                    case 'uint32'
                        obj.fh = @uint32;
                    case 'uint64'
                        error('Not yet implemented')
                        obj.fh = @uint64;
                    case 'double'
                        %Find max and guess class if double ...
                        %Default to uint32 where possible
                        error('Not yet implemented')
                    otherwise
                        error('Type not supported')
                end
                
                obj.values = value;
            else
                if ~iscell(value)
                    error('Non-raw values must be input as a cell array')
                end
                
                %Determine fh
                %----------------------
                switch in.type
                    case 'uint32'
                        fh = @uint32;
                    case 'uint64'
                        fh = @uint64;
                        %64 bits is messy in terms of the conversion
                        %because of using double which doesn't have
                        %64 value bits
                        %=> I think we can get 2^64, but I'm not sure
                        %about overflow on summation ... - might
                        %need a loop ...
                        error('Not yet implemented')
                    otherwise
                        error('Option not recognized')
                end
                
                obj.fh = fh;
                
                %The actual conversion
                %--------------------------
                
                obj.values = h__expandedToValue(obj,fh,value);
            end
        end
        
        %TODO: These are not yet implemented
        %         function enableBits(obj,indices)
        %
        %         end
        %         function disableBits(obj,indices)
        %         end
    end
    
end

function value = h__expandedToValue(obj,fh,expanded_values)
%   TODO: The conversion approach might fail with uint64
%   since we are using double for the calculation

expanded_values(cellfun('isempty',expanded_values)) = {0};

value = cellfun(@(x) fh(sum(floor(2.^(x - 1)))),expanded_values);

%{
    expanded_values = {1:64};
    fh = @uint64;
    value = cellfun(@(x) fh(sum(floor(2.^(x - 1)))),expanded_values);
    dec2bin(value) => incorrect
    
%}


end

