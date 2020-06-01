








































































































































































































































local uv = require "luv"
local sql = assert(sql)

local s = require "status:status" ()
s.verbose = true

local git_info = require "orb:util/gitinfo"
local Skein = require "orb:skein/skein"
local Deck = require "orb:lume/deck"
local Watcher = require "orb:lume/watcher"
-- #todo replace this with /database after new toolchain lands
local database = require "orb:compile/newdatabase"

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
   -- cache result
   rawset(net, ref, skein)
   return skein
end





















local create, resume, running, yield = assert(coroutine.create),
                                       assert(coroutine.resume),
                                       assert(coroutine.running),
                                       assert(coroutine.yield)

local function _loader(skein, lume, path)
   s:verb("begin read of %s", path)
   skein :load() :spin() :knit() :weave() :compile()
   s:verb("processed: %s", path)
   lume.count = lume.count - 1
   lume.rack:insert(running())
   local stmts, ids, git_info, now = yield()
   skein:commit(stmts, ids, git_info, now)
   yield()
   skein:persist()
end

function Lume.bundle(lume)
   lume.count = 0
   repeat
      local skein = lume.net[lume.shuttle:pop()]
      local path = tostring(skein.source.file)
      s:verb("loaded skein: %s", path)
      lume.count = lume.count + 1
      resume(create(_loader), skein, lume, path)
   until lume.shuttle:is_empty()
   s:verb("cleared shuttle")
   lume:persist()
end










local commitBundle, commitSkein = assert(database.commitBundle),
                                  assert(database.commitSkein)

function Lume.persist(lume)
   local transactor = uv.new_idle()
   local transacting = true
   transactor:start(function()
      s:verb("lume.count: %d", lume.count)
      if lume.count > 0 then return end
      local conn = lume.conn
      -- set up transaction
      conn:exec "BEGIN TRANSACTION;"
      s:chat("writing artifacts to database")
      local stmts, ids, now = commitBundle(lume)
      local git_info = lume:gitInfo()
      for co in pairs(lume.rack) do
         if coroutine.status(co) ~= 'dead' then
            local ok, err = resume(co, stmts, ids, git_info, now)
            if not ok then
               error ("coroutine broke during commit: " .. err)
               conn:exec "ROLLBACK;"
               transacting = false
               transactor:stop()
            end
         end
      end
      -- commit transaction
      conn:exec "COMMIT;"
      -- checkpoint
      -- use a pcall because we get a (harmless) error if the table is locked
      -- by another process:
      pcall(conn.pragma.wal_checkpoint, "0") -- 0 == SQLITE_CHECKPOINT_PASSIVE
      transacting = false
      transactor:stop()
   end)
   local persistor = uv.new_idle()
   persistor:start(function()
      if transacting then return end
      for co in pairs(lume.rack) do
         local ok, err = resume(co)
         if not ok then
            error ("coroutine broke during file write: " .. err)
            persistor:stop()
         end
      end
      -- GC the coroutines, now that we're done with them
      table.clear(lume.rack)
      persistor:stop()
   end)
end









function Lume.run(lume, watch)
   -- determine if we're already in an event loop
   local on_loop = uv.loop_alive()
   local launcher = uv.new_idle()
   launcher:start(function()
      lume:bundle()
      if watch then
         -- watcher goes here
      end
      launcher:stop()
   end)

   if not on_loop then
      print "running loop"
      uv.run 'default'
   end
end






local function changer(lume)
   local function onchange(watcher, fname)
      local full_name = tostring(lume.orb) .. "/" .. fname
      print ("changed " .. full_name)
      if lume.docs[full_name] and full_name:sub(-4) == ".orb" then
         local doc = Doc(lume.files[full_name]:read())
         local knit_doc = knitter:knit(doc)
         local knit_name = tostring(lume.src) .. "/"
                           .. fname : sub(1, -5) .. ".lua"
         local written = write(knit_name, tostring(knit_doc))
         print("knit_doc is type " .. type   (knit_doc))
      else
         print("false")
      end
   end

   return onchange
end

local function _changer(lume)
   return function (watcher, fname)
      print ("changed " .. fname)
   end
end

local function renamer(lume)
   local function onrename(watcher, fname)
      print ("renamed " .. fname)
   end

   return onrename
end

function Codex.serve(lume)
   lume.server = Watcher { onchange = _changer(lume),
                            onrename = renamer(lume) }
   lume.server(tostring(lume.orb))
end










function Lume.gitInfo(lume)
   lume.git_info = git_info(tostring(lume.root))
   return lume.git_info
end











function Lume.projectInfo(lume)
   local proj = {}
   proj.name = _Bridge.args.project or lume.project
   if lume.git_info.is_repo then
      proj.repo_type = "git"
      proj.repo = lume.git_info.url
      proj.home = lume.home or ""
      proj.website = lume.website or ""
      local alts = {}
      for _, repo in ipairs(lume.git_info.remotes) do
         alts[#alts + 1] = repo[2] ~= proj.repo and repo[2] or nil
      end
      proj.repo_alternates = table.concat(alts, "\n")
   end
   return proj
end











function Lume.versionInfo(lume)
   if not _Bridge.args.version then
      return { is_versioned = false }
   end
   local version = { is_versioned = true }
   for k,v in pairs(_Bridge.args.version) do
      version[k] = v
   end
   version.edition = _Bridge.args.edition or ""
   version.stage   = _Bridge.args.stage or "SNAPSHOT"
   return version
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



local function new(dir, db_conn, no_write)
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
   lume.conn = db_conn and _Bridge.new_modules_db(db_conn)
                       or _Bridge.modules_conn
                       or error "no database"
   lume.no_write = no_write
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
   _Lumes[dir] = lume
   return lume
end

Lume.idEst = new



return new
