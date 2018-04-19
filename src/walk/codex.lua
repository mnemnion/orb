





local s = require "core/status" ()
s.verbose = true
local Dir  = require "walk/directory"
local File = require "walk/file"
local Path = require "walk/path"




local Codex = {}
Codex.__index = Codex
local __Codices = {} -- One codex per directory

















function Codex.caseDir(codex, dir)
   s:verb("dir: " .. tostring(dir))
   assert(dir.idEst == Dir, "dir not a directory")
   local codexRoot = codex.root:basename()
   s:verb("root: " .. tostring(codex.root) .. " base: " ..tostring(codexRoot))
   local subdirs = dir:getsubdirs()

   s:verb("  " .. "# subdirs: " .. #subdirs)
   local files = dir:getfiles()
   s:verb(" " .. "# files: " .. #files)
   for i, file in ipairs(files) do
      s:verb("  -  " .. tostring(file))
   end
   return codex
end



function Codex.caseOrb(codex)
   local orb = codex.orb
   assert(orb.idEst == Dir, "orb directory not a directory")
   Codex.caseDir(codex, orb)
   return codex
end












local function isACodex(dir, codex)
   local isCo = false
   local orbDir, srcDir, libDir, srcLibDir = nil, nil, nil, nil
   codex.root = dir
   dir:getsubdirs()
   for i, sub in ipairs(dir.subdirs) do
      local name = sub:basename()
      if name == "orb" then
         s:verb("orb: " .. tostring(sub))
         orbDir = sub
         codex.orb = sub
      elseif name == "src" then
         s:verb("src: " .. tostring(sub))
         srcDir = Dir(sub)
         codex.src = sub
         srcDir:getsubdirs()
         for j, subsub in ipairs(sub.subdirs) do
            local subname = subsub:basename()
            if subname == "lib" then
               s:verb("src/lib: " .. tostring(subsub))
               subLibDir = subsub
            end
         end
          --]]
      elseif name == "lib" then
         s:verb("lib: " .. tostring(sub))
         libDir = sub
         codex.lib = sub
      end
   end
   if orbDir and srcDir and libDir and subLibDir then
      -- check equality of /lib and /src/lib
      codex.codex = true
   end
   return codex
end



local function new(dir)
   if type(dir) == "string" then
      dir = Dir(dir)
   end
   if __Codices[dir] then
      return __Codices[dir]
   end
   local codex = setmetatable({}, Codex)
   codex = isACodex(dir, codex)

   return codex
end




Codex.idEst = new
return new
