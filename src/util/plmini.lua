








local pl = {}







----------------
--- Lua 5.1/5.2/5.3 compatibility.
-- Ensures that `table.pack` and `package.searchpath` are available
-- for Lua 5.1 and LuaJIT.
-- The exported function `load` is Lua 5.2 compatible.
-- `compat.setfenv` and `compat.getfenv` are available for Lua 5.2, although
-- they are not always guaranteed to work.
-- @module pl.compat

local compat = {}

compat.lua51 = _VERSION == 'Lua 5.1'

local isJit = (tostring(assert):match('builtin') ~= nil)
if isJit then
    -- 'goto' is a keyword when 52 compatibility is enabled in LuaJit
    compat.jit52 = not loadstring("local goto = 1")
end

compat.dir_separator = _G.package.config:sub(1,1)
compat.is_windows = compat.dir_separator == '\\'

--- execute a shell command.
-- This is a compatibility function that returns the same for Lua 5.1 and Lua 5.2
-- @param cmd a shell command
-- @return true if successful
-- @return actual return code
function compat.execute (cmd)
    local res1,_,res3 = os.execute(cmd)
    if compat.lua51 and not compat.jit52 then
        if compat.is_windows then
            res1 = res1 > 255 and res1 % 256 or res1
            return res1==0,res1
        else
            res1 = res1 > 255 and res1 / 256 or res1
            return res1==0,res1
        end
    else
        if compat.is_windows then
            res3 = res3 > 255 and res3 % 256 or res3
            return res3==0,res3
        else
            return not not res1,res3
        end
    end
end

----------------
-- Load Lua code as a text or binary chunk.
-- @param ld code string or loader
-- @param[opt] source name of chunk for errors
-- @param[opt] mode 'b', 't' or 'bt'
-- @param[opt] env environment to load the chunk in
-- @function compat.load

---------------
-- Get environment of a function.
-- With Lua 5.2, may return nil for a function with no global references!
-- Based on code by [Sergey Rozhenko](http://lua-users.org/lists/lua-l/2010-06/msg00313.html)
-- @param f a function or a call stack reference
-- @function compat.getfenv

---------------
-- Set environment of a function
-- @param f a function or a call stack reference
-- @param env a table that becomes the new environment of `f`
-- @function compat.setfenv

if compat.lua51 then -- define Lua 5.2 style load()
    if not isJit then -- but LuaJIT's load _is_ compatible
        local lua51_load = load
        function compat.load(str,src,mode,env)
            local chunk,err
            if type(str) == 'string' then
                if str:byte(1) == 27 and not (mode or 'bt'):find 'b' then
                    return nil,"attempt to load a binary chunk"
                end
                chunk,err = loadstring(str,src)
            else
                chunk,err = lua51_load(str,src)
            end
            if chunk and env then setfenv(chunk,env) end
            return chunk,err
        end
    else
        compat.load = load
    end
    compat.setfenv, compat.getfenv = setfenv, getfenv
else
    compat.load = load
    -- setfenv/getfenv replacements for Lua 5.2
    -- by Sergey Rozhenko
    -- http://lua-users.org/lists/lua-l/2010-06/msg00313.html
    -- Roberto Ierusalimschy notes that it is possible for getfenv to return nil
    -- in the case of a function with no globals:
    -- http://lua-users.org/lists/lua-l/2010-06/msg00315.html
    function compat.setfenv(f, t)
        f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
        local name
        local up = 0
        repeat
            up = up + 1
            name = debug.getupvalue(f, up)
        until name == '_ENV' or name == nil
        if name then
            debug.upvaluejoin(f, up, function() return name end, 1) -- use unique upvalue
            debug.setupvalue(f, up, t)
        end
        if f ~= 0 then return f end
    end

    function compat.getfenv(f)
        local f = f or 0
        f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
        local name, val
        local up = 0
        repeat
            up = up + 1
            name, val = debug.getupvalue(f, up)
        until name == '_ENV' or name == nil
        return val
    end
end

--- Lua 5.2 Functions Available for 5.1
-- @section lua52

--- pack an argument list into a table.
-- @param ... any arguments
-- @return a table with field n set to the length
-- @return the length
-- @function table.pack
--if not table.pack then
    function table.pack (...)
        return {n=select('#',...); ...}
    end
--end

------
-- return the full path where a Lua module name would be matched.
-- @param mod module name, possibly dotted
-- @param path a path in the same form as package.path or package.cpath
-- @see path.package_path
-- @function package.searchpath
if not package.searchpath then
    local sep = package.config:sub(1,1)
    function package.searchpath (mod,path)
        mod = mod:gsub('%.',sep)
        for m in path:gmatch('[^;]+') do
            local nm = m:gsub('?',mod)
            local f = io.open(nm,'r')
            if f then f:close(); return nm end
        end
    end
end






--- Generally useful routines.
-- See  @{01-introduction.md.Generally_useful_functions|the Guide}.
--
-- Dependencies: `pl.compat`
--
-- @module pl.utils
local format = string.format
local stdout = io.stdout
local append = table.insert
local unpack = rawget(_G,'unpack') or rawget(table,'unpack')

local utils = {
    _VERSION = "1.5.2",
    lua51 = compat.lua51,
    setfenv = compat.setfenv,
    getfenv = compat.getfenv,
    load = compat.load,
    execute = compat.execute,
    dir_separator = compat.dir_separator,
    is_windows = compat.is_windows,
    unpack = unpack
}

--- end this program gracefully.
-- @param code The exit code or a message to be printed
-- @param ... extra arguments for message's format'
-- @see utils.fprintf
function utils.quit(code,...)
    if type(code) == 'string' then
        utils.fprintf(io.stderr,code,...)
        code = -1
    else
        utils.fprintf(io.stderr,...)
    end
    io.stderr:write('\n')
    os.exit(code)
end

--- print an arbitrary number of arguments using a format.
-- @param fmt The format (see string.format)
-- @param ... Extra arguments for format
function utils.printf(fmt,...)
    utils.assert_string(1,fmt)
    utils.fprintf(stdout,fmt,...)
end

--- write an arbitrary number of arguments to a file using a format.
-- @param f File handle to write to.
-- @param fmt The format (see string.format).
-- @param ... Extra arguments for format
function utils.fprintf(f,fmt,...)
    utils.assert_string(2,fmt)
    f:write(format(fmt,...))
end

local function import_symbol(T,k,v,libname)
    local key = rawget(T,k)
    -- warn about collisions!
    if key and k ~= '_M' and k ~= '_NAME' and k ~= '_PACKAGE' and k ~= '_VERSION' then
        utils.fprintf(io.stderr,"warning: '%s.%s' will not override existing symbol\n",libname,k)
        return
    end
    rawset(T,k,v)
end

local function lookup_lib(T,t)
    for k,v in pairs(T) do
        if v == t then return k end
    end
    return '?'
end

local already_imported = {}

--- take a table and 'inject' it into the local namespace.
-- @param t The Table
-- @param T An optional destination table (defaults to callers environment)
function utils.import(t,T)
    T = T or _G
    t = t or utils
    if type(t) == 'string' then
        t = require (t)
    end
    local libname = lookup_lib(T,t)
    if already_imported[t] then return end
    already_imported[t] = libname
    for k,v in pairs(t) do
        import_symbol(T,k,v,libname)
    end
end

utils.patterns = {
    FLOAT = '[%+%-%d]%d*%.?%d*[eE]?[%+%-]?%d*',
    INTEGER = '[+%-%d]%d*',
    IDEN = '[%a_][%w_]*',
    FILE = '[%a%.\\][:%][%w%._%-\\]*'
}

--- escape any 'magic' characters in a string
-- @param s The input string
function utils.escape(s)
    utils.assert_string(1,s)
    return (s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'))
end

--- return either of two values, depending on a condition.
-- @param cond A condition
-- @param value1 Value returned if cond is true
-- @param value2 Value returned if cond is false (can be optional)
function utils.choose(cond,value1,value2)
    if cond then return value1
    else return value2
    end
end

local raise

--- return the contents of a file as a string
-- @param filename The file path
-- @param is_bin open in binary mode
-- @return file contents
function utils.readfile(filename,is_bin)
    local mode = is_bin and 'b' or ''
    utils.assert_string(1,filename)
    local f,open_err = io.open(filename,'r'..mode)
    if not f then return utils.raise (open_err) end
    local res,read_err = f:read('*a')
    f:close()
    if not res then
        -- Errors in io.open have "filename: " prefix,
        -- error in file:read don't, add it.
        return raise (filename..": "..read_err)
    end
    return res
end

--- write a string to a file
-- @param filename The file path
-- @param str The string
-- @param is_bin open in binary mode
-- @return true or nil
-- @return error message
-- @raise error if filename or str aren't strings
function utils.writefile(filename,str,is_bin)
    local mode = is_bin and 'b' or ''
    utils.assert_string(1,filename)
    utils.assert_string(2,str)
    local f,err = io.open(filename,'w'..mode)
    if not f then return raise(err) end
    f:write(str)
    f:close()
    return true
end

--- return the contents of a file as a list of lines
-- @param filename The file path
-- @return file contents as a table
-- @raise errror if filename is not a string
function utils.readlines(filename)
    utils.assert_string(1,filename)
    local f,err = io.open(filename,'r')
    if not f then return raise(err) end
    local res = {}
    for line in f:lines() do
        append(res,line)
    end
    f:close()
    return res
end

--- split a string into a list of strings separated by a delimiter.
-- @param s The input string
-- @param re A Lua string pattern; defaults to '%s+'
-- @param plain don't use Lua patterns
-- @param n optional maximum number of splits
-- @return a list-like table
-- @raise error if s is not a string
function utils.split(s,re,plain,n)
    utils.assert_string(1,s)
    local find,sub,append = string.find, string.sub, table.insert
    local i1,ls = 1,{}
    if not re then re = '%s+' end
    if re == '' then return {s} end
    while true do
        local i2,i3 = find(s,re,i1,plain)
        if not i2 then
            local last = sub(s,i1)
            if last ~= '' then append(ls,last) end
            if #ls == 1 and ls[1] == '' then
                return {}
            else
                return ls
            end
        end
        append(ls,sub(s,i1,i2-1))
        if n and #ls == n then
            ls[#ls] = sub(s,i1)
            return ls
        end
        i1 = i3+1
    end
end

--- split a string into a number of values.
-- @param s the string
-- @param re the delimiter, default space
-- @return n values
-- @usage first,next = splitv('jane:doe',':')
-- @see split
function utils.splitv (s,re)
    return unpack(utils.split(s,re))
end

--- convert an array of values to strings.
-- @param t a list-like table
-- @param temp buffer to use, otherwise allocate
-- @param tostr custom tostring function, called with (value,index).
-- Otherwise use `tostring`
-- @return the converted buffer
function utils.array_tostring (t,temp,tostr)
    temp, tostr = temp or {}, tostr or tostring
    for i = 1,#t do
        temp[i] = tostr(t[i],i)
    end
    return temp
end

local is_windows = utils.is_windows

--- Quote an argument of a command.
-- Quotes a single argument of a command to be passed
-- to `os.execute`, `pl.utils.execute` or `pl.utils.executeex`.
-- @string argument the argument.
-- @return quoted argument.
function utils.quote_arg(argument)
    if is_windows then
        if argument == "" or argument:find('[ \f\t\v]') then
            -- Need to quote the argument.
            -- Quotes need to be escaped with backslashes;
            -- additionally, backslashes before a quote, escaped or not,
            -- need to be doubled.
            -- See documentation for CommandLineToArgvW Windows function.
            argument = '"' .. argument:gsub([[(\*)"]], [[%1%1\"]]):gsub([[\+$]], "%0%0") .. '"'
        end

        -- os.execute() uses system() C function, which on Windows passes command
        -- to cmd.exe. Escape its special characters.
        return (argument:gsub('["^<>!|&%%]', "^%0"))
    else
        if argument == "" or argument:find('[^a-zA-Z0-9_@%+=:,./-]') then
            -- To quote arguments on posix-like systems use single quotes.
            -- To represent an embedded single quote close quoted string ('),
            -- add escaped quote (\'), open quoted string again (').
            argument = "'" .. argument:gsub("'", [['\'']]) .. "'"
        end

        return argument
    end
end

--- execute a shell command and return the output.
-- This function redirects the output to tempfiles and returns the content of those files.
-- @param cmd a shell command
-- @param bin boolean, if true, read output as binary file
-- @return true if successful
-- @return actual return code
-- @return stdout output (string)
-- @return errout output (string)
function utils.executeex(cmd, bin)
    local mode
    local outfile = os.tmpname()
    local errfile = os.tmpname()

    if is_windows and not outfile:find(':') then
        outfile = os.getenv('TEMP')..outfile
        errfile = os.getenv('TEMP')..errfile
    end
    cmd = cmd .. " > " .. utils.quote_arg(outfile) .. " 2> " .. utils.quote_arg(errfile)

    local success, retcode = utils.execute(cmd)
    local outcontent = utils.readfile(outfile, bin)
    local errcontent = utils.readfile(errfile, bin)
    os.remove(outfile)
    os.remove(errfile)
    return success, retcode, (outcontent or ""), (errcontent or "")
end

--- 'memoize' a function (cache returned value for next call).
-- This is useful if you have a function which is relatively expensive,
-- but you don't know in advance what values will be required, so
-- building a table upfront is wasteful/impossible.
-- @param func a function of at least one argument
-- @return a function with at least one argument, which is used as the key.
function utils.memoize(func)
    local cache = {}
    return function(k)
        local res = cache[k]
        if res == nil then
            res = func(k)
            cache[k] = res
        end
        return res
    end
end


utils.stdmt = {
    List = {_name='List'}, Map = {_name='Map'},
    Set = {_name='Set'}, MultiMap = {_name='MultiMap'}
}

local _function_factories = {}

--- associate a function factory with a type.
-- A function factory takes an object of the given type and
-- returns a function for evaluating it
-- @tab mt metatable
-- @func fun a callable that returns a function
function utils.add_function_factory (mt,fun)
    _function_factories[mt] = fun
end

local function _string_lambda(f)
    local raise = utils.raise
    if f:find '^|' or f:find '_' then
        local args,body = f:match '|([^|]*)|(.+)'
        if f:find '_' then
            args = '_'
            body = f
        else
            if not args then return raise 'bad string lambda' end
        end
        local fstr = 'return function('..args..') return '..body..' end'
        local fn,err = utils.load(fstr)
        if not fn then return raise(err) end
        fn = fn()
        return fn
    else return raise 'not a string lambda'
    end
end

--- an anonymous function as a string. This string is either of the form
-- '|args| expression' or is a function of one argument, '_'
-- @param lf function as a string
-- @return a function
-- @usage string_lambda '|x|x+1' (2) == 3
-- @usage string_lambda '_+1' (2) == 3
-- @function utils.string_lambda
utils.string_lambda = utils.memoize(_string_lambda)

local ops

--- process a function argument.
-- This is used throughout Penlight and defines what is meant by a function:
-- Something that is callable, or an operator string as defined by <code>pl.operator</code>,
-- such as '>' or '#'. If a function factory has been registered for the type, it will
-- be called to get the function.
-- @param idx argument index
-- @param f a function, operator string, or callable object
-- @param msg optional error message
-- @return a callable
-- @raise if idx is not a number or if f is not callable
function utils.function_arg (idx,f,msg)
    utils.assert_arg(1,idx,'number')
    local tp = type(f)
    if tp == 'function' then return f end  -- no worries!
    -- ok, a string can correspond to an operator (like '==')
    if tp == 'string' then
        if not ops then ops = require 'pl.operator'.optable end
        local fn = ops[f]
        if fn then return fn end
        local fn, err = utils.string_lambda(f)
        if not fn then error(err..': '..f) end
        return fn
    elseif tp == 'table' or tp == 'userdata' then
        local mt = getmetatable(f)
        if not mt then error('not a callable object',2) end
        local ff = _function_factories[mt]
        if not ff then
            if not mt.__call then error('not a callable object',2) end
            return f
        else
            return ff(f) -- we have a function factory for this type!
        end
    end
    if not msg then msg = " must be callable" end
    if idx > 0 then
        error("argument "..idx..": "..msg,2)
    else
        error(msg,2)
    end
end

--- bind the first argument of the function to a value.
-- @param fn a function of at least two values (may be an operator string)
-- @param p a value
-- @return a function such that f(x) is fn(p,x)
-- @raise same as @{function_arg}
-- @see func.bind1
function utils.bind1 (fn,p)
    fn = utils.function_arg(1,fn)
    return function(...) return fn(p,...) end
end

--- bind the second argument of the function to a value.
-- @param fn a function of at least two values (may be an operator string)
-- @param p a value
-- @return a function such that f(x) is fn(x,p)
-- @raise same as @{function_arg}
function utils.bind2 (fn,p)
    fn = utils.function_arg(1,fn)
    return function(x,...) return fn(x,p,...) end
end


--- assert that the given argument is in fact of the correct type.
-- @param n argument index
-- @param val the value
-- @param tp the type
-- @param verify an optional verification function
-- @param msg an optional custom message
-- @param lev optional stack position for trace, default 2
-- @raise if the argument n is not the correct type
-- @usage assert_arg(1,t,'table')
-- @usage assert_arg(n,val,'string',path.isdir,'not a directory')
function utils.assert_arg (n,val,tp,verify,msg,lev)
    if type(val) ~= tp then
        error(("argument %d expected a '%s', got a '%s'"):format(n,tp,type(val)),lev or 2)
    end
    if verify and not verify(val) then
        error(("argument %d: '%s' %s"):format(n,val,msg),lev or 2)
    end
end

--- assert the common case that the argument is a string.
-- @param n argument index
-- @param val a value that must be a string
-- @raise val must be a string
function utils.assert_string (n,val)
    utils.assert_arg(n,val,'string',nil,nil,3)
end

local err_mode = 'default'

--- control the error strategy used by Penlight.
-- Controls how <code>utils.raise</code> works; the default is for it
-- to return nil and the error string, but if the mode is 'error' then
-- it will throw an error. If mode is 'quit' it will immediately terminate
-- the program.
-- @param mode - either 'default', 'quit'  or 'error'
-- @see utils.raise
function utils.on_error (mode)
    if ({['default'] = 1, ['quit'] = 2, ['error'] = 3})[mode] then
      err_mode = mode
    else
      -- fail loudly
      if err_mode == 'default' then err_mode = 'error' end
      utils.raise("Bad argument expected string; 'default', 'quit', or 'error'. Got '"..tostring(mode).."'")
    end
end

--- used by Penlight functions to return errors.  Its global behaviour is controlled
-- by <code>utils.on_error</code>
-- @param err the error string.
-- @see utils.on_error
function utils.raise (err)
    if err_mode == 'default' then return nil,err
    elseif err_mode == 'quit' then utils.quit(err)
    else error(err,2)
    end
end

--- is the object of the specified type?.
-- If the type is a string, then use type, otherwise compare with metatable
-- @param obj An object to check
-- @param tp String of what type it should be
function utils.is_type (obj,tp)
    if type(tp) == 'string' then return type(obj) == tp end
    local mt = getmetatable(obj)
    return tp == mt
end

raise = utils.raise

--- load a code string or bytecode chunk.
-- @param code Lua code as a string or bytecode
-- @param name for source errors
-- @param mode kind of chunk, 't' for text, 'b' for bytecode, 'bt' for all (default)
-- @param env  the environment for the new chunk (default nil)
-- @return compiled chunk
-- @return error message (chunk is nil)
-- @function utils.load

---------------
-- Get environment of a function.
-- With Lua 5.2, may return nil for a function with no global references!
-- Based on code by [Sergey Rozhenko](http://lua-users.org/lists/lua-l/2010-06/msg00313.html)
-- @param f a function or a call stack reference
-- @function utils.getfenv

---------------
-- Set environment of a function
-- @param f a function or a call stack reference
-- @param env a table that becomes the new environment of `f`
-- @function utils.setfenv

--- execute a shell command.
-- This is a compatibility function that returns the same for Lua 5.1 and Lua 5.2
-- @param cmd a shell command
-- @return true if successful
-- @return actual return code
-- @function utils.execute



local file = {}

--- return the contents of a file as a string
-- @function file.read
-- @string filename The file path
-- @return file contents
file.read = utils.readfile

--- write a string to a file
-- @function file.write
-- @string filename The file path
-- @string str The string
file.write = utils.writefile







local _G = _G
local sub = string.sub
local getenv = os.getenv
local tmpnam = os.tmpname
local attributes, currentdir, link_attrib
local package = package
local append, concat, remove = table.insert, table.concat, table.remove
local assert_string,raise = utils.assert_string,utils.raise

local attrib
local path = {}

local res,lfs = _G.pcall(_G.require,'lfs')
if res then
    attributes = lfs.attributes
    currentdir = lfs.currentdir
    link_attrib = lfs.symlinkattributes
else
    error("pl.path requires LuaFileSystem")
end

attrib = attributes
path.attrib = attrib
path.link_attrib = link_attrib

--- Lua iterator over the entries of a given directory.
-- Behaves like `lfs.dir`
path.dir = lfs.dir

--- Creates a directory.
path.mkdir = lfs.mkdir

--- Removes a directory.
path.rmdir = lfs.rmdir

---- Get the working directory.
path.currentdir = currentdir

--- Changes the working directory.
path.chdir = lfs.chdir


--- is this a directory?
-- @string P A file path
function path.isdir(P)
    assert_string(1,P)
    if P:match("\\$") then
        P = P:sub(1,-2)
    end
    return attrib(P,'mode') == 'directory'
end

--- is this a file?.
-- @string P A file path
function path.isfile(P)
    assert_string(1,P)
    return attrib(P,'mode') == 'file'
end

-- is this a symbolic link?
-- @string P A file path
function path.islink(P)
    assert_string(1,P)
    if link_attrib then
        return link_attrib(P,'mode')=='link'
    else
        return false
    end
end

--- return size of a file.
-- @string P A file path
function path.getsize(P)
    assert_string(1,P)
    return attrib(P,'size')
end

--- does a path exist?.
-- @string P A file path
-- @return the file path if it exists, nil otherwise
function path.exists(P)
    assert_string(1,P)
    return attrib(P,'mode') ~= nil and P
end

--- Return the time of last access as the number of seconds since the epoch.
-- @string P A file path
function path.getatime(P)
    assert_string(1,P)
    return attrib(P,'access')
end

--- Return the time of last modification
-- @string P A file path
function path.getmtime(P)
    return attrib(P,'modification')
end

---Return the system's ctime.
-- @string P A file path
function path.getctime(P)
    assert_string(1,P)
    return path.attrib(P,'change')
end


local function at(s,i)
    return sub(s,i,i)
end

path.is_windows = utils.is_windows

local other_sep
-- !constant sep is the directory separator for this platform.
if path.is_windows then
    path.sep = '\\'; other_sep = '/'
    path.dirsep = ';'
else
    path.sep = '/'
    path.dirsep = ':'
end
local sep,dirsep = path.sep,path.dirsep

--- are we running Windows?
-- @class field
-- @name path.is_windows

--- path separator for this platform.
-- @class field
-- @name path.sep

--- separator for PATH for this platform
-- @class field
-- @name path.dirsep

--- given a path, return the directory part and a file part.
-- if there's no directory part, the first value will be empty
-- @string P A file path
function path.splitpath(P)
    assert_string(1,P)
    local i = #P
    local ch = at(P,i)
    while i > 0 and ch ~= sep and ch ~= other_sep do
        i = i - 1
        ch = at(P,i)
    end
    if i == 0 then
        return '',P
    else
        return sub(P,1,i-1), sub(P,i+1)
    end
end

--- return an absolute path.
-- @string P A file path
-- @string[opt] pwd optional start path to use (default is current dir)
function path.abspath(P,pwd)
    assert_string(1,P)
    if pwd then assert_string(2,pwd) end
    local use_pwd = pwd ~= nil
    if not use_pwd and not currentdir then return P end
    P = P:gsub('[\\/]$','')
    pwd = pwd or currentdir()
    if not path.isabs(P) then
        P = path.join(pwd,P)
    elseif path.is_windows and not use_pwd and at(P,2) ~= ':' and at(P,2) ~= '\\' then
        P = pwd:sub(1,2)..P -- attach current drive to path like '\\fred.txt'
    end
    return path.normpath(P)
end

--- given a path, return the root part and the extension part.
-- if there's no extension part, the second value will be empty
-- @string P A file path
-- @treturn string root part
-- @treturn string extension part (maybe empty)
function path.splitext(P)
    assert_string(1,P)
    local i = #P
    local ch = at(P,i)
    while i > 0 and ch ~= '.' do
        if ch == sep or ch == other_sep then
            return P,''
        end
        i = i - 1
        ch = at(P,i)
    end
    if i == 0 then
        return P,''
    else
        return sub(P,1,i-1),sub(P,i)
    end
end

--- return the directory part of a path
-- @string P A file path
function path.dirname(P)
    assert_string(1,P)
    local p1,p2 = path.splitpath(P)
    return p1
end

--- return the file part of a path
-- @string P A file path
function path.basename(P)
    assert_string(1,P)
    local p1,p2 = path.splitpath(P)
    return p2
end

--- get the extension part of a path.
-- @string P A file path
function path.extension(P)
    assert_string(1,P)
    local p1,p2 = path.splitext(P)
    return p2
end

--- is this an absolute path?.
-- @string P A file path
function path.isabs(P)
    assert_string(1,P)
    if path.is_windows then
        return at(P,1) == '/' or at(P,1)=='\\' or at(P,2)==':'
    else
        return at(P,1) == '/'
    end
end

--- return the path resulting from combining the individual paths.
-- if the second (or later) path is absolute, we return the last absolute path (joined with any non-absolute paths following).
-- empty elements (except the last) will be ignored.
-- @string p1 A file path
-- @string p2 A file path
-- @string ... more file paths
function path.join(p1,p2,...)
    assert_string(1,p1)
    assert_string(2,p2)
    if select('#',...) > 0 then
        local p = path.join(p1,p2)
        local args = {...}
        for i = 1,#args do
            assert_string(i,args[i])
            p = path.join(p,args[i])
        end
        return p
    end
    if path.isabs(p2) then return p2 end
    local endc = at(p1,#p1)
    if endc ~= path.sep and endc ~= other_sep and endc ~= "" then
        p1 = p1..path.sep
    end
    return p1..p2
end

--- normalize the case of a pathname. On Unix, this returns the path unchanged;
--  for Windows, it converts the path to lowercase, and it also converts forward slashes
-- to backward slashes.
-- @string P A file path
function path.normcase(P)
    assert_string(1,P)
    if path.is_windows then
        return (P:lower():gsub('/','\\'))
    else
        return P
    end
end

--- normalize a path name.
--  A//B, A/./B and A/foo/../B all become A/B.
-- @string P a file path
function path.normpath(P)
    assert_string(1,P)
    -- Split path into anchor and relative path.
    local anchor = ''
    if path.is_windows then
        if P:match '^\\\\' then -- UNC
            anchor = '\\\\'
            P = P:sub(3)
        elseif at(P, 1) == '/' or at(P, 1) == '\\' then
            anchor = '\\'
            P = P:sub(2)
        elseif at(P, 2) == ':' then
            anchor = P:sub(1, 2)
            P = P:sub(3)
            if at(P, 1) == '/' or at(P, 1) == '\\' then
                anchor = anchor..'\\'
                P = P:sub(2)
            end
        end
        P = P:gsub('/','\\')
    else
        -- According to POSIX, in path start '//' and '/' are distinct,
        -- but '///+' is equivalent to '/'.
        if P:match '^//' and at(P, 3) ~= '/' then
            anchor = '//'
            P = P:sub(3)
        elseif at(P, 1) == '/' then
            anchor = '/'
            P = P:match '^/*(.*)$'
        end
    end
    local parts = {}
    for part in P:gmatch('[^'..sep..']+') do
        if part == '..' then
            if #parts ~= 0 and parts[#parts] ~= '..' then
                remove(parts)
            else
                append(parts, part)
            end
        elseif part ~= '.' then
            append(parts, part)
        end
    end
    P = anchor..concat(parts, sep)
    if P == '' then P = '.' end
    return P
end

local function ATS (P)
    if at(P,#P) ~= path.sep then
        P = P..path.sep
    end
    return path.normcase(P)
end

--- relative path from current directory or optional start point
-- @string P a path
-- @string[opt] start optional start point (default current directory)
function path.relpath (P,start)
    assert_string(1,P)
    if start then assert_string(2,start) end
    local split,normcase,min,append = utils.split, path.normcase, math.min, table.insert
    P = normcase(path.abspath(P,start))
    start = start or currentdir()
    start = normcase(start)
    local startl, Pl = split(start,sep), split(P,sep)
    local n = min(#startl,#Pl)
    if path.is_windows and n > 0 and at(Pl[1],2) == ':' and Pl[1] ~= startl[1] then
        return P
    end
    local k = n+1 -- default value if this loop doesn't bail out!
    for i = 1,n do
        if startl[i] ~= Pl[i] then
            k = i
            break
        end
    end
    local rell = {}
    for i = 1, #startl-k+1 do rell[i] = '..' end
    if k <= #Pl then
        for i = k,#Pl do append(rell,Pl[i]) end
    end
    return table.concat(rell,sep)
end


--- Replace a starting '~' with the user's home directory.
-- In windows, if HOME isn't set, then USERPROFILE is used in preference to
-- HOMEDRIVE HOMEPATH. This is guaranteed to be writeable on all versions of Windows.
-- @string P A file path
function path.expanduser(P)
    assert_string(1,P)
    if at(P,1) == '~' then
        local home = getenv('HOME')
        if not home then -- has to be Windows
            home = getenv 'USERPROFILE' or (getenv 'HOMEDRIVE' .. getenv 'HOMEPATH')
        end
        return home..sub(P,2)
    else
        return P
    end
end


---Return a suitable full path to a new temporary file name.
-- unlike os.tmpnam(), it always gives you a writeable path (uses TEMP environment variable on Windows)
function path.tmpname ()
    local res = tmpnam()
    -- On Windows if Lua is compiled using MSVC14 os.tmpname
    -- already returns an absolute path within TEMP env variable directory,
    -- no need to prepend it.
    if path.is_windows and not res:find(':') then
        res = getenv('TEMP')..res
    end
    return res
end

--- return the largest common prefix path of two paths.
-- @string path1 a file path
-- @string path2 a file path
function path.common_prefix (path1,path2)
    assert_string(1,path1)
    assert_string(2,path2)
    path1, path2 = path.normcase(path1), path.normcase(path2)
    -- get them in order!
    if #path1 > #path2 then path2,path1 = path1,path2 end
    for i = 1,#path1 do
        local c1 = at(path1,i)
        if c1 ~= at(path2,i) then
            local cp = path1:sub(1,i-1)
            if at(path1,i-1) ~= sep then
                cp = path.dirname(cp)
            end
            return cp
        end
    end
    if at(path2,#path1+1) ~= sep then path1 = path.dirname(path1) end
    return path1
    --return ''
end

--- return the full path where a particular Lua module would be found.
-- Both package.path and package.cpath is searched, so the result may
-- either be a Lua file or a shared library.
-- @string mod name of the module
-- @return on success: path of module, lua or binary
-- @return on error: nil,error string
function path.package_path(mod)
    assert_string(1,mod)
    local res
    mod = mod:gsub('%.',sep)
    res = package.searchpath(mod,package.path)
    if res then return res,true end
    res = package.searchpath(mod,package.cpath)
    if res then return res,false end
    return raise 'cannot find module on path'
end





--- Python-style list class.
--
-- **Please Note**: methods that change the list will return the list.
-- This is to allow for method chaining, but please note that `ls = ls:sort()`
-- does not mean that a new copy of the list is made. In-place (mutable) methods
-- are marked as returning 'the list' in this documentation.
--
-- See the Guide for further @{02-arrays.md.Python_style_Lists|discussion}
--
-- See <a href="http://www.python.org/doc/current/tut/tut.html">http://www.python.org/doc/current/tut/tut.html</a>, section 5.1
--
-- **Note**: The comments before some of the functions are from the Python docs
-- and contain Python code.
--
-- Written for Lua version Nick Trout 4.0; Redone for Lua 5.1, Steve Donovan.
--
-- Dependencies: `pl.utils`, `pl.tablex`, `pl.class`
-- @classmod pl.List
-- @pragma nostrip

local tinsert,tremove,concat,tsort = table.insert,table.remove,table.concat,table.sort
local setmetatable, getmetatable,type,tostring,string = setmetatable,getmetatable,type,tostring,string
local tablex = require 'pl.tablex'
local filter,imap,imap2,reduce,transform,tremovevalues = tablex.filter,tablex.imap,tablex.imap2,tablex.reduce,tablex.transform,tablex.removevalues
local tsub = tablex.sub
local utils = require 'pl.utils'
local class = require 'pl.class'

local array_tostring,split,assert_arg,function_arg = utils.array_tostring,utils.split,utils.assert_arg,utils.function_arg
local normalize_slice = tablex._normalize_slice

-- metatable for our list and map objects has already been defined..
local Multimap = utils.stdmt.MultiMap
local List = utils.stdmt.List

local iter

class(nil,nil,List)

-- we want the result to be _covariant_, i.e. t must have type of obj if possible
local function makelist (t,obj)
    local klass = List
    if obj then
        klass = getmetatable(obj)
    end
    return setmetatable(t,klass)
end

local function simple_table(t)
    return type(t) == 'table' and not getmetatable(t) and #t > 0
end

function List._create (src)
    if simple_table(src) then return src end
end

function List:_init (src)
    if self == src then return end -- existing table used as self!
    if src then
        for v in iter(src) do
            tinsert(self,v)
        end
    end
end

--- Create a new list. Can optionally pass a table;
-- passing another instance of List will cause a copy to be created;
-- this will return a plain table with an appropriate metatable.
-- we pass anything which isn't a simple table to iterate() to work out
-- an appropriate iterator
--  @see List.iterate
-- @param[opt] t An optional list-like table
-- @return a new List
-- @usage ls = List();  ls = List {1,2,3,4}
-- @function List.new

List.new = List

--- Make a copy of an existing list.
-- The difference from a plain 'copy constructor' is that this returns
-- the actual List subtype.
function List:clone()
    local ls = makelist({},self)
    ls:extend(self)
    return ls
end

---Add an item to the end of the list.
-- @param i An item
-- @return the list
function List:append(i)
    tinsert(self,i)
    return self
end

List.push = tinsert

--- Extend the list by appending all the items in the given list.
-- equivalent to 'a[len(a):] = L'.
-- @tparam List L Another List
-- @return the list
function List:extend(L)
    assert_arg(1,L,'table')
    for i = 1,#L do tinsert(self,L[i]) end
    return self
end

--- Insert an item at a given position. i is the index of the
-- element before which to insert.
-- @int i index of element before whichh to insert
-- @param x A data item
-- @return the list
function List:insert(i, x)
    assert_arg(1,i,'number')
    tinsert(self,i,x)
    return self
end

--- Insert an item at the begining of the list.
-- @param x a data item
-- @return the list
function List:put (x)
    return self:insert(1,x)
end

--- Remove an element given its index.
-- (equivalent of Python's del s[i])
-- @int i the index
-- @return the list
function List:remove (i)
    assert_arg(1,i,'number')
    tremove(self,i)
    return self
end

--- Remove the first item from the list whose value is given.
-- (This is called 'remove' in Python; renamed to avoid confusion
-- with table.remove)
-- Return nil if there is no such item.
-- @param x A data value
-- @return the list
function List:remove_value(x)
    for i=1,#self do
        if self[i]==x then tremove(self,i) return self end
    end
    return self
 end

--- Remove the item at the given position in the list, and return it.
-- If no index is specified, a:pop() returns the last item in the list.
-- The item is also removed from the list.
-- @int[opt] i An index
-- @return the item
function List:pop(i)
    if not i then i = #self end
    assert_arg(1,i,'number')
    return tremove(self,i)
end

List.get = List.pop

--- Return the index in the list of the first item whose value is given.
-- Return nil if there is no such item.
-- @function List:index
-- @param x A data value
-- @int[opt=1] idx where to start search
-- @return the index, or nil if not found.

local tfind = tablex.find
List.index = tfind

--- does this list contain the value?.
-- @param x A data value
-- @return true or false
function List:contains(x)
    return tfind(self,x) and true or false
end

--- Return the number of times value appears in the list.
-- @param x A data value
-- @return number of times x appears
function List:count(x)
    local cnt=0
    for i=1,#self do
        if self[i]==x then cnt=cnt+1 end
    end
    return cnt
end

--- Sort the items of the list, in place.
-- @func[opt='<'] cmp an optional comparison function
-- @return the list
function List:sort(cmp)
    if cmp then cmp = function_arg(1,cmp) end
    tsort(self,cmp)
    return self
end

--- return a sorted copy of this list.
-- @func[opt='<'] cmp an optional comparison function
-- @return a new list
function List:sorted(cmp)
    return List(self):sort(cmp)
end

--- Reverse the elements of the list, in place.
-- @return the list
function List:reverse()
    local t = self
    local n = #t
    for i = 1,n/2 do
        t[i],t[n] = t[n],t[i]
        n = n - 1
    end
    return self
end

--- return the minimum and the maximum value of the list.
-- @return minimum value
-- @return maximum value
function List:minmax()
    local vmin,vmax = 1e70,-1e70
    for i = 1,#self do
        local v = self[i]
        if v < vmin then vmin = v end
        if v > vmax then vmax = v end
    end
    return vmin,vmax
end

--- Emulate list slicing.  like  'list[first:last]' in Python.
-- If first or last are negative then they are relative to the end of the list
-- eg. slice(-2) gives last 2 entries in a list, and
-- slice(-4,-2) gives from -4th to -2nd
-- @param first An index
-- @param last An index
-- @return a new List
function List:slice(first,last)
    return tsub(self,first,last)
end

--- empty the list.
-- @return the list
function List:clear()
    for i=1,#self do tremove(self) end
    return self
end

local eps = 1.0e-10

--- Emulate Python's range(x) function.
-- Include it in List table for tidiness
-- @int start A number
-- @int[opt] finish A number greater than start; if absent,
-- then start is 1 and finish is start
-- @int[opt=1] incr an increment (may be less than 1)
-- @return a List from start .. finish
-- @usage List.range(0,3) == List{0,1,2,3}
-- @usage List.range(4) = List{1,2,3,4}
-- @usage List.range(5,1,-1) == List{5,4,3,2,1}
function List.range(start,finish,incr)
    if not finish then
        finish = start
        start = 1
    end
    if incr then
    assert_arg(3,incr,'number')
    if math.ceil(incr) ~= incr then finish = finish + eps end
    else
        incr = 1
    end
    assert_arg(1,start,'number')
    assert_arg(2,finish,'number')
    local t = List()
    for i=start,finish,incr do tinsert(t,i) end
    return t
end

--- list:len() is the same as #list.
function List:len()
    return #self
end

-- Extended operations --

--- Remove a subrange of elements.
-- equivalent to 'del s[i1:i2]' in Python.
-- @int i1 start of range
-- @int i2 end of range
-- @return the list
function List:chop(i1,i2)
    return tremovevalues(self,i1,i2)
end

--- Insert a sublist into a list
-- equivalent to 's[idx:idx] = list' in Python
-- @int idx index
-- @tparam List list list to insert
-- @return the list
-- @usage  l = List{10,20}; l:splice(2,{21,22});  assert(l == List{10,21,22,20})
function List:splice(idx,list)
    assert_arg(1,idx,'number')
    idx = idx - 1
    local i = 1
    for v in iter(list) do
        tinsert(self,i+idx,v)
        i = i + 1
    end
    return self
end

--- general slice assignment s[i1:i2] = seq.
-- @int i1  start index
-- @int i2  end index
-- @tparam List seq a list
-- @return the list
function List:slice_assign(i1,i2,seq)
    assert_arg(1,i1,'number')
    assert_arg(1,i2,'number')
    i1,i2 = normalize_slice(self,i1,i2)
    if i2 >= i1 then self:chop(i1,i2) end
    self:splice(i1,seq)
    return self
end

--- concatenation operator.
-- @within metamethods
-- @tparam List L another List
-- @return a new list consisting of the list with the elements of the new list appended
function List:__concat(L)
    assert_arg(1,L,'table')
    local ls = self:clone()
    ls:extend(L)
    return ls
end

--- equality operator ==.  True iff all elements of two lists are equal.
-- @within metamethods
-- @tparam List L another List
-- @return true or false
function List:__eq(L)
    if #self ~= #L then return false end
    for i = 1,#self do
        if self[i] ~= L[i] then return false end
    end
    return true
end

--- join the elements of a list using a delimiter.
-- This method uses tostring on all elements.
-- @string[opt=''] delim a delimiter string, can be empty.
-- @return a string
function List:join (delim)
    delim = delim or ''
    assert_arg(1,delim,'string')
    return concat(array_tostring(self),delim)
end

--- join a list of strings. <br>
-- Uses `table.concat` directly.
-- @function List:concat
-- @string[opt=''] delim a delimiter
-- @return a string
List.concat = concat

local function tostring_q(val)
    local s = tostring(val)
    if type(val) == 'string' then
        s = '"'..s..'"'
    end
    return s
end

--- how our list should be rendered as a string. Uses join().
-- @within metamethods
-- @see List:join
function List:__tostring()
    return '{'..self:join(',',tostring_q)..'}'
end

--- call the function on each element of the list.
-- @func fun a function or callable object
-- @param ... optional values to pass to function
function List:foreach (fun,...)
    fun = function_arg(1,fun)
    for i = 1,#self do
        fun(self[i],...)
    end
end

local function lookup_fun (obj,name)
    local f = obj[name]
    if not f then error(type(obj).." does not have method "..name,3) end
    return f
end

--- call the named method on each element of the list.
-- @string name the method name
-- @param ... optional values to pass to function
function List:foreachm (name,...)
    for i = 1,#self do
        local obj = self[i]
        local f = lookup_fun(obj,name)
        f(obj,...)
    end
end

--- create a list of all elements which match a function.
-- @func fun a boolean function
-- @param[opt] arg optional argument to be passed as second argument of the predicate
-- @return a new filtered list.
function List:filter (fun,arg)
    return makelist(filter(self,fun,arg),self)
end

--- split a string using a delimiter.
-- @string s the string
-- @string[opt] delim the delimiter (default spaces)
-- @return a List of strings
-- @see pl.utils.split
function List.split (s,delim)
    assert_arg(1,s,'string')
    return makelist(split(s,delim))
end

--- apply a function to all elements.
-- Any extra arguments will be passed to the function.
-- @func fun a function of at least one argument
-- @param ... arbitrary extra arguments.
-- @return a new list: {f(x) for x in self}
-- @usage List{'one','two'}:map(string.upper) == {'ONE','TWO'}
-- @see pl.tablex.imap
function List:map (fun,...)
    return makelist(imap(fun,self,...),self)
end

--- apply a function to all elements, in-place.
-- Any extra arguments are passed to the function.
-- @func fun A function that takes at least one argument
-- @param ... arbitrary extra arguments.
-- @return the list.
function List:transform (fun,...)
    transform(fun,self,...)
    return self
end

--- apply a function to elements of two lists.
-- Any extra arguments will be passed to the function
-- @func fun a function of at least two arguments
-- @tparam List ls another list
-- @param ... arbitrary extra arguments.
-- @return a new list: {f(x,y) for x in self, for x in arg1}
-- @see pl.tablex.imap2
function List:map2 (fun,ls,...)
    return makelist(imap2(fun,self,ls,...),self)
end

--- apply a named method to all elements.
-- Any extra arguments will be passed to the method.
-- @string name name of method
-- @param ... extra arguments
-- @return a new list of the results
-- @see pl.seq.mapmethod
function List:mapm (name,...)
    local res = {}
    for i = 1,#self do
      local val = self[i]
      local fn = lookup_fun(val,name)
      res[i] = fn(val,...)
    end
    return makelist(res,self)
end

local function composite_call (method,f)
    return function(self,...)
        return self[method](self,f,...)
    end
end

function List.default_map_with(T)
    return function(self,name)
        local m
        if T then
            local f = lookup_fun(T,name)
            m = composite_call('map',f)
        else
            m = composite_call('mapn',name)
        end
        getmetatable(self)[name] = m -- and cache..
        return m
    end
end

List.default_map = List.default_map_with

--- 'reduce' a list using a binary function.
-- @func fun a function of two arguments
-- @return result of the function
-- @see pl.tablex.reduce
function List:reduce (fun)
    return reduce(fun,self)
end

--- partition a list using a classifier function.
-- The function may return nil, but this will be converted to the string key '<nil>'.
-- @func fun a function of at least one argument
-- @param ... will also be passed to the function
-- @treturn MultiMap a table where the keys are the returned values, and the values are Lists
-- of values where the function returned that key.
-- @see pl.MultiMap
function List:partition (fun,...)
    fun = function_arg(1,fun)
    local res = {}
    for i = 1,#self do
        local val = self[i]
        local klass = fun(val,...)
        if klass == nil then klass = '<nil>' end
        if not res[klass] then res[klass] = List() end
        res[klass]:append(val)
    end
    return setmetatable(res,Multimap)
end

--- return an iterator over all values.
function List:iter ()
    return iter(self)
end

--- Create an iterator over a seqence.
-- This captures the Python concept of 'sequence'.
-- For tables, iterates over all values with integer indices.
-- @param seq a sequence; a string (over characters), a table, a file object (over lines) or an iterator function
-- @usage for x in iterate {1,10,22,55} do io.write(x,',') end ==> 1,10,22,55
-- @usage for ch in iterate 'help' do do io.write(ch,' ') end ==> h e l p
function List.iterate(seq)
    if type(seq) == 'string' then
        local idx = 0
        local n = #seq
        local sub = string.sub
        return function ()
            idx = idx + 1
            if idx > n then return nil
            else
                return sub(seq,idx,idx)
            end
        end
    elseif type(seq) == 'table' then
        local idx = 0
        local n = #seq
        return function()
            idx = idx + 1
            if idx > n then return nil
            else
                return seq[idx]
            end
        end
    elseif type(seq) == 'function' then
        return seq
    elseif type(seq) == 'userdata' and io.type(seq) == 'file' then
        return seq:lines()
    end
end
iter = List.iterate





local is_windows = path.is_windows
local ldir = path.dir
local mkdir = path.mkdir
local rmdir = path.rmdir
local sub = string.sub
local os,pcall,ipairs,pairs,require,setmetatable = os,pcall,ipairs,pairs,require,setmetatable
local remove = os.remove
local append = table.insert
local wrap = coroutine.wrap
local yield = coroutine.yield
local assert_arg,assert_string,raise = utils.assert_arg,utils.assert_string,utils.raise

local dir = {}

local function makelist(l)
    return setmetatable(l, List)
end

local function assert_dir (n,val)
    assert_arg(n,val,'string',path.isdir,'not a directory',4)
end

local function filemask(mask)
    mask = utils.escape(path.normcase(mask))
    return '^'..mask:gsub('%%%*','.*'):gsub('%%%?','.')..'$'
end

--- Test whether a file name matches a shell pattern.
-- Both parameters are case-normalized if operating system is
-- case-insensitive.
-- @string filename A file name.
-- @string pattern A shell pattern. The only special characters are
-- `'*'` and `'?'`: `'*'` matches any sequence of characters and
-- `'?'` matches any single character.
-- @treturn bool
-- @raise dir and mask must be strings
function dir.fnmatch(filename,pattern)
    assert_string(1,filename)
    assert_string(2,pattern)
    return path.normcase(filename):find(filemask(pattern)) ~= nil
end

--- Return a list of all file names within an array which match a pattern.
-- @tab filenames An array containing file names.
-- @string pattern A shell pattern.
-- @treturn List(string) List of matching file names.
-- @raise dir and mask must be strings
function dir.filter(filenames,pattern)
    assert_arg(1,filenames,'table')
    assert_string(2,pattern)
    local res = {}
    local mask = filemask(pattern)
    for i,f in ipairs(filenames) do
        if path.normcase(f):find(mask) then append(res,f) end
    end
    return makelist(res)
end

local function _listfiles(dir,filemode,match)
    local res = {}
    local check = utils.choose(filemode,path.isfile,path.isdir)
    if not dir then dir = '.' end
    for f in ldir(dir) do
        if f ~= '.' and f ~= '..' then
            local p = path.join(dir,f)
            if check(p) and (not match or match(f)) then
                append(res,p)
            end
        end
    end
    return makelist(res)
end

--- return a list of all files in a directory which match the a shell pattern.
-- @string dir A directory. If not given, all files in current directory are returned.
-- @string mask  A shell pattern. If not given, all files are returned.
-- @treturn {string} list of files
-- @raise dir and mask must be strings
function dir.getfiles(dir,mask)
    assert_dir(1,dir)
    if mask then assert_string(2,mask) end
    local match
    if mask then
        mask = filemask(mask)
        match = function(f)
            return path.normcase(f):find(mask)
        end
    end
    return _listfiles(dir,true,match)
end

--- return a list of all subdirectories of the directory.
-- @string dir A directory
-- @treturn {string} a list of directories
-- @raise dir must be a a valid directory
function dir.getdirectories(dir)
    assert_dir(1,dir)
    return _listfiles(dir,false)
end

local alien,ffi,ffi_checked,CopyFile,MoveFile,GetLastError,win32_errors,cmd_tmpfile

local function execute_command(cmd,parms)
   if not cmd_tmpfile then cmd_tmpfile = path.tmpname () end
   local err = path.is_windows and ' > ' or ' 2> '
    cmd = cmd..' '..parms..err..utils.quote_arg(cmd_tmpfile)
    local ret = utils.execute(cmd)
    if not ret then
        local err = (utils.readfile(cmd_tmpfile):gsub('\n(.*)',''))
        remove(cmd_tmpfile)
        return false,err
    else
        remove(cmd_tmpfile)
        return true
    end
end

local function find_ffi_copyfile ()
    if not ffi_checked then
        ffi_checked = true
        local res
        res,alien = pcall(require,'alien')
        if not res then
            alien = nil
            res, ffi = pcall(require,'ffi')
        end
        if not res then
            ffi = nil
            return
        end
    else
        return
    end
    if alien then
        -- register the Win32 CopyFile and MoveFile functions
        local kernel = alien.load('kernel32.dll')
        CopyFile = kernel.CopyFileA
        CopyFile:types{'string','string','int',ret='int',abi='stdcall'}
        MoveFile = kernel.MoveFileA
        MoveFile:types{'string','string',ret='int',abi='stdcall'}
        GetLastError = kernel.GetLastError
        GetLastError:types{ret ='int', abi='stdcall'}
    elseif ffi then
        ffi.cdef [[
            int CopyFileA(const char *src, const char *dest, int iovr);
            int MoveFileA(const char *src, const char *dest);
            int GetLastError();
        ]]
        CopyFile = ffi.C.CopyFileA
        MoveFile = ffi.C.MoveFileA
        GetLastError = ffi.C.GetLastError
    end
    win32_errors = {
        ERROR_FILE_NOT_FOUND    =         2,
        ERROR_PATH_NOT_FOUND    =         3,
        ERROR_ACCESS_DENIED    =          5,
        ERROR_WRITE_PROTECT    =          19,
        ERROR_BAD_UNIT         =          20,
        ERROR_NOT_READY        =          21,
        ERROR_WRITE_FAULT      =          29,
        ERROR_READ_FAULT       =          30,
        ERROR_SHARING_VIOLATION =         32,
        ERROR_LOCK_VIOLATION    =         33,
        ERROR_HANDLE_DISK_FULL  =         39,
        ERROR_BAD_NETPATH       =         53,
        ERROR_NETWORK_BUSY      =         54,
        ERROR_DEV_NOT_EXIST     =         55,
        ERROR_FILE_EXISTS       =         80,
        ERROR_OPEN_FAILED       =         110,
        ERROR_INVALID_NAME      =         123,
        ERROR_BAD_PATHNAME      =         161,
        ERROR_ALREADY_EXISTS    =         183,
    }
end

local function two_arguments (f1,f2)
    return utils.quote_arg(f1)..' '..utils.quote_arg(f2)
end

local function file_op (is_copy,src,dest,flag)
    if flag == 1 and path.exists(dest) then
        return false,"cannot overwrite destination"
    end
    if is_windows then
        -- if we haven't tried to load Alien/LuaJIT FFI before, then do so
        find_ffi_copyfile()
        -- fallback if there's no Alien, just use DOS commands *shudder*
        -- 'rename' involves a copy and then deleting the source.
        if not CopyFile then
            src = path.normcase(src)
            dest = path.normcase(dest)
            local cmd = is_copy and 'copy' or 'rename'
            local res, err = execute_command('copy',two_arguments(src,dest))
            if not res then return false,err end
            if not is_copy then
                return execute_command('del',utils.quote_arg(src))
            end
            return true
        else
            if path.isdir(dest) then
                dest = path.join(dest,path.basename(src))
            end
            local ret
            if is_copy then ret = CopyFile(src,dest,flag)
            else ret = MoveFile(src,dest) end
            if ret == 0 then
                local err = GetLastError()
                for name,value in pairs(win32_errors) do
                    if value == err then return false,name end
                end
                return false,"Error #"..err
            else return true
            end
        end
    else -- for Unix, just use cp for now
        return execute_command(is_copy and 'cp' or 'mv',
            two_arguments(src,dest))
    end
end

--- copy a file.
-- @string src source file
-- @string dest destination file or directory
-- @bool flag true if you want to force the copy (default)
-- @treturn bool operation succeeded
-- @raise src and dest must be strings
function dir.copyfile (src,dest,flag)
    assert_string(1,src)
    assert_string(2,dest)
    flag = flag==nil or flag
    return file_op(true,src,dest,flag and 0 or 1)
end

--- move a file.
-- @string src source file
-- @string dest destination file or directory
-- @treturn bool operation succeeded
-- @raise src and dest must be strings
function dir.movefile (src,dest)
    assert_string(1,src)
    assert_string(2,dest)
    return file_op(false,src,dest,0)
end

local function _dirfiles(dir,attrib)
    local dirs = {}
    local files = {}
    for f in ldir(dir) do
        if f ~= '.' and f ~= '..' then
            local p = path.join(dir,f)
            local mode = attrib(p,'mode')
            if mode=='directory' then
                append(dirs,f)
            else
                append(files,f)
            end
        end
    end
    return makelist(dirs), makelist(files)
end


local function _walker(root,bottom_up,attrib)
    local dirs,files = _dirfiles(root,attrib)
    if not bottom_up then yield(root,dirs,files) end
    for i,d in ipairs(dirs) do
        _walker(root..path.sep..d,bottom_up,attrib)
    end
    if bottom_up then yield(root,dirs,files) end
end

--- return an iterator which walks through a directory tree starting at root.
-- The iterator returns (root,dirs,files)
-- Note that dirs and files are lists of names (i.e. you must say path.join(root,d)
-- to get the actual full path)
-- If bottom_up is false (or not present), then the entries at the current level are returned
-- before we go deeper. This means that you can modify the returned list of directories before
-- continuing.
-- This is a clone of os.walk from the Python libraries.
-- @string root A starting directory
-- @bool bottom_up False if we start listing entries immediately.
-- @bool follow_links follow symbolic links
-- @return an iterator returning root,dirs,files
-- @raise root must be a directory
function dir.walk(root,bottom_up,follow_links)
    assert_dir(1,root)
    local attrib
    if path.is_windows or not follow_links then
        attrib = path.attrib
    else
        attrib = path.link_attrib
    end
    return wrap(function () _walker(root,bottom_up,attrib) end)
end

--- remove a whole directory tree.
-- @string fullpath A directory path
-- @return true or nil
-- @return error if failed
-- @raise fullpath must be a string
function dir.rmtree(fullpath)
    assert_dir(1,fullpath)
    if path.islink(fullpath) then return false,'will not follow symlink' end
    for root,dirs,files in dir.walk(fullpath,true) do
        for i,f in ipairs(files) do
            local res, err = remove(path.join(root,f))
            if not res then return nil,err end
        end
        local res, err = rmdir(root)
        if not res then return nil,err end
    end
    return true
end

local dirpat
if path.is_windows then
    dirpat = '(.+)\\[^\\]+$'
else
    dirpat = '(.+)/[^/]+$'
end

local _makepath
function _makepath(p)
    -- windows root drive case
    if p:find '^%a:[\\]*$' then
        return true
    end
   if not path.isdir(p) then
    local subp = p:match(dirpat)
    local ok, err = _makepath(subp)
    if not ok then return nil, err end
    return mkdir(p)
   else
    return true
   end
end

--- create a directory path.
-- This will create subdirectories as necessary!
-- @string p A directory path
-- @return true on success, nil + errormsg on failure
-- @raise failure to create
function dir.makepath (p)
    assert_string(1,p)
    return _makepath(path.normcase(path.abspath(p)))
end


--- clone a directory tree. Will always try to create a new directory structure
-- if necessary.
-- @string path1 the base path of the source tree
-- @string path2 the new base path for the destination
-- @func file_fun an optional function to apply on all files
-- @bool verbose an optional boolean to control the verbosity of the output.
--  It can also be a logging function that behaves like print()
-- @return true, or nil
-- @return error message, or list of failed directory creations
-- @return list of failed file operations
-- @raise path1 and path2 must be strings
-- @usage clonetree('.','../backup',copyfile)
function dir.clonetree (path1,path2,file_fun,verbose)
    assert_string(1,path1)
    assert_string(2,path2)
    if verbose == true then verbose = print end
    local abspath,normcase,isdir,join = path.abspath,path.normcase,path.isdir,path.join
    local faildirs,failfiles = {},{}
    if not isdir(path1) then return raise 'source is not a valid directory' end
    path1 = abspath(normcase(path1))
    path2 = abspath(normcase(path2))
    if verbose then verbose('normalized:',path1,path2) end
    -- particularly NB that the new path isn't fully contained in the old path
    if path1 == path2 then return raise "paths are the same" end
    local i1,i2 = path2:find(path1,1,true)
    if i2 == #path1 and path2:sub(i2+1,i2+1) == path.sep then
        return raise 'destination is a subdirectory of the source'
    end
    local cp = path.common_prefix (path1,path2)
    local idx = #cp
    if idx == 0 then -- no common path, but watch out for Windows paths!
        if path1:sub(2,2) == ':' then idx = 3 end
    end
    for root,dirs,files in dir.walk(path1) do
        local opath = path2..root:sub(idx)
        if verbose then verbose('paths:',opath,root) end
        if not isdir(opath) then
            local ret = dir.makepath(opath)
            if not ret then append(faildirs,opath) end
            if verbose then verbose('creating:',opath,ret) end
        end
        if file_fun then
            for i,f in ipairs(files) do
                local p1 = join(root,f)
                local p2 = join(opath,f)
                local ret = file_fun(p1,p2)
                if not ret then append(failfiles,p2) end
                if verbose then
                    verbose('files:',p1,p2,ret)
                end
            end
        end
    end
    return true,faildirs,failfiles
end

--- return an iterator over all entries in a directory tree
-- @string d a directory
-- @return an iterator giving pathname and mode (true for dir, false otherwise)
-- @raise d must be a non-empty string
function dir.dirtree( d )
    assert( d and d ~= "", "directory parameter is missing or empty" )
    local exists, isdir = path.exists, path.isdir
    local sep = path.sep

    local last = sub ( d, -1 )
    if last == sep or last == '/' then
        d = sub( d, 1, -2 )
    end

    local function yieldtree( dir )
        for entry in ldir( dir ) do
            if entry ~= "." and entry ~= ".." then
                entry = dir .. sep .. entry
                if exists(entry) then  -- Just in case a symlink is broken.
                    local is_dir = isdir(entry)
                    yield( entry, is_dir )
                    if is_dir then
                        yieldtree( entry )
                    end
                end
            end
        end
    end

    return wrap( function() yieldtree( d ) end )
end


--- Recursively returns all the file starting at _path_. It can optionally take a shell pattern and
-- only returns files that match _shell_pattern_. If a pattern is given it will do a case insensitive search.
-- @string start_path  A directory. If not given, all files in current directory are returned.
-- @string shell_pattern A shell pattern. If not given, all files are returned.
-- @treturn List(string) containing all the files found recursively starting at _path_ and filtered by _shell_pattern_.
-- @raise start_path must be a directory
function dir.getallfiles( start_path, shell_pattern )
    assert_dir(1,start_path)
    shell_pattern = shell_pattern or "*"

    local files = {}
    local normcase = path.normcase
    for filename, mode in dir.dirtree( start_path ) do
        if not mode then
            local mask = filemask( shell_pattern )
            if normcase(filename):find( mask ) then
                files[#files + 1] = filename
            end
        end
    end

    return makelist(files)
end






pl.file  = file
pl.path  = path
pl.utils = utils
pl.dir   = dir

return pl
