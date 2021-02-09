































































































local uv = require "luv"
local sql = assert(sql)

local s = require "status:status" ()
s.verbose = false

local git_info = require "orb:util/gitinfo"
local Skein = require "orb:skein/skein"
local Deck = require "orb:lume/deck"
local Watcher = require "orb:lume/watcher"
local database = require "orb:compile/database"

local Dir  = require "fs:fs/directory"
local File = require "fs:fs/file"
local Path = require "fs:fs/path"
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
   s:verb("initial load of " .. tostring(ref))
   local skein = Skein(ref, net.lume)
   -- cache result
   rawset(net, ref, skein)
   return skein
end
































































































function Lume.run(lume)
   -- determine if we need to start the loop
   local loop_alive = uv.loop_alive()
   local launcher = uv.new_idle()
   local launch_running = true
   launcher:start(function()
      lume:bundle()
      launcher:stop()
      launch_running = false
   end)

   if not loop_alive then
      s:chat "running loop"
      uv.run 'default'
   end

   loop_alive = uv.loop_alive()
   -- if there are remaining (hence broken) coroutines, run the skein again,
   -- to try and catch the error:
   local retrier = uv.new_idle()
   retrier :start(function()
      if launch_running or lume.transacting or lume.persisting then
         return
      end

      for _, skein in pairs(lume.ondeck) do
         s:verb("retry on %s", tostring(skein.source.file))
         local ok, err = xpcall(skein:transform(), debug.traceback)
         if not ok then
            s:warn(err)
         end
      end
      retrier:stop()
      s:verb("end run")
   end)
   if not loop_alive then
      uv.run 'default'
   end

   return lume
end









local function changer(lume)
   return function (watcher, fname)
      local full_name = tostring(lume.orb) .. "/" .. fname
      s:chat ("altered or new file %s", full_name)
      -- refresh git info
      lume:gitInfo()
      local skein = lume.net[File(full_name)]
      skein:transform()
      lume.has_file_change = true
      s:chat("processed %s", full_name)
   end
end

function Lume.serve(lume)
   s:chat("listening for file changes in orb/")
   s:chat("^C to exit")
   local loop_alive = uv.loop_alive()
   lume.server = Watcher { onchange = changer(lume),
                            onrename = changer(lume) }
   lume.server(tostring(lume.orb))
   if not loop_alive then
      uv.run 'default'
   end
   return lume
end














local create, resume, running, yield = assert(coroutine.create),
                                       assert(coroutine.resume),
                                       assert(coroutine.running),
                                       assert(coroutine.yield)

local function _loader(skein, lume, path)
   s:verb("begin read of %s", path)
   local co = running()
   lume.ondeck[co] = skein
   skein :load() :spin() :knit() :weave() :compile()
   s:verb("processed: %s", path)
   lume.count = lume.count - 1
   lume.ondeck[co] = nil
   lume.rack:insert(co)
   local stmts, ids, git_info, now = yield()
   skein:commit(stmts, ids, git_info, now)
   yield()
   skein:persist()
end

function Lume.bundle(lume)
   lume.count = 0
   -- #todo this is, ideally, temporary; we need it while things can still
   -- break.
   lume.ondeck = {}
   -- bail early if there's nothing on the shuttle
   if lume.shuttle:is_empty() then return lume end
   repeat
      local skein = lume.net[lume.shuttle:pop()]
      local path = tostring(skein.source.file)
      s:verb("loaded skein: %s", path)
      lume.count = lume.count + 1
      resume(create(_loader), skein, lume, path)
   until lume.shuttle:is_empty()
   s:verb("cleared shuttle")
   lume:persist()

   return lume
end













local commitBundle, commitSkein = assert(database.commitBundle),
                                  assert(database.commitSkein)

function Lume.persist(lume)
   local transactor, persistor = uv.new_idle(), uv.new_idle()
   lume.transacting, lume.persisting = true, true
   local check, report = 0, 1

   transactor:start(function()
      -- watch for next phase
      check = check + 1
      if check == report then
         s:verb("lume.count: %d", lume.count)
         report = report * 2
      end
      if check > 512 then
         s:warn("bailing. lume.count: %d", lume.count)
         lume.count = 0
      end
      if lume.count > 0 then return end
      -- report failed coroutines
      for _, skein in pairs(lume.ondeck) do
         s:verb("failed to process: %s", tostring(skein.source.file))
      end
      -- set up transaction
      local conn = lume.conn
      local stmts, ids, now = commitBundle(lume)
      local git_info = lume:gitInfo()
      -- cache db info for later commits
      lume.db = { stmts    = stmts,
                  ids      = ids,
                  git_info = git_info,
                  now      = now }
      -- make closures for transaction so we can reuse them
      lume.db.begin = function() conn:exec [[BEGIN TRANSACTION;]] end
      lume.db.commit = function() conn:exec [[COMMIT;]] end
      s:chat("writing artifacts to database")
      lume.db.begin()
      for co in pairs(lume.rack) do
         if coroutine.status(co) ~= 'dead' then
            local ok, err = resume(co, stmts, ids, git_info, now)
            if not ok then
               error ("coroutine broke during commit: " .. err)
               conn:exec "ROLLBACK;"
               transacting = false
               persistor:stop()
               transactor:stop()
            end
         end
      end
      -- commit transaction
      lume.db.commit()
      -- checkpoint
      -- use a pcall because we get a (harmless) error if the table is locked
      -- by another process:
      pcall(conn.pragma.wal_checkpoint, "0") -- 0 == SQLITE_CHECKPOINT_PASSIVE
      -- clean up db cache
      lume.db.ids.bundle_id = nil
      lume.db.now = nil
      -- end transactor, signal persistor to act
      lume.transacting = false
      transactor:stop()
   end)
   -- persist changed files to disk
   persistor:start(function()
      if lume.transacting then return end
      for co in pairs(lume.rack) do
         local ok, err = resume(co)
         if not ok then
            error ("coroutine broke during file write: " .. err)
            persistor:stop()
         end
      end
      -- GC the coroutines, now that we're done with them
      lume.rack:clear()
      lume.persisting = false
      persistor:stop()
   end)

   return lume
end











local sh = require "lash:lash"
local date = sh.command("date", "-u", '+"%Y-%m-%d %H:%M:%S"')

function Lume.now(lume)
   return tostring(date())
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
   if _Lumes[dir] then
      return _Lumes[dir]
   end
   local lume = setmetatable({}, Lume)
   lume.conn = db_conn and _Bridge.new_modules_db(db_conn)
                       or _Bridge.modules_conn
                       or error "no database"
   lume.no_write = no_write
   lume.shuttle = Deque()
   lume.rack = Set()
   lume.pedantic = _Bridge.args.pedantic and true or false
   lume.well_formed = _findSubdirs(lume, dir)
   if lume.well_formed then
      lume.deck = Deck(lume, lume.orb)
   else
      -- this will probably break currently, but the end goal of
      -- this architecture is to try and do something more sensible
      -- than that.
      s:warn("%s is not a well formed codex", uv.cwd())
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

