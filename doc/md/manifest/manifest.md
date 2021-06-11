# Manifest


  Manifests are how we configure Orb documents\.

In essence they are simply [TOML](orb/-/blob/trunk/doc/mdUsers/atman/Dropbox/br/orb/orb/manifest/manifest.md) code blocks, which can be
found within a specific file, or more usually in a top\-level Orb document
called `manifest.orb`\.

Presumably we'll have a global manifest in `$BRIDGE_HOME` as well\.

Other than that I have basically no idea what this is actually going to look
like\.  Any code block with `#!toml #manifest` in it will end up in the
appropriate Manifest, and access is of course through the skein\.


### Fields

  This will be a list of all key/value pairs and subtables recognized by the
manifest format\.


-  weave:  A table for weave\-specific configuration\.

   - module\_url:  The base for [refs](httk://) within the module itself\.

   - project\_url:  The project base url\.

       We'll need to do a bit of magic to make this work, because
       the Git\(Hub|Lab\) style of constructing URLs isn't as simple
       as project\_url \+ module\_name \+ rest\_of\_the\_ref\.

       So the weave table will have some way to construct the
       intermediate information, with a "sensible" default: for a
       markdown weave on Gitlab, `/-/blob/trunk/doc/md/`\.


- knit:  A table for knit\-specific configuration\.

    This will ultimately include versioning for various dependencies,
    which is a complex system with several unfilled prerequisites\.

    Or maybe the bridge\-specific stuff goes in a `bridge` table\.  TBD\.


## Implementation

  The Manifest itself is just a container: you feed it data, and it represents
that data as Lua tables\.

TOML codeblocks, like any codeblock, just have a `code_body` Node, which isn't
normally parsed within it\.

We want to be able to read from a Manifest without blocking any potential
fields \(I think?\) so we'll use `__call` to do the two things a Manifest is
expected to do: `manifest(codeblock)` will add the TOML to the existing
Manifest, and `manifest(true)` will return a new Manifest inheriting from the
old one\.

We use the latter for e\.g\. encountering a `#manifest` block inside a file, or
if we have a global `manifest.orb`, we use it to create the `.manifest` field
on the Lume\.  I'm not in love with this code signature, but at least at the
moment I prefer it to having a mixture of methods and plain\-old\-data\.


#### imports

```lua
local meta = require "core:core/cluster" . Meta
local s = require "status:status" ()
s.verbose = true
s.boring = false

local Skein = require "orb:skein/skein"

local Toml = require "lon:loml"
```


### Manifest

```lua
local Manifest = meta {}
```


```lua

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
```

```lua
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
```


```lua
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
```



```lua
local function new(block)
   local manifest = meta(Manifest)
   if block then
      _addBlock(manifest, block)
   end
   return manifest
end

Manifest.idEst = new
```

```lua
return new
```
