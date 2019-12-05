# sh


This is based around [luash](https://zserge.com/blog/luash.html), I've
modified it so that it doesn't put a metatable on the global namespace.


Next up:


- [ ]  Add __repr


- [ ]  Intercept ``stderr`` and include it in the return package.


- [ ]  Add ``sh.session``, a persistent shell which, e.g., actually changes
       directory when you ``session "cd"``.


       This may not be feasible, since we can apparently read from or write
       to a ``popen`` call but not both?!


- [ ]  MMMmaaaybe build out a standard library of commands, I'm thinking of
       ``ls`` here, which have methods to parse the input into something usable
       within the Lua ecosystem.


       ``ls`` is a good choice, the more I think about it, because we can just
       get all the possible file information at once, and use the flags to
       filter the output.

```lua
local Sh = {}

-- borrowed with gratitude from:
-- https://github.com/zserge/luash/blob/master/sh.lua

-- converts key and it's argument to "-k" or "-k=v" or just ""
local function arg(k, a)
    if not a then return k end
    if type(a) == 'string' and #a > 0 then return k..'=\''..a..'\'' end
    if type(a) == 'number' then return k..'='..tostring(a) end
    if type(a) == 'boolean' and a == true then return k end
    error('invalid argument type ' .. type(a) .. " " .. tostring(a))
end

-- converts nested tables into a flat list of arguments and concatenated input
local function flatten(t)
    local result = {args = {}, input = ''}

    local function f(t)
        local keys = {}
        for k = 1, #t do
            keys[k] = true
            local v = t[k]
            if type(v) == 'table' then
                f(v)
            else
                table.insert(result.args, v)
            end
        end
        for k, v in pairs(t) do
            if k == '__input' then
                result.input = result.input .. v
            elseif not keys[k] and k:sub(1, 1) ~= '_' then
                local key = '-'..k
                if #k > 1 then key = '-' ..key end
                table.insert(result.args, arg(key, v))
            end
        end
    end

    f(t)
    return result
end

-- returns a function that executes the command with given args and returns its
-- output, exit status etc
local function command(cmd, ...)
    local prearg = {...}
    return function(...)
        local args = flatten({...})
        local s = cmd
        for _, v in ipairs(prearg) do
            s = s .. ' ' .. v
        end
        for k, v in pairs(args.args) do
            s = s .. ' ' .. v
        end

        if args.input then
            local san_input = args.input:gsub("\"", "\\\"")
            s = "echo \"" .. san_input .. "\" | " .. s
        end
        local p = io.popen(s, 'r')
        local output = p:read('*a')
        local _, exit, status = p:close()

        local t = {
            __input = output,
            __exitcode = exit == 'exit' and status or 127,
            __signal = exit == 'signal' and status or 0,
        }
        local mt = {
            __index = function(self, k, ...)
                return command(k)
            end,
            __tostring = function(self)
                -- return trimmed command output as a string
                return self.__input:match('^%s*(.-)%s*$')
            end,
            __repr = function(self)
                return string.gmatch(self.__input, "[^\n]+")
            end
        }
        return setmetatable(t, mt)
    end
end

-- export command() function
Sh.command = command
```
#### Sh.install()

An attempt to write a _respectful_ and _general_ version of the 'install to
global' behavior of the original ``luash``.


This either installs to a given environment table, or finds the right place
in the inheritance chain to patch itself in.


Thus installed, it strives mightily to do the right thing. This even defeats
strict mode.  I think.  Admittedly, I have yet to try it.


To unwind this, we'll want to cache the value of Global once initially
assigned, the value of the original G_index, and whether we created a
metatable or just retrieved one.


If it's our metatable, we just set Global's metatable to nil, done.


Otherwise we'll break out the metatable walk into its own function, so we can
repeat it, then reassign index to its original value.

```lua
function Sh.install(_Global)
    local Global
    local VER = string.sub( assert( _VERSION ), -4 )
    if _Global then
        Global = _Global
    elseif VER == " 5.1" then
        Global = getfenv()
    else
        Global = _ENV
    end
    local G_mt, G_index = nil, nil
    local at_top = false
    while not at_top do
        local maybe_mt = getmetatable(Global)
        if not maybe_mt then
            at_top = true
        else
            -- we have a metatable
            G_mt = maybe_mt
            -- but is it the ultimate?
            if G_mt.__index then
                if type(G_mt.__index) == "function" then
                    G_index = G_mt.__index
                    at_top = true
                elseif getmetatable(G_mt.__index) then
                    at_top = false
                    Global = G_mt.__index
                else
                    G_index = G_mt.__index
                    at_top = true
                end
            else
                at_top = true
            end
        end
    end
    -- *now* we can monkey-patch the global environment
    if not G_mt then G_mt = {} end
    local __index_fn
    -- three flavors:
    if not G_index then
        __index_fn = function(_, cmd)
                        return command(cmd)
                     end
    elseif type(G_index) == "table" then
        __index_fn = function(_, key)
                        local v = rawget(G_index, key)
                        if v ~= nil then return v end
                        return command(key)
                     end
    elseif type(G_index) == "function" then
        __index_fn = function(_, key)
                        local ok, v = pcall(G_index, _, key)
                        if ok and (v ~= nil) then return v end
                        return command(key)
                     end
    end
    --- now set the metatable:
    G_mt.__index = __index_fn
    setmetatable(Global, G_mt)
end
```
```lua
-- allow to call sh to run shell commands
setmetatable(Sh, {
    __call = function(_, cmd, ...)
        return command(cmd, ...)()
    end,
    __index = function(_, field)
        return command(field)
    end
})

return Sh
```
