






















































































local File = require "fs:fs/file"
local Path = require "fs:fs/path"
local Doc  = require "orb:orb/doc"
local knitter = require "orb:knit/newknit" ()



local Skein = {}
Skein.__index = Skein




























function Skein.load(skein)
   skein.source = { text = File(skein.source.path):read() }
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












local function new(codex, path)
   local skein = setmetatable({}, Skein)
   skein.codex = codex
   skein.source = { path = Path(path) }
   return skein
end

Skein.idEst = new




return new
