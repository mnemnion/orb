
















local pairs = assert (pairs)
local tostring = assert (tostring)
local setmeta = assert (setmetatable)
local error = assert (error)
local require = assert (require)
local rawget = assert (rawget)

local schar = assert(string.char)
local sub   = assert(string.sub)
local rep   = assert(string.rep)
local byte  = assert(string.byte)
local bit   = assert(bit, "anterm requires Luajit 'bit' or compatible in _G")
local rshift = assert(bit.rshift)
local core = require "core"
bit = nil






















local anterm = {}

local CSI = schar(27)..'['











local colormt = {}
colormt.__index = colormt











local colors = {
    -- attributes
    attribute = {
        reset = 0,
        clear = 0,
        bright = 1,
        bold = 1,
        dim = 2,
        italic = 3,
        underscore = 4,
        underline = 4,
        reverse = 7,
        hidden = 8,
        clear_bold = 22,
        clear_dim  = 22,
        clear_underline = 24,
        clear_inverse = 27,
        clear_hidden = 28 },
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
        value = CSI .. value .."m",
        name = name,
        kind = kind }
    return setmetatable(color, colormt)
end

for kind, val in pairs(colors) do
    for c, v in pairs(val) do
        anterm[c] = makecolor(v, c, kind)
    end
end

function colormt.__tostring(color)
    return color.value
end

function colormt.__concat(color, other)
    return tostring(color) .. tostring(other)
end

local clear_fg, clear_bg, clear = anterm.clear_fg, anterm.clear_bg,
                                  anterm.clear
local clear_bold = anterm.clear_bold

local function reset(color)
    -- given a color, reset its action.
    -- simple for fg and bg
    if color.kind == "fg" then
        return clear_fg
    elseif color.kind == "bg" then
        return clear_bg
    elseif color.kind == "attribute" then
       local name = color.name
       if name == "bold" or name == "dim" then
          return clear_bold
       elseif name == "underscore" or name == "underline" then
          return clear_underline
       elseif name == "inverse" then
          return clear_inverse
       elseif name == "hidden" then
          return clear_hidden
       else
          return clear
       end
    end
end

local __ts = colormt.__tostring

function colormt.__call(color, str)
    if str then
        return __ts(color) .. str .. reset(color)
    else
        return __ts(color)
    end
end












local function byte_panic(byte_p)
   if not byte_p or not (0 <= byte_p and byte_p <= 255) then
      error "xterm value must be 8 bit unsigned"
   end
end

local x256_store = setmetatable({}, {__mode = "v"})

local function ansi_fg(byte)
    local function make (byte)
        byte_panic(byte)
        local color = { value = schar(27).."[38;5;"..byte.."m",
                        kind = "fg" }
        return setmetatable(color, colormt)
    end
    if x256_store[byte] then
        return x256_store[byte]
    else
        local color = make(byte)
        x256_store[byte] = color
        return color
    end
end

local function ansi_bg(byte)
    local function make (byte)
        byte_panic(byte)
        local color = { value = schar(27).."[48;5;"..byte.."m",
                        kind = "bg" }
        return setmetatable(color, colormt)
    end
    if x256_store[byte] then
        return x256_store[byte]
    else
        local color = make(byte)
        x256_store[byte] = color
        return color
    end
end


























local x24k = setmetatable({}, {__mode = "v"})

local fg24pre = schar(27) .. "[38;2;"

local function fg24(r,g,b)
   byte_panic(r)
   byte_panic(g)
   byte_panic(b)
   local color = { value = fg24pre
                           .. r .. ";" .. g .. ";" .. b .. "m",
                   kind = "fg" }
   if x24k[color] then
      return x24k[color]
   end
   x24k[color] = color
   return setmetatable(color, colormt)
end

local bg24pre = schar(27) .. "[48;2;"

local function bg24(r,g,b)
   byte_panic(r)
   byte_panic(g)
   byte_panic(b)
   local color = { value = bg24pre
                           .. r .. ";" .. g .. ";" .. b .. "m",
                   kind = "bg" }
   if x24k[color] then
      return x24k[color]
   end
   x24k[color] = color
   return setmetatable(color, colormt)
end

anterm["fg"], anterm["bg"] = ansi_fg, ansi_bg

anterm["fg24"], anterm["bg24"] = fg24, bg24






local jump = {}

function jump.up(num)
    if not num then num = "1" end
    return CSI..num.."A"
end

function jump.down(num)
    if not num then num = "1" end
        return CSI..num.."B"
end

function jump.forward(num)
    if not num then num = "1" end
    return CSI..num.."C"
end

jump.right = jump.forward

jump.back = function(num)
    if not num then num = "1" end
    return CSI..num.."D"
end

local __nl = CSI .. 1 .. "B" .. CSI .. 1 .. "G"

function jump.nl()
   return __nl
end

jump.left = jump.back

local function Jump(_,row,column)
    return CSI..row..";"..column.."H"
end

local J = { __call = Jump}
setmetatable(jump,J)

anterm["jump"] = jump

function anterm.rc(row, column)
   return CSI .. row .. ";" .. column .. "H"
end

anterm.rowcol = anterm.rc

function anterm.colrow(col, row)
   return CSI .. row .. ";" .. col .. "H"
end

function anterm.col(col)
   col = col or 1
   return CSI .. col .. "G"
end






local erase = {}
anterm.erase = erase

local e__below = CSI .. "0J"
local e__above = CSI .. "1J"
local e__all   = CSI .. "2J"
local e__right = CSI .. "0K"
local e__left  = CSI .. "1K"
local e__line  = CSI .. "2K"

function erase.below() return e__below end

function erase.above() return e__above end

function erase.all()   return e__all   end

function erase.right() return e__right end

function erase.left()  return e__left  end

function erase.line()  return e__line  end







local cursor = {}
function erase.box(tc, tr, bc, br, dash)
   dash = dash or " "
   assert(tr <= br and tc <= bc, "box must be at least 1 by 1: "
          .. " tc: " .. tc .. " tr: " .. tr
          .. " bc: " .. bc .. " br: " .. br)
   local phrase = anterm.stash()
               .. Jump(nil, tr, tc)
   br = br + 1
   bc = bc + 1
   local blanks = rep(dash, bc - tc)
   local nl = anterm.col(tc) .. jump.down(1)
   for i = 1, br - tr do
      phrase = phrase .. blanks .. nl
   end
   return phrase .. anterm.pop()
end





local random = assert(math.random)

function erase.checker(tc, tr, bc, br, dash, mod)
   mod = mod or 3
   dash = dash or "."
   local space = jump.forward()
   assert(tr <= br and tc <= bc, "box must be at least 1 by 1")
   local skip = random(1, mod)
   local phrase = anterm.stash()
               .. Jump(nil, tr, tc)
   br = br + 1
   bc = bc + 1

   local nl = anterm.col(tc) .. jump.down(1)
   for i = 1, br - tr do
      local checks = ""
      for j = 1, bc - tc do
         if skip % mod == 0 then
            checks = checks .. dash
         else
            checks = checks .. space
         end
         skip = skip + 1
      end
      phrase = phrase .. checks .. nl
   end
   return phrase .. anterm.pop()
end






local mouse = {}
anterm.mouse = mouse

local buttons = {[0] ="MB0", "MB1", "MB2", "MBNONE"}










function mouse.track(on)
   if on == true then
      return "\x1b[?1003h"
   end

   return "\x1b[?1003l"
end



function mouse.ismousemove(seq)
   if sub(seq, 1, 3) == "\x1b[M" then
      return true
   end
end










function mouse.parse_fast(seq)
   local kind, col, row = byte(seq,4), byte(seq, 5), byte(seq, 6)
   kind = kind - 32
   local m = {row = row - 32, col = col - 32}
   -- Get button
   m.button = buttons[kind % 4]
   -- Get modifiers
   kind = rshift(kind, 2)
   m.shift = kind % 2 == 1
   kind = rshift(kind, 1)
   m.meta = kind % 2 == 1
   kind = rshift(kind, 1)
   m.ctrl = kind % 2 == 1
   kind = rshift(kind, 1)
   m.moving = kind % 2 == 1
   -- we skip a bit that seems to just mirror .moving
   m.scrolling = kind == 2
   return m
end








function mouse.parse(seq)
   if mouse.ismousemove(seq) then
      return mouse.parsefast(seq)
   else
      return nil, "sequence was not a mouse move", seq
   end
end






function anterm.stash()
   return "\x1b7"
end

function anterm.pop()
   return "\x1b8"
end
anterm.cursor = cursor

function cursor.hide()
   return "\x1b[?25l"
end

function cursor.show()
   return "\x1b[?25h"
end

cursor.stash = anterm.stash
cursor.pop = anterm.pop












local report = {}

function report.area()
   return "\x1b[18t"
end
anterm.report = report









local totty = {}
local lines = assert(core.lines)
local collect = assert(core.collect)











function totty.nl_to_jumps(str)
  local l = collect(lines, str)
  local phrase = ""
  local length = 0
  for i,v in ipairs(l) do
    phrase = phrase..v..a.jump.down()..a.jump.back(utf8.width(v))
    if length < utf8.width(v) then
      length = utf8.width(v)
    end
  end
  return phrase, length, #l
end

--- takes a string and a width in columns.
--  Returns the amount of string which fits the width.
function totty.truncate(str, width)
  local trunc = utf8.sub(str,1,width)
  if utf8.len(trunc) == utf8.width(trunc) then
    return trunc
  else
    local i = 1
    while utf8.width(trunc) > width do
      -- io.write("width is ", utf8.width(trunc), "  target: ", width, "\n")
      trunc = utf8.sub(str,1,width-i)
      i = i + 1
    end
    return trunc
  end
end

-- takes a string, returning a string which, when printed, will:
-- print the string as a column, return to the top, and move one beyond
-- the column thereby printed.
function totty.collimate(str)
  local phrase, length, lines = totty.nl_to_jumps(str)
  return phrase..a.jump.up(lines)..a.jump.forward(length)
end

anterm.totty = totty














local __navigation = {  UP       = "\x1b[A",
                        DOWN     = "\x1b[B",
                        RIGHT    = "\x1b[C",
                        LEFT     = "\x1b[D",
                        SHIFT_UP = "\x1b[1;2A",
                        SHIFT_DOWN = "\x1b[1;2B",
                        SHIFT_RIGHT = "\x1b[1;2C",
                        SHIFT_LEFT  = "\x1b[1;2D",
                        HYPER_UP    = "\x1b[5~",
                        HYPER_DOWN  = "\x1b[6~",
                        HYPER_RIGHT = "\x1b[F",
                        HYPER_LEFT  = "\x1b[H",
                        ALT_UP    = "\x1b\x1b[A",
                        ALT_DOWN  = "\x1b\x1b[B",
                        ALT_RIGHT = "\x1bf", -- heh
                        ALT_LEFT  = "\x1bb",
                        SHIFT_ALT_UP = "\x1b[1;10A",
                        SHIFT_ALT_DOWN = "\x1b[1;10B",
                        SHIFT_ALT_RIGHT = "\x1b[1;10C",
                        SHIFT_ALT_LEFT  = "\x1b[1;10D",
                        SHIFT_TAB  = "\x1b[Z",
                        ALT_TAB    = "\x1b\t",
                        NEWLINE    = "\n",
                        RETURN     = "\r",
                        TAB        = "\t",
                        BACKSPACE  = "\127",
                        DELETE     = "\x1b[3~",
                        ESC        = "\x1b",
                     }





local __alt_nav = {  UP       = "\x1bOA",
                     DOWN     = "\x1bOB",
                     RIGHT    = "\x1bOC",
                     LEFT     = "\x1bOD",
                  }























local navigation = {}

for k,v in pairs(__navigation) do
   navigation[v] = k
end
for k,v in pairs(__alt_nav) do
   navigation[v] = k
end

__navigation, __alt_nav = nil, nil

anterm.navigation = navigation

function anterm.is_nav(seq)
   if navigation[seq] then
      return navigation[seq]
   else
      return false, "not a recognized NAV token", seq
   end
end



return anterm
