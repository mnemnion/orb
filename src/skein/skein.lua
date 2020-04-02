







































local File = require "fs:fs/file"
local Path = require "fs:fs/path"
local Doc  = require "orb:orb/doc"



local Skein = {}
Skein.__index = Skein



function Skein.load(skein)
   skein.source = File(skein.source_path):read()
   return skein
end



function Skein.spin(skein)
   skein.doc = Doc(skein.source)
   return skein
end



function Skein.filter(skein)

end



function Skein.format(skein)

end



function Skein.knit(skein)

end



function Skein.weave(skein)

end



function Skein.commit(skein, stmts)

end



function Skein.persist(skein)

end















local function new(path)
   local skein = setmetatable({}, Skein)
   skein.source_path = Path(path)
   return skein
end

Skein.idEst = new




return new
