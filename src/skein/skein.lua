




































local Skein = {}
Skein.__index = Skein



function Skein.load(path)

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















local function new()
   local skein = setmetatable({}, Skein)

   return skein
end

Skein.idEst = new




return new
