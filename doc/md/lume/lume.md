# Lume


The artifact across which skeins are variously worked is called the `lume`\.


## Premise

  Orb being a hypertextual medium, we must *resolve* references between
documents\.  Normal operation works on a project at a time, but this was
Proctrustean: sometimes too large for the job, and sometimes too small\.

The Lume is a general\-purpose document resolver and skein wrangler\.

It functions at the project level; that is, it's expected to work correctly
if opened in a directory with "codex normal form"\.

This means, in brief:

-  Has an `/orb` folder, which contains subdirectories with `.orb` files and
    no cycles\.

-  Has a =/src= folder, which contains, or will contain, sorcery files, which
    have the extension of the target language: `.lua` for most bridge projects,
    in principle, anything is supported\.

-  Has a `/doc/md` folder, which will contain markdown weaves of the source
    files\.

Aspirationally, it will handle any sort of project which has orb files to work
on, and will have a more refined mode for working on single files as well,
or single subdirectories of a project\.

We may build an "overwatch" mode, which assumes all subdirectories might be
codex\-normal, and sets up a lume for each, but this will live elsewhere\.


### Vocabulary

\#Todo

We refer to the project root as the `codex`, but we simply must break the
requirement that it have "codex normal form"\.  Bridge projects will continue
to follow the form, which remains useful, but we require ways to override it,
and ways to continue operation, in some circumstances, without the familiar
directories\.

The codex itself is a special sort of system directory, rather than a Lua
module\.  Pieces of the codex are attached to the lume itself\.

A `deck` is what we will call each meta\-directory within a Codex\.  Meta in the
sense that each source, knit, and weave directory, is *basically* a single
entity with different faces\.  We do have to decide under what circumstances
this correspondence can be broken, and how we inform the Lume that this is
happening, so that it doesn't delete artifacts that appear to have no further
basis in the source\.

Currently, `lume.deck` only represents the source files; the parallel
constructions of the Deck for knits and weaves are going to have to wait\.

A `manifest` is our specification document\.  Any codex exists in a profusion
of different versions from a variety of sources of truth, and if we mean a
specific one, we need to tell the Lume which one we mean\.  Manifests are
initially loaded from specific files, located in the base of the Deck which
they influence, but a Deck's manifest is an in\-memory data structure which may
be further modified by information contained in Docs\.

That is itself a bit bewildering but there's a simple remedy: each Codex,
Deck, and Doc, has a single associated Manifest, and if that Manifest has any
modifications relative to its parent, it is turned into an *instance* which
has the parent as a metatable\.  This is the cheaper and more eloquent way to
do it: the cleanest way is to make each and every Manifest an instance with
a metatable structure which leads back to the root\.  We'll decide later\.

There is no code working with manifests, or sample manifests, or anything of
the sort\.  One prerequisite is improving the Orb parser until it makes a
decent configuration language\.

A `skein` is a meta\-Doc in the way in which a Deck is a meta\-directory; it
handles all the permutations of a given document, and is responsible for
handling messages to do operations, and returning messages and closures which
manifest hyper\-linking, transclusion, and this sort of thing\.

Each `skein` has a reference to its Lume, and might end up carrying a
reference to its Deck as well\.  Skeins don't do much with Decks per se,
however, and we can derive it from the Skein's base path, so perhaps not\.

The big piece I'm missing is how to handle queuing of asynchronous operations,
such that the Lume can tell, during each pass through libuv, what operations
are ready to be taken to the next level\.  Once I've really grasped that, the
rest is, not straightforward, but surely tractable\.


#### imports

```lua
local uv = require "luv"
local sql = assert(sql)

local s = require "status:status" ()
s.verbose = false

local git_info = require "orb:util/gitinfo"
local Skein = require "orb:skein/skein"
local Deck = require "orb:lume/deck"
local Watcher = require "orb:lume/watcher"
-- #todo replace this with /database after new toolchain lands
local database = require "orb:compile/newdatabase"

local Dir  = require "fs:fs/directory"
local File = require "fs:fs/file"
local Path = require "fs:fs/path"
local Deque = require "deque:deque"
local Set = require "set:set"
```


## Lume

```lua
local Lume = {}
Lume.__index = Lume
```

I expect we'll want Lumes to be unique by directory, so we'll return already\-
existing Lumes:

```lua
local _Lumes = setmetatable({}, { __mode = "kv" })
```


## Slots

  Because of the centrality of the codex to operation of a Lume, its
references are "exploded" in the Lume\.  That is, the `orb`, `src` and `doc`
directories are instance fields on the Lume itself\.


### Fields


#### Lume\.net

The `net` is our reference resolver\.  Index a value on the Net, and it returns
a Skein\.

Thanks to the thoughtful design of Lua, we can write [purple functions](),
which will block if called outside an event loop and/or the main coroutine,
seamlessly becoming asynchronous otherwise\.

\[†\]: http://journal\.stuffwithstuff\.com/2015/02/01/what\-color\-is\-your\-function/

So this:

```lua-example
local skein = lume.net["http://example.com/doc.orb"]
```

Will either block to complete the network request, or, if it's in a coroutine,
will immediately yield and suspend, after passing a callback which will resume
with the document\.

In the process, `net` is `rawset` with the value, so the next lookup is a
simple index on the slot\.  With a twist: the key is canonicalized before
it's keyed in, so `"path/to/file.orb"` and `Path "path/to/file.orb"` will
always yield the same thing\.

This cache may always be invalidated by setting the key to `nil`\.

```lua
local Net = {}
```

```lua
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
```


#### Lume\.shuttle

A [deque](@br/deque:deque) on which files are placed, to be turned into
Skeins by the net and wrapped in a coroutine for asynchronous processing\.


#### Lume\.ondeck

A table with coroutines as keys and the skein as value\.

Key\-value pairs on the deck are undergoing transformation\.  If this succeeds
without crashing, they are removed from `ondeck`\.

That's what is supposed to happen\. But if it doesn't, we can go through
`ondeck` and figure out what to do about it\.


#### Lume\.rack

The rack is a [Set](@br/set:set) of the coroutines, to be iterated twice,
to commit modules to the database and persist changed artifacts into files,
after which it is cleared\.


#### Lume\.db

A map of database\-specific values\.

- db:




  - ids:   The project, bundle, and version ids\.

  - git\_info:  Repository data\.

  - now:  A timestamp\.

  - begin:  A closure which begins a transaction\.

  - end:  A closure which ends a transaction\.


### Scalar Fields

- lume:

  - count:  An integer, incremented every time a coroutine is created, and
      decremented after transformation is complete\.

  - conn:  The database connection\.

  - no\_write:  If truthy, generated files aren't written\.

  - project:  The name of the project\.

  - orb:  The source directory\.

  - src:  The knit directory\.

  - doc:  The weave directory\.

  - docMd:  The Markdown weave directory\.

      There may be more directories like this; we currently check for
      docDot and docSvg, but don't do anything else with those fields\.


##### Next

We need some sort of work queue for completions\. I think\! The coro\-wrapped
async callback approach might just be sufficient\.

Local references are easy, we just wait until the codex has been processed\.
For remote references, we can probably just set up an async call which lands
it\.


## Methods

Lume is mostly implemented in the method\-chaining style, with some inner
methods which return data instead\.

The main entry point is `lume:run()`\.


### Lume:run\(watch\)

Runs a bundle, and if `watch` is set to `true`, launch the watcher and run a
second bundle when the watcher quits\.

```lua
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
   -- if there are remaining (hence broken) coroutines, run the skein again,
   -- to try and catch the error:
   for _, skein in pairs(lume.ondeck) do
      s:verb("retry on %s", tostring(skein.source.file))
      local ok, err = xpcall(skein:transform(), debug.traceback)
      if not ok then
         s:warn(err)
      end
   end
   s:verb("end run")
   return lume
end
```


### Lume:serve\(\)

Sets up a file watcher over the `orb/` directory, running a full
transformation on each changed file\.  `^C` to quit\.

```lua
local function changer(lume)
   return function (watcher, fname)
      local full_name = tostring(lume.orb) .. "/" .. fname
      print ("changed to " .. full_name)
      local skein = lume.net[File(full_name)]
      skein:transform()
      print ("processed " .. full_name)
   end
end

local function renamer(lume)
   local function onrename(watcher, fname)
      print ("renamed " .. fname)
   end

   return onrename
end

function Lume.serve(lume)
   s:chat("listening for file changes in orb/")
   s:chat("^C to exit")
   local on_loop = uv.loop_alive()
   lume.server = Watcher { onchange = changer(lume),
                            onrename = renamer(lume) }
   lume.server(tostring(lume.orb))
   if not on_loop then
      uv.run 'default'
   end
   return lume
end
```


### Lume:bundle\(\)

`lume:bundle()` takes the contents of the shuttle, and runs the full
transformation inside a coroutine for each Skein\.

We need to coalesce after all transformations complete, so we can put all the
commits into a single transaction, before running all file writes in a final
coroutine\.  So the coroutine places itself in the `.rack`, a Set, and `yield`s
so that the database operations can be wrapped in a single transaction\.

```lua
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
```


### Lume:persist\(\)

Sets up a UV idler which checks `.count` until it's 0, then runs the
coroutines inside a transaction, and finally runs them again to write changed
files\.

Currently there is a check variable that runs the transactor 512 times and
then forces the issue\.

```lua
local commitBundle, commitSkein = assert(database.commitBundle),
                                  assert(database.commitSkein)

function Lume.persist(lume)
   local transactor, persistor = uv.new_idle(), uv.new_idle()
   local transacting = true
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
      transacting = false
      transactor:stop()
   end)
   -- persist changed files to disk
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

   return lume
end
```


### Lume:now\(\)

This is a convenience function which we end up needing inside the skein and
database modules\.

Returns a timestamp in the correct formula for the modules database\.

```lua
local sh = require "lash:lash"
local date = sh.command("date", "-u", '+"%Y-%m-%d %H:%M:%S"')

function Lume.now(lume)
   return tostring(date())
end
```


### Lume:gitInfo\(\)

The git info for a lume can change during runtime, this method will refresh
it\.

\#todo

```lua
function Lume.gitInfo(lume)
   lume.git_info = git_info(tostring(lume.root))
   return lume.git_info
end
```


### Lume:projectInfo\(\)

Returns a table containing info about the project useful for querying and
updating the database\.

Uses `git_info` and presumes the information is fresh\.

```lua
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
```


### Lume:versionInfo\(\)

Returns information about the version, in a database\_friendly format\.

Currently just searches the `_Bridge.args`, but we want to provide a
consistent interface for allowing in\-document version pinning\.

```lua
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
```


## Lume\(dir, db\_conn, no\_write\)

Creates a Lume, rooted in the provided Directory, which may be a string or a
Dir\.

This generates the Deck, and puts all the associated Files on the shuttle for
later processing\.

The additional parameters are for mocking: `db_conn` will open another
database, or in\-memory for `""`, and `no_write` will disable persisting
changed files\.


##### An aside regarding memory

  The algorithm we're using pulls everything into memory, and keeps all
generated artifacts there as well\.  This is profligate, by the standards I
learned to program under, but well within the realistic limits of today's
hardware and actual project complexity\.

I'll do what I can, in designing the API, to make this an artifact of the
algorithm, rather than a requirement of it\.  Should `bridge` survive into
adulthood, someone, somewhere, will push into larger and larger repositories,
and at some point we may need to fall back on a more memory\-constrained
approach\.

Might never happen, my laptop can hold a single\-layer Blu\-Ray completely in
memory\.  On the other hand, LuaJIT currently has limited memory available;
there's been work to remove that limit but only in RaptorJIT, which in turn
supports only Linux\.


####  \_findSubdirs\(lume, dir\)

  Called by the constructor to find the directories for knitted and woven
artifacts, should they happen to exist\.

This function annotates the lume, which means we shouldn't return it\.  Instead,
we return a boolean indicating that the directory is "well formed"\.

We currently ignore this, but that is likely to change\.

```lua
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
```

```lua
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
```

```lua
return new
```
