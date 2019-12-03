


























local core = require "singletons/core"



local Sh = {}

-- borrowed with gratitude from:
-- https://github.com/zserge/luash/blob/master/sh.lua

-- converts key and it's argument to "-k" or "-k=v" or just ""
local function arg(k, a)
    if not a then return k end
    if type(a) == 'string' and #a > 0 then return k..'=\''..a..'\'' end
    if type(a) == 'number' then return k..'='..tostring(a) end
    if type(a) == 'boolean' and a == true then return k end
    error('invalid argument type', type(a), a)
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

local lines = core.lines
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
            local f = io.open(Sh.tmpfile, 'w')
            f:write(args.input)
            f:close()
            s = s .. ' <'..Sh.tmpfile
        end
        local p = io.popen(s, 'r')
        local output = p:read('*a')
        local _, exit, status = p:close()
        os.remove(Sh.tmpfile)

        local t = {
            __input = output,
            __exitcode = exit == 'exit' and status or 127,
            __signal = exit == 'signal' and status or 0,
        }
        local mt = {
            __tostring = function(self)
                -- return trimmed command output as a string
                return self.__input:match('^%s*(.-)%s*$')
            end,
            __repr = function(self)
                return lines(self.__input)
            end
        }
        return setmetatable(t, mt)
    end
end

-- export command() function and configurable temporary "input" file
Sh.command = command
Sh.tmpfile = '/tmp/shluainput'

-- allow to call sh to run shell commands
setmetatable(Sh, {
    __call = function(_, cmd, ...)
        return command(cmd, ...)
    end
})

return Sh
