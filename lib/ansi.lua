local pairs = pairs
local tostring = tostring
local setmetatable = setmetatable
local error = error
local require = require
local rawget = rawget
local io = io
local schar = string.char

local _M = {}


local colormt = {}

local colors = {
    -- attributes
    attribute = {
        reset = 0,
        clear = 0,
        bright = 1,
        dim = 2,
        underscore = 4,
        blink = 5,
        reverse = 7,
        hidden = 8},
    -- foreground
    fg = {  
        black = 30,
        red = 31,
        green = 32,
        yellow = 33,
        blue = 34,
        magenta = 35,
        cyan = 36,
        white = 37,
        clear_fg = 39  },
    -- background
    bg = {
        onblack = 40,
        onred = 41,
        ongreen = 42,
        onyellow = 43,
        onblue = 44,
        onmagenta = 45,
        oncyan = 46,
        onwhite = 47,
        clear_bg = 49}
}

local function makecolor(value, name, kind)
    local color = { 
        value = schar(27)..'['..tostring(value)..'m',
        name = name,
        kind = kind }
    return setmetatable(color, colormt)
end

for kind, val in pairs(colors) do
    for c, v in pairs(val) do 
        _M[c] = makecolor(v, c, kind)
    end
end

function colormt:__tostring()
    return self.value
end

function colormt:__concat(other)
    return tostring(self) .. tostring(other)
end


local function reset(color)
    -- given a color, reset its action.
    -- simple for fg and bg
    -- complex but tractable for attributes
    if color.kind == "fg" then
        return _M.clear_fg
    elseif color.kind == "bg" then
        return _M.clear_bg
    elseif color.kind == "attribute" then
        --error "attribute reset NYI"
        return _M.clear
    end
end

function colormt:__call(s)
    if s then
        return tostring(self) .. s .. reset(self)
    else
        return tostring(self)
    end
end

colormt.__metatable = {}

local function byte_panic(byte_p)
       if not byte_p or not (0 < byte_p and byte_p <= 255) then
        error "xterm value must be 8 bit unsigned"
    end
end 

local function ansi_fg(byte)
    local store = {} -- repeated allocation is a sin.
    local function make (byte)
        byte_panic(byte)
        local color = { value = schar(27).."[38;5;"..byte.."m",
                        kind = "fg" }
        return setmetatable(color, colormt)
    end
    if store[byte] then
        return store[byte]
    else
        local color = make(byte)
        store[byte] = color
        return color
    end
end

local function ansi_bg(byte)
    local store = {}
    local function make (byte)
        byte_panic(byte)
        local color = { value = schar(27).."[48;5;"..byte.."m",
                        kind = "bg" }
        return setmetatable(color, colormt)
    end
    if store[byte] then
        return store[byte]
    else
        local color = make(byte)
        store[byte] = color
        return color
    end
end

_M["fg"], _M["bg"] = ansi_fg, ansi_bg

--- Jumps

local jump = {}

local CSI = schar(27)..'['

jump.up = function(num)
    if not num then num = "" end
    return CSI..num.."A"
end

jump.down = function(num)
    if not num then num = "" end
        return CSI..num.."B"
end 

jump.forward = function(num)
    if not num then num = "" end
    return CSI..num.."C"
end 

jump.back = function(num)
    if not num then num = "" end 
    return CSI..num.."D"
end 

local function Jump(_,row,column)
    return CSI..row..";"..column.."H"
end

local J = { __call = Jump}
setmetatable(jump,J)

_M["jump"] = jump


return _M

