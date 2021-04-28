

































































local meta = require "core:core/cluster" . Meta
local s = require "status:status" ()
s.verbose = true

local Skein = require "orb:skein/skein"

local Toml = require "lon:loml"






local Manifest = meta {}




local function _addBlock(manifest, block)
   -- quick sanity check
   assert(block and block.isNode, "manifest() must receive a Node")
   local codebody = block :select "code_body" () :span()
   local toml = Toml(codebody)
   if toml then
      s:verb("adding contents of manifest codebody")
      local contents = toml:toTable()
      for k,v in pairs(contents) do
         s:verb("adding %s : %s", k, v)
         manifest[k] = v
      end
   else
       s:warn("no contents generated from #manifest block, line %d",
              block:linePos())
   end
end



local function _addSkein(manifest, skein)
   -- check if the Skein has been loaded and spun (probably not)
   if (not skein.source.text) or (not skein.source.doc) then
      skein:load():spin():tag()
   end
   local nodes = skein.tags.manifest
   if nodes then
      for _, block in ipairs(nodes) do
         _addBlock(manifest, block)
      end
   else
      s:verb("no manifest blocks found in %s" .. tostring(skein.source.file))
   end
end




function Manifest.__call(manifest, msg)
   if msg == true then
      -- we make and return a new Manifest instance
      return meta(manifest)
   end
   -- otherwise this should be a codeblock or a Skein
   if msg.idEst and msg.idEst == Skein then
      s:verb("manifest was given a skein")
      _addSkein(manifest, msg)
   elseif msg.isNode and msg.id == 'codeblock' then
      s:verb("manifest was given a codeblock")
      _addBlock(manifest, msg)
   end
end





local function new(block)
   local manifest = meta(Manifest)
   if block then
      _addBlock(manifest, block)
   end
   return manifest
end

Manifest.idEst = new



return new

