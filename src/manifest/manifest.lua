

































































local meta = require "core:core/cluster" . Meta
local s = require "status:status" ()
s.verbose = false
s.boring = false

local Skein = require "orb:skein/skein"

local Toml = require "lon:loml"






local Manifest = meta {}





local function _addTable(manifest, tab)
   for k,v in pairs(tab) do
      s:verb("adding %s : %s", k, v)
      if type(v) == 'table' and manifest[k] ~= nil then
         _addTable(manifest[k], v)
      else
         manifest[k] = v
      end
   end
end

local function _addBlock(manifest, block)
   -- quick sanity check
   assert(block and block.isNode, "manifest() must receive a Node")
   local code_type = block :select 'code_type' () :span()
   if code_type ~= 'toml' then
      s:verb("don't know what to do with a %s codeblock tagged with #manifest",
             code_type)
      return
   end
   local codebody = block :select 'code_body' () :span()
   local toml = Toml(codebody)
   if toml then
      s:verb("adding contents of manifest codebody")
      local contents = toml:toTable()
      _addTable(manifest, contents)
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
         if block.id == 'codeblock' then
            s:verb "adding codeblock from Skein"
            _addBlock(manifest, block)
         else
            s:verb("don't know what to do with a %s tagged "
                   .. "with #manifest", block.id)
         end
      end
   else
      s:verb("no manifest blocks found in %s" .. tostring(skein.source.file))
   end
end




function Manifest.__call(manifest, msg)
   s:bore "entering manifest()"
   if msg == true then
      -- we make and return a new Manifest instance
      return setmetatable({}, { __index = manifest,
                                __call  = Manifest.__call })

   end
   -- otherwise this should be a codeblock or a Skein
   if msg.idEst and msg.idEst == Skein then
      s:bore("manifest was given a skein")
      _addSkein(manifest, msg)
   elseif msg.isNode and msg.id == 'codeblock' then
      s:bore("manifest was given a codeblock")
      _addBlock(manifest, msg)
   end
   s:bore "leaving manifest()"
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

