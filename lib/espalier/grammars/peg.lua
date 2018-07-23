











local L = require "espalier/elpatt"
local D, E, P, R, S, V   =  L.D, L.E, L.P, L.R, L.S, L.V
local Grammar = require "espalier/grammar"



local function pegylator(_ENV)
   START "rules"
   ---[[
   SUPPRESS ("WS",  "enclosed", "form",
            "element" ,"elements",
            "allowed_prefixed", "allowed_suffixed",
            "simple", "compound", "prefixed", "suffixed"  )
   --]]
   local comment_m  = -P"\n" * P(1)
   local comment_c =  comment_m^0 * #P"\n"
   local letter = R"AZ" + R"az"
   local valid_sym = letter + P"-"
   local digit = R"09"
   local sym = valid_sym + digit
   local WS = (P' ' + P'\n' + P',' + P'\09')^0
   local symbol = letter * ( -(P"-" * WS) * sym )^0
   local h_string    = (-P"`" * core.escape)^0
   local d_string = (-P'"' * core.escape)^0
   local s_string = (-P"'" * core.escape)^0
   local range_match =  -P"-" * -P"\\" * -P"]" * P(1)
   local range_capture = (range_match + P"\\-" + P"\\]" + P"\\")
   local range_c  = range_capture^1 * P"-" * range_capture^1
   local set_match = -P"}" * -P"\\" * P(1)
   local set_c    = (set_match + P"\\}" + P"\\")^1
   local some_num_c =   digit^1 * P".." * digit^1
                +   (P"+" + P"-")^0 * digit^1


   rules   =  V"comment"^0 * V"rule"^1
   rule    =  V"lhs" * V"rhs"
   lhs     =  WS * V"pattern" * WS * ( P":" + P"=" + ":=")
   rhs     =  V"form"

   form   =  V"element" * V"elements"
   pattern =  symbol
         +  V"hidden_pattern"
   hidden_pattern =  P"`" * symbol * P"`"

   element  =   -V"lhs" * WS
            *  ( V"simple"
            +    V"compound"
            +    V"comment" )
   elements  =  V"choice"
             +  V"cat"
             +  P""

   choice =  WS * P"/" * V"form"
   cat =  WS * V"form"
   compound =  V"group"
          +  V"enclosed"
          +  V"hidden_match"

   group   =  WS * V"pel"
           *  WS * V"form" * WS
           *  V"per"
   pel     = D "("
   per     = D ")"

   enclosed =  V"literal"
            +  V"hidden_literal"
            +  V"set"
            +  V"range"

   hidden_match =  WS * P"``"
                *  WS * V"form" * WS
                *  P"``"

   simple   =  V"suffixed"
            +  V"prefixed"
            +  V"atom"

   comment  =  D";" * comment_c

   prefixed =  V"if_not_this"
            +  V"not_this"
            +  V"if_and_this"
            +  V"capture"

   suffixed =  V"optional"
            +  V"more_than_one"
            +  V"maybe"
            +  V"with_suffix"
            +  V"some_number"

   if_not_this = P"!" * WS * V"allowed_prefixed"
   not_this    = P"-" * WS * V"allowed_prefixed"
   if_and_this = P"&" * WS * V"allowed_prefixed"
   capture     = P"~" * WS * V"allowed_prefixed"

   literal =  D'"' * d_string * D'"'
           +  D"'" * s_string * D"'"

   hidden_literal = -P"``" * D"`" * hidden_string * -P"``" * D"`"

   set     =  P"{" * set_c^1 * P"}"

-- Change range to not use '-' separator instead require even # of bytes.
-- Ru catches edge cases involving multi-byte chars.

   range   =  P"[" * range_c * P"]"

   optional      =  V"allowed_suffixed" * WS * P"*"
   more_than_one =  V"allowed_suffixed" * WS * P"+"
   maybe         =  V"allowed_suffixed" * WS * P"?"

   with_suffix   =  V"some_number" * V"which_suffix"
   which_suffix  =  ( P"*" + P"+" + P"?")
   some_number   =  V"allowed_suffixed" * WS * V"some_suffix"
   some_suffix   = P"$" * V"repeats"

   repeats       =  Csp(some_num_c)
   allowed_prefixed =  V"compound" + V"suffixed" + V"atom"
   allowed_suffixed =  V"compound" + V"prefixed" + V"atom"

   atom =  V"ws" + symbol

   ws = Csp(P"_")
end
