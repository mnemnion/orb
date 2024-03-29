












































































































local s = require "status:status" ()
local a = require "anterm:anterm"
s.chatty = true
s.angry = false



local Doc      = require "orb:orb/doc"
local knitter  = require "orb:knit/knit" ()
local compiler = require "orb:compile/compiler"
local database = require "orb:compile/database"
local Manifest; -- optional load which would otherwise be circular

local File   = require "fs:fs/file"
local Path   = require "fs:fs/path"
local Scroll = require "scroll:scroll"
local Notary = require "status:annotate"



local Skein = {}
Skein.__index = Skein





























function Skein.load(skein)
   assert(skein.source.file, "no file on skein")
   local ok, text = pcall(skein.source.file.read, skein.source.file)
   if ok then
      skein.source.text = text
   else
      s:complain("fail on load %s: %s", tostring(skein.source.file), text)
   end
   return skein
end












function Skein.filter(skein)
   return skein
end











function Skein.spin(skein)
   assert(skein.source.text, "no text on skein, call :load or check path")
   local ok, doc = pcall(Doc, skein.source.text)
   if not ok then
       s:complain("couldn't make doc: %s, %s", doc, tostring(skein.source.file))
   end
   skein.source.doc = doc
   return skein
end








function Skein.format(skein)
   return skein
end










Skein.tag = require "orb:tag/tagger"











function Skein.tagAct(skein)
   local mani_blocks = skein.tags.manifest
   if mani_blocks then
      Manifest = require "orb:manifest/manifest"
      s:verb("found manifest blocks in %s", tostring(skein.source.file))
      skein.manifest = skein.manifest and skein.manifest(true) or Manifest()
      for _, block in ipairs(mani_blocks) do
         s:verb("attempted add of node type %s", block.id)
         skein.manifest(block)
      end
   end
   return skein
end










function Skein.knit(skein)
   local ok, err = pcall(knitter.knit, knitter, skein)
   if not ok then
      s:complain("failure to knit %s: %s", tostring(skein.source.file), err)
   end
   if not skein.knitted.lua then
      s:warn("no knit document produced from %s", tostring(skein.source.file))
   end
   return skein
end





















function Skein.weave(skein)
   if not skein.woven then
      skein.woven = {}
   end
   local woven = skein.woven
   woven.md = {}
   local ok, err = pcall(function()
      local scroll = Scroll()
      skein.source.doc:toMarkdown(scroll, skein)
      local ok = scroll:deferResolve()
      if not ok then
         scroll.not_resolved = true
      end
      woven.md.text = tostring(scroll)
      woven.md.scroll = scroll
      -- report errors, if any
      for _, err in ipairs(scroll.errors) do
         s:warn(tostring(skein.source.file) .. ": " .. err)
      end
      -- again, this bakes in the assumption of 'codex normal form', which we
      -- need to relax, eventually.
      woven.md.path = skein.source.file.path
                          :subFor(skein.source_base,
                                  skein.weave_base .. "/md",
                                  "md")
   end)
   if not ok then
      s:complain("couldn't weave %s: %s", tostring(skein.source.file), err)
   end
   return skein
end















function Skein.compile(skein)
   compiler:compile(skein)
   return skein
end









local commitSkein = assert(database.commitSkein)

function Skein.commit(skein, stmts, ids, git_info, now)
   assert(stmts)
   assert(ids)
   assert(git_info)
   assert(now)
   commitSkein(skein, stmts, ids, git_info, now)
   return skein
end













function Skein.transact(skein, stmts, ids, git_info, now)
   assert(stmts)
   assert(ids)
   assert(git_info)
   skein.lume.db.begin()
   commitSkein(skein, stmts, ids, git_info, now)
   skein.lume.db.commit()
   return skein
end














local function writeOnChange(scroll, path, dont_write)
   -- if we don't have a path, there's nothing to be done
   -- #todo we should probably take some note of this situation
   if not path then return end
   local current = File(path):read()
   local newest = tostring(scroll)
   if newest ~= current then
      s:chat(a.green("    - " .. tostring(path)))
      if not dont_write then
         File(path):write(newest)
      end
      return true
   else
   -- Otherwise do nothing
      return nil
   end
end



function Skein.persist(skein)
   for _, scroll in pairs(skein.knitted) do
      writeOnChange(scroll, scroll.path, skein.no_write)
   end
   local md = skein.woven.md
   if md then
      writeOnChange(md.text, md.path, skein.no_write)
   end
   return skein
end











function Skein.transform(skein)
   local db = skein.lume.db
   skein
     : load()
     : filter()
     : spin()
     : knit()
     : weave()
     : compile()
     : transact(db.stmts, db.ids, db.git_info, skein.lume:now())
     : persist()
   return skein
end















local function new(path, lume)
   local skein = setmetatable({}, Skein)
   skein.note = Notary()
   skein.source = {}
   if not path then
      error "Skein must be constructed with a path"
   end
   -- handles: string, Path, or File objects
   if type(path) == 'string' or path.idEst ~= File then
      path = File(Path(path):absPath())
   end
   if lume then
      skein.lume = lume
      -- lift info off the lume here
      skein.project     = lume.project
      skein.source_base = lume.orb
      skein.knit_base   = lume.src
      skein.weave_base  = lume.doc
      skein.manifest    = lume.manifest
      if lume.no_write then
         skein.no_write = true
      end
   end

   skein.source.relpath = Path(tostring(path)):relPath(skein.source_base)
   skein.source.file = path
   return skein
end

Skein.idEst = new




return new

