






















































































local File = require "fs:fs/file"
local Path = require "fs:fs/path"
local Doc  = require "orb:orb/doc"
local knitter = require "orb:knit/newknit" ()



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
   return skein
end











function Skein.commit(skein, stmts)
   return skein
end








function Skein.persist(skein)
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
