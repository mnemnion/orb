


























local Sh = {}




-- make a safe-escaped, POSIX-compliant literal string,
-- with the 'quote marks'
local function sh_str(str)
    return table.concat {"'", str:gsub("'", "'\\''"), "'"}
end
-- borrowed with gratitude from:
-- https://github.com/zserge/luash/blob/master/sh.lua

-- converts key and it's argument to "-k" or "-k=v" or just ""
local function arg(k, a)
    if not a then return k end
    if type(a) == 'string' and #a > 0 then return k .. '=' .. sh_str(a) end
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
            s = "echo " .. sh_str(args.input) .. " | " .. s
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





-- allow to call sh to run shell commands
local Sh_M = {
    __call = function(_, cmd, ...)
        return command(cmd, ...)()
    end,
    __index = function(_, field)
        return command(field)
    end
}
setmetatable(Sh, Sh_M)
























function Sh.install(_Global)
    local Global
    local VER = string.sub( assert( _VERSION ), -4 )
    if _Global and _Global ~= Sh then
        Global = _Global
    elseif VER == " 5.1" then
        Global = getfenv()
    else
        Global = _ENV
    end
    local G_mt, G_index = nil, nil
    local at_top = false
    local our_mt = false
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
    -- if _ENV has no metatable, let's make one:
    if not G_mt then
        our_mt = true
        G_mt = {}
    end
    -- *now* we can monkey-patch the global environment
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
    -- stash the components for later removal
    -- put them on the metatable to avoid polluting the
    -- command space
    Sh_M.__cache = { Global = Global,
                     our_mt = our_mt,
                     G_index = G_index }
    -- return Sh for convenience
    return Sh
end








function Sh.remove()
    if not Sh_M.__cache then
        -- didn't patch the namespace
        return nil
    end
    local cache = Sh_M.__cache
    if cache.our_mt then
        -- we made the metatable, let's remove the
        -- whole thing
        setmetatable(cache.Global, nil)
    else
        -- if there was no G_index this will be a no-op
        getmetatable(cache.Global).__index = cache.G_index
    end
    -- remove cache
    Sh_M.__cache = nil
end



return Sh
