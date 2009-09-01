classdef null < py.types.BasePyObject
    methods
        function B = subsref(A, S)
            error('Can''t subsref null pointer');
        end
        
        function A = subsasgn(A, S, V)
            error('Can''t subsasgn null pointer');
        end
        
        function t = type(obj)
            t = py.types.null;
        end
        
        function disp(obj)
            disp('<null>');
        end
    end
end
