

























































































local s = require "singletons/status" ()
local a = require "anterm:anterm"
s.chatty = true



local File = require "fs:fs/file"
local Path = require "fs:fs/path"
local Doc  = require "orb:orb/doc"
local knitter = require "orb:knit/newknit" ()
local weaver = require "orb:weave/weave"



local Skein = {}
Skein.__index = Skein





























function Skein.load(skein)
   skein.source.text = skein.source.file:read()
   return skein
end












function Skein.filter(skein)
   return skein
end











function Skein.spin(skein)
   skein.source.doc = Doc(skein.source.text)
   return skein
end








function Skein.format(skein)
   return skein
end










function Skein.knit(skein)
   knitter:knit(skein)
   return skein
end

















function Skein.weave(skein)
   if not skein.woven then
      skein.woven = {}
   end
   local woven = skein.woven
   woven.md = skein.source.doc:toMarkdown(skein)
   return skein
end











function Skein.commit(skein, stmts)
   return skein
end













local function writeOnChange(scroll, dont_write)
   -- If the text has changed, write it
   local out_file = scroll.path
   -- if we don't have a path, there's nothing to be done
   -- #todo we should probably take some note of this situation
   if not out_file then return end
   local current = File(out_file):read()
   local newest = tostring(scroll)
   if newest ~= current then
      s:chat(a.green("    - " .. tostring(out_file)))
      if not dont_write then
         File(out_file):write(newest)
      end
      return true
   else
   -- Otherwise do nothing
      return nil
   end
end



function Skein.persist(skein)
   for _, scroll in pairs(skein.knitted.scrolls) do
      writeOnChange(scroll, true)
   end
   return skein
end












local function new(path, codex)
   local skein = setmetatable({}, Skein)
   skein.source = {}
   if codex then
      skein.codex = codex
      -- lift info off the codex here
      skein.project     = codex.project
      -- this should just be codex.orb but I turned that into a Deck for some
      -- silly reason
      skein.source_base = codex.orb_base
      skein.knit_base   = codex.src
      skein.weave_base  = codex.doc
      -- #todo we're including the Dirs here, when what we're likely to need
      -- is the Path, is this wise?  It's easy to reach the latter...
   end
   skein.source.file = File(Path(path):absPath())
   return skein
end

Skein.idEst = new




return new
