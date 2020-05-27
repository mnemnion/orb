








































































































































































































































local uv = require "luv"
local sql = assert(sql)

local s = require "status:status" ()
s.verbose = false

local git_info = require "orb:util/gitinfo"
local Skein = require "orb:skein/skein"
local Deck = require "orb:lume/deck"

local Dir  = require "fs:directory"
local File = require "fs:file"
local Path = require "fs:path"
local Deque = require "deque:deque"
local Set = require "set:set"



local Lume = {}
Lume.__index = Lume










local _Lumes = setmetatable({}, { __mode = "kv" })




























local Net = {}



function Net.__index(net, ref)
   -- resolve reference
   -- make Skein
   -- net carries a reference to parent lume:
   local skein = Skein(ref, net.lume)
   return skein
end





















local create, resume, running, yield = assert(coroutine.create),
                                       assert(coroutine.resume),
                                       assert(coroutine.running),
                                       assert(coroutine.yield)

function Lume.bundle(lume)
   lume.count = 0
   repeat
      local skein = lume.net[lume.shuttle:pop()]
      local path = tostring(skein.source.file)
      s:verb("loaded skein: %s", path)
      lume.count = lume.count + 1
      local co = create(function()
         s:verb("begin read of %s", path)
         skein:load():spin():knit():weave()
         s:verb("processed: %s", path)
         lume.count = lume.count - 1
         lume.rack:insert(running())
         local stmts = yield()
         skein:commit(stmts)
         yield()
         skein:persist()
      end)
      resume(co)
   until lume.shuttle:is_empty()
   s:verb("cleared shuttle")
   lume:persist()
end










function Lume.persist(lume)
   local transactor = uv.new_idle()
   local transacting = true
   transactor:start(function()
      s:verb("lume.count: %d", lume.count)
      s:chat("writing artifacts to database")
      if lume.count > 0 then return end
      -- set up transaction
      for co in pairs(lume.rack) do
         resume(co, lume.stmts)
      end
      -- commit transaction
      transacting = false
      transactor:stop()
   end)
   local persistor = uv.new_idle()
   persistor:start(function()
      if transacting then return end
      for co in pairs(lume.rack) do
         resume(co)
      end
      persistor:stop()
   end)
end









function Lume.run(lume, watch)
   local launcher = uv.new_idle()
   launcher:start(function()
      lume:bundle()
      if watch then
         -- watcher goes here
      end
      launcher:stop()
   end)
   uv.run 'default'
end







































local function _findSubdirs(lume, dir)
   local isCo = false
   local orbDir, srcDir, libDir = nil, nil, nil
   local docDir, docMdDir, docDotDir, docSvgDir = nil, nil, nil, nil
   lume.root = dir
   local subdirs = dir:getsubdirs()

   for i, sub in ipairs(subdirs) do
      local name = sub:basename()
      if name == "orb" then
         s:verb("orb: " .. tostring(sub))
         orbDir = sub
         lume.orb = sub
      elseif name == "src" then
         s:verb("src: " .. tostring(sub))
         srcDir = Dir(sub)
         lume.src = sub
      elseif name == "doc" then
         s:verb("doc: " .. tostring(sub))
         docDir = sub
         lume.doc = sub
         local subsubdirs = docDir:getsubdirs()
         for j, subsub in ipairs(subsubdirs) do
            local subname = subsub:basename()
            if subname == "md" then
               s:verb("doc/md: " .. tostring(subsub))
               docMdDir = subsub
               lume.docMd = subsub
            elseif subname == "dot" then
               s:verb("doc/dot: " .. tostring(subsub))
               docDotDir = subsub
               lume.docDot = subsub
            elseif subname == "svg" then
               s:verb("doc/svg: " .. tostring(subsub))
               docSvgDir = subsub
               lume.docSvg = subsub
            end
         end
      end
   end

   return (orbDir and srcDir and docDir)
end



local function new(dir, db_conn)
   if type(dir) == "string" then
      dir = Dir(dir)
   end
   -- #todo this should use a unique property of the directory, which the
   -- inode is and the path string is not.
   if _Lumes[dir] then
      return _Lumes[dir]
   end
   local lume = setmetatable({}, Lume)
   -- #todo this prevents writing files and shouldn't be on by default:
   lume.conn = db_conn and sql.open(db_conn)
                       or _Bridge.modules_connn
                       or error "no database"
   lume.no_write = true
   lume.shuttle = Deque()
   lume.rack = Set()
   --setup lume prepared statements
   lume.stmts = {}
   local well_formed = _findSubdirs(lume, dir)
   if well_formed then
      lume.deck = Deck(lume, lume.orb)
   else
      s:warn("root codex %s is not well formed", tostring(lume.orb))
   end
   lume.project = dir.path[#dir.path]
   lume.git_info = git_info(tostring(dir))
   lume.net = setmetatable({}, Net)
   lume.net.lume = lume
   return lume
end

Lume.idEst = new



return new
