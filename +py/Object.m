classdef Object < handle    
  properties (Hidden)
      pointer
  end
  properties (Access = private, Transient)
      pytype
  end
  
  methods
      function obj = Object(inobj)
          if nargin > 0
              obj = pymex('SCALAR_TO_PYOBJ', inobj);
          else
              obj.pointer = uint64(0);
          end
      end
      
      function delete(obj)
          pymex('DELETE_OBJ', obj);
      end
      
      function objdir = dir(obj)
          objdir = pymex('DIR', obj);
      end
      
      function attr = getattr(obj, attrname)
          attr = pymex('GET_ATTR', obj, attrname);
      end
      
      function item = getitem(obj, key)
          item = pymex('GET_ITEM', obj, key);
      end
      
      function setattr(obj, attrname, val)
          pymex('SET_ATTR', obj, attrname, val);
      end
      
      function setitem(obj, key, val)
          pymex('SET_ITEM', obj, key, val);
      end
      
      function c = char(obj)
          if obj.pointer == uint64(0)
              c = '<null pointer>';
          else
              c = pymex('TO_STR', obj);
          end
      end
      
      function t = type(obj)
          if isempty(obj.pytype)              
              if obj.pointer == uint64(0)
                  t = py.Object();
              else
                  t = pymex('GET_TYPE', obj);
              end
              obj.pytype = t;
          else
              t = obj.pytype;
          end
      end      
      
      function r = call(obj, varargin)
          iskw = cellfun(@(o) isa(o, 'py.kw'), varargin);
          kwargs = [varargin{iskw}];
          args = varargin(~iskw);
          if isempty(kwargs)
              py_kwargs = py.Object;
          else
              py_kwargs = dict(kwargs);
          end
          py_args = py.tuple(args{:});
          r = pymex('CALL', obj, py_args, py_kwargs);
      end
      
      function disp(obj)
          str = char(obj);
          newlines = strfind(str, char(10));
          if numel(newlines) > 5
              fprintf('py.Object %s:\n%s\n...<truncated: too many lines>...\n', char(type(obj)), str(1:newlines(6)-1));
          elseif numel(str) > 500
              fprintf('py.Object %s:\n%s\n...<truncated: too long>...\n', char(type(obj)), str(1:255));
          else
              fprintf('py.Object %s:\n%s\n', char(type(obj)), str);
          end
              
      end
      
      function n = numel(obj, varargin) %#ok<INUSD>
          n = 1;
      end
      
      function tf = iscallable(obj)
          tf = pymex('IS_CALLABLE', obj);
      end
      
      function tf = isinstance(obj, pytype)
          tf = pymex('IS_INSTANCE', obj, pytype);
      end
      
      function pstruct = saveobj(obj)
          pstruct = struct('pickled',false,'string','');
          try
              dumps = getattr(py.import('pickle'), 'dumps');
              pstruct.string = char(call(dumps, obj));
              pstruct.pickled = true;
          catch
              warning('pyobj:pickle', 'could not pickle object');
          end
      end      
      
      function varargout = subsref(obj, S)
          out = obj;
          for i = 1:numel(S)
              switch S(i).type                  
                  case '.'
                      out = getattr(out, S(i).subs);
                  case '()'
                      out = call(out, S(i).subs{:});
                  case '{}'
                      subs = S(i).subs;
                      % Subscript type kludge.
                      % Python demands that list indices be integers. But
                      % mylist{int64(2)} = 5; isn't very aesthetic. So if
                      % an index is an integral float, convert it
                      % automatically to int64. 
                      if isinstance(out, py.builtins('list', 'tuple'))
                          for s = 1:numel(subs)
                              if isfloat(subs{s})
                                  if all(subs{s} - floor(subs{s}) == 0)
                                      subs{s} = int64(subs{s});
                                  end
                              end
                          end
                      end
                      if numel(subs) > 1                          
                          out = getitem(out, py.tuple(subs{:}));
                      else                          
                          out = getitem(out, subs{1});
                      end
                  otherwise
                      error('wtf is "%s" doing in a substruct?', S(i).type);
              end
          end
          if ~(nargout == 0 && py.none().pointer == out.pointer)
              varargout{1} = out;
          end                  
      end
               
      function obj = subsasgn(obj, S, val)
          preS = S(1:end-1);
          S = S(end);
          if strcmp(S.type, '()')
              error('PyObject:BadAssign', 'Invalid lvalue. Can''t assign to expression ending in ().');
          end
          obj = subsref(obj, preS);          
          switch S.type
              case '.'
                  setattr(obj, S.subs, val);
              case '{}'
                  subs = S.subs;
                  if isinstance(obj, py.builtins('list', 'tuple'))
                      for s = 1:numel(subs)
                          if isfloat(subs{s})
                              if all(subs{s} - floor(subs{s}) == 0)
                                  subs{s} = int64(subs{s});
                              end
                          end
                      end
                  end
                  if numel(subs) > 1
                      setitem(obj, py.tuple(subs{:}), val);
                  else
                      setitem(obj, subs{1}, val);
                  end
              otherwise
                  error('wtf is "%s" doing in a substruct?', S.type);
          end
      end                        
  end
  
  methods (Static)
      function pyobj = loadobj(pstruct)
          if ~pstruct.pickled
              pyobj = py.none;
          else
              try
                  loads = getattr(py.import('pickle'), 'loads');
                  pyobj = call(loads, pstruct.string);
              catch
                  pyobj = py.none;
                  warning('pyobj:unpickle', 'could not load pickled object');
              end
          end
      end
  end

end

    
    
