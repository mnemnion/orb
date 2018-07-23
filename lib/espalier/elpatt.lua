









local L = require "lpeg"
local s = require "status" ()
s.verbose = false
local Node = require "espalier/node"
local elpatt = {}
elpatt.P, elpatt.B, elpatt.V, elpatt.R = L.P, L.B, L.V, L.R

local P, C, Cc, Cp, Ct, Carg = L.P, L.C, L.Cc, L.Cp, L.Ct, L.Carg





local Err = require "espalier/error"
elpatt.E, elpatt.EOF = Err.E, Err.EOF




















local function num_bytes(str)
--returns the number of bytes in the next character in str
   local c = str:byte(1)
   if type(c) == 'number' then
      if c >= 0x00 and c <= 0x7F then
         return 1
      elseif c >= 0xC2 and c <= 0xDF then
         return 2
      elseif c >= 0xE0 and c <= 0xEF then
         return 3
      elseif c >= 0xF0 and c <= 0xF4 then
         return 4
      end
   end
end




























local DROP = {}
elpatt.DROP = DROP

local function make_drop(caps)
   local dropped = setmetatable({}, DROP)
   dropped.DROP = DROP
   dropped.first = caps[1]
   dropped.last = caps[3]
   return dropped
end

function elpatt.D(patt)
   return Ct(Cp() * Ct(patt) * Cp()) / make_drop
end

















function elpatt.S(a, ...)
   if not a then return nil end
   local arg = {...}
   local set = P(a)
   for _, patt in ipairs(arg) do
      set = set + P(patt)
   end
   return set
end



return elpatt
