

































































local meta = require "core:core/cluster" . Meta
local Toml = require "lon:loml"
local s = require "status:status" ()






local Manifest = meta {}




local function _addBlock(manifest, block)
   -- quick sanity check
   assert(block and block.isNode, "manifest() must receive a Node")
   local codebody = block :select "code_body" ()
   local contents = Toml(codebody) :toTable()
   if contents then
      for k,v in pairs(contents) do
         manifest[k] = v
      end
   else
       s:halt("no contents generated from #manifest block, line %d",
              block:linePos())
   end
end




function Manifest.__call(manifest, msg)
   if msg == true then
      -- we make and return a new Manifest instance
      return meta(manifest)
   end
   -- otherwise this should be a codeblock
   local block = msg
   _addBlock(manifest, block)
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

