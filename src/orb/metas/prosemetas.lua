



local Twig = require "orb:orb/metas/twig"

local Phrase = require "singletons:singletons/phrase"



local Prose_M = {}



local bounds = { bold      = "*",
                 italic    = "/",
                 literal   = "=",
                 verbatim  = "`",
                 underline = "_",
                 strike    = "~" }



local byte = assert(string.byte)

local function _fillGen(bookend)
   local bound = byte(bounds[bookend])
   return function(bounded)
      if #bounded == 0 then
         local span = bounded:span()
         local count = 1
         while true do
            if byte(count + 1) ~= bound then
               break
            end
            count = count + 1
         end
         -- make bookend nodes
      else

      end
   end
end





return Prose_M
