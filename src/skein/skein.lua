








































































































local s = require "status:status" ()
local a = require "anterm:anterm"
s.chatty = true
s.angry = true



local File = require "fs:fs/file"
local Path = require "fs:fs/path"
local Doc  = require "orb:orb/doc"
local knitter = require "orb:knit/newknit" ()
local compiler = require "orb:compile/compiler"
local database = require "orb:compile/newdatabase"



local Skein = {}
Skein.__index = Skein





























function Skein.load(skein)
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










function Skein.knit(skein)
   local ok, err = pcall(knitter.knit, knitter, skein)
   if not ok then
      s:complain("failure to knit %s: %s", tostring(skein.source.file), err)
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
      woven.md.text = skein.source.doc:toMarkdown(skein)
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
   assert(now)
   stmts.begin:step()
   commitSkein(skein, stmts, ids, git_info, now)
   stmts.commit:step()
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












local function new(path, lume)
   local skein = setmetatable({}, Skein)
   skein.source = {}
   -- handles: string, Path, or File objects
   if not path then
      error "Skein must be constructed with a path"
   end
   if path.idEst ~= File then
      path = File(Path(path):absPath())
   end
   if lume then
      skein.lume = lume
      -- lift info off the lume here
      skein.project     = lume.project
      skein.source_base = lume.orb
      skein.knit_base   = lume.src
      skein.weave_base  = lume.doc
      if lume.no_write then
         skein.no_write = true
      end
   end
   skein.source.file = path
   return skein
end

Skein.idEst = new




return new
