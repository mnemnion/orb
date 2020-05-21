








































































































local s = require "singletons/status" ()
local a = require "anterm:anterm"
s.chatty = true



local File = require "fs:fs/file"
local Path = require "fs:fs/path"
local Doc  = require "orb:orb/doc"
local knitter = require "orb:knit/newknit" ()
local compiler = require "orb:compile/compiler"



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
   woven.md = {}
   woven.md.text = skein.source.doc:toMarkdown(skein)
   woven.md.path = skein.source.file.path
                       :subFor(skein.source_base,
                               skein.weave_base .. "/md",
                               "md")
   return skein
end















function Skein.compile(skein)
   compiler:compile(skein)
   return skein
end








function Skein.commit(skein, stmts)
   return skein
end



















local function writeOnChange(scroll, path, dont_write)
   -- if we don't have a path, there's nothing to be done
   -- #todo we should probably take some note of this situation
   if not path then return end
   local current = File(path):read()
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
   for _, scroll in pairs(skein.knitted) do
      writeOnChange(scroll, scroll.path, true)
   end
   local md = skein.woven.md
   if md then
      writeOnChange(md.text, md.path, true)
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
