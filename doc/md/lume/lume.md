# Lume


The old toolchain had a codex.


This one is going to have a Lume.  Which sounds like loom, and looks like
light, and that will do.


## Premise

  Orb being a hypertextual medium, we must _resolve_ references between
documents.  Normal operation works on a project at a time, but this was
Proctrustean: sometimes too large for the job, and sometimes too small.


The Lume, which will undergo several metamorphoses on its path to the final
boss form, is a general-purpose document resolver and skein wrangler.  We give
it essentially a URL, it gives us back a promise to provide that data, in the
form of a coroutinized callback.


That's one of the tricky parts.  Bridge programs run on an event loop, and we
have a threadpool for doing filesystem I/O, so this does come with notional
speed benefits, even for loading files from store.


But for retrieving remote work, we would absolutely crawl if we had to wait
for each network request to resolve before launching another one.  There's no
alternative but to finally internalise the paradigm which luvit uses for doing
async work in a single-threaded callback + coroutine framework.


I'll probably end up writing blocking versions of most of the basic
operations, because it's simpler, and because it's our only hope of having
colorless functions: ones which don't have to know, at call-time, that they
must be inside a coroutine and handled accordingly.


### Vocabulary

#Todo URLify all the definitions in this section
sense that each source, knit, and weave directory, is _basically_ a single
entity with different faces.  We do have to decide under what circumstances
this correspondence can be broken, and how we inform the Lume that this is
happening, so that it doesn't delete artifacts that appear to have no further
basis in the source.


A ``manifest`` is our specification document.  Any codex exists in a profusion
of different versions from a variety of sources of truth, and if we mean a
specific one, we need to tell the Lume which one we mean.  Manifests are
initially loaded from specific files, located in the base of the Deck which
they influence, but a Deck's manifest is an in-memory data structure which may
be further modified by information contained in Docs.


That is itself a bit bewildering but there's a simple remedy: each Codex,
Deck, and Doc, has a single associated Manifest, and if that Manifest has any
modifications relative to its parent, it is turned into an _instance_ which
has the parent as a metatable.  This is the cheaper and more eloquent way to
do it: the cleanest way is to make each and every Manifest an instance with
a metatable structure which leads back to the root.  We'll decide later.


A ``skein`` is a meta-Doc in the way in which a Deck is a meta-directory; it
handles all the permutations of a given document, and is responsible for
handling messages to do operations, and returning messages and closures which
manifest hyper-linking, transclusion, and this sort of thing.


Each ``skein`` has a reference to its Lume, and might end up carrying a
reference to its Deck as well.  Skeins don't do much with Decks per se,
however, and we can derive it from the Skein's base path, so perhaps not.


The big piece I'm missing is how to handle queuing of asynchronous operations,
such that the Lume can tell, during each pass through libuv, what operations
are ready to be taken to the next level.  Once I've really grasped that, the
rest is, not straightforward, but surely tractable.


#### Fields

  Because of the centrality of the Codex to operation of a Lume, its
references are "exploded" in the Lume.  That is, the ``orb``, ``src`` and ``doc``
directories are instance fields on the Lume itself, not (primarily) on the
``codex`` object.


It's awkward to have to imperatively command the Lume to retrieve some data,
so indexing the net will return a closure which we can call repeatedly until
it has something to give us.  I _think_ that's how this should work; this is
my first time writing a beast of this nature, and I should expect to do a
shoddy job of it the first time around.


Actually, I'm thinking that we create a _coroutine_ on the spot, and when the
inner callback returns a value, this is placed on a work queue to be further
processed by the Lume idler.  Or something like that; I'm going to need to do
some flowcharting to really get this thing right.


There's some small advantage to making this perfectly consistent, but it's
less efficient, so I believe we'll just have this index return a Skein if it
happens to already have one, and the promise of a Skein if it does not.


Using an ``__index`` function lets us be smart about not caring if this index is
a string, a Path, File, a Skein (which sounds like a no-op but bear with me),
or something exotic we aren't using yet, like an URL node.  Canonicalizing all
these possibilities is often, but not always, straightforward, and in any
case we benefit from having a single place where it happens.


Lumes also have to handle inter-skein communication.  Our first case, and the
one we can build the rest on, is a transclusion: here the Lume encounters an
operation within a Skein which cannot be completed without information in
another Doc, and it doesn't want to know at the time whether or not that
information is already present.  It may buy us time, at the expense of
complexity, to resolve the reference on the spot if we're already able, but
this is an optimization.


What the knitter (for the sake of argument) returns is a closure, along with
the information it has on hand as to how to provide the additional parameters
needed to call the closure.  So if we've encountered a #transclude block,
we'll get back a closure which inserts the transcluded text into the Scroll,
at the current offset, and the @name of the transclude block, used to
retrieve the associated Doc and ``:select`` the necessary Twig.


There's no reason for this to ever live on the Skein, when we can retrieve the
Lume from the Skein and place it there immediately.


### Stop. Hammock Time.

  So there are a number of unanswered questions here, and I do need to obtain
some clarity on them before I can start to sketch out the implementation.


A Lume is opened any time we have a Doc, with the minimum-viable amount of
support infrastructure surrounding it.


This sort of needs to be built inside out.  ``bridge`` has to be able to handle
an invocation such as ``br example.orb``, which should knit ``example.orb`` and
execute it.  This will create a Lume, yes, and it shouldn't have to look at
anything that isn't directly implicated in loading the sorcery.


Expanding outward, the paradigm case is actually ``br orb serve`` typed from the
root directory of a Codex.  This should case the entire Codex into a Lume,
generate a bundle and all artifacts, then set up a file watcher which conducts
changes.  At some point this develops the ability to talk to ``helm``, an editor,
and other such constructions.


The whole goal of bridge is to tighten the OODA loop between editing text and
seeing the changes to the system, after all.


A fully-operational Lume will need to be retrieving changes from a remote
code repository and walking the user through an interaction about whether to
update Manifests to point to new revisions, should allow changes to a Doc's
source through inline editing of a woven HTML view, wants to intercept error
messages from runtimes and sent a message to text editors to display the
offending piece of (orb!) source code, and so on, and so forth.


The challenge is to build the Lume so that it can be repeatedly extended until
it reaches this final boss form.  The Lume isn't a dumpster, but it does have
a complex remit, and is called upon in the moment to be both more and less
than the Codex which it replaces.


The main hangup is two related things: how to handle an asynchronous operation,
and where/how to store things which are in transit.


Let me break this down.  Lume has three kinds of data: something which can
resolve a variety of messages into the associated data/Skein, something which
marshals in-process tasks while they are in flight, and various slots which
hold useful data: two examples of this are the Directory for the root Codex,
and a table with ``git`` informaiton for it.


I'm starting to think the process management _ queue _ event worker thingie is
its own module, and that the Lume is just the web of resolutions and the
directory for all cross-skein data transfer and 'global state'.


#### First Steps

  The initial goal is to reach feature parity with the existing Codex
implementation.


The constructor is relatively straightforward, main difference this time is
that we don't want to silently break later if the root directory isn't in
codex normal form.


The workflow for the new runner is approximately this:


-  Case the Orb directory and generate Skeins for each ``.orb`` file we find.


-  Launch a coroutine, per file, which triggers the 'callback style' of
   opening, while counting the number of operations we have in flight.


   Each of these coroutines, when it resumes, will decrement the counter.


  -  After queuing the ``sk:load()`` into the threadpool, set up an idler which
     simply checks to see if the count is back at zero, and exits if it isn't.


     When the documents are all loaded, iterate them and run them through the
     spin/knit/weave/compile/cycle.


     I think this can all be written into the initial coroutine, which is
     simply resumed.  All of these operations are blocking, there's no way to
     make them faster without experimenting with threads, and I doubt (no way
     to know without profiling) that any CPU operations will be a meaningful
     target for optimization.


  -  The last step is to use the same callback pattern to write out any new
     files.  The database persistence needs to be a transaction anyway, and I
     don't think we'll be helping ourselves by trying to put it into libuv,
     we'll just let SQLite take care of it.  But we can absolutely write
     files without having to wait around while the system does what it does.


This will handle everything we currently do with Orb, and give me a framework
for reasoning about how to do the more complex tasks ahead.


##### Next

We need some sort of work queue for completions. I think! The coro-wrapped
async callback approach might just be sufficient.


Local references are easy, we just wait until the codex has been processed.
For remote references, we can probably just set up an async call which lands
it.


## Lume


#### imports

```lua
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
```
```lua
local Lume = {}
Lume.__index = Lume
```

Doing this right requires resolving symlinks, making relative file paths
absolute, and probably the best option, retrieving the directory inode.  But
we might just do it wrong at first.

```lua
local _Lumes = setmetatable({}, { __mode = "kv" })
```
### Lume.net

The ``net`` is our reference resolver.  Index a value on the Net, and it returns
a Skein.


I _think_ the way this works, is, if called on a coroutine and in an event
loop, the index function yields and then resumes into a callback.  If not,
it blocks to complete the request.


So this:

```lua-example
local skein = lume.net["http://example.com/doc.orb"]
```

Will either block to complete the network request, or, if it's in a coroutine,
will immediately yield and suspend, after passing a callback which will resume
with the document.


It the process, ``net`` is ``rawset`` with the value, so the next lookup is a
simple index on the slot.  With a twist: the key is canonicalized before
it's keyed in, so ``"path/to/file.orb"`` and ``Path "path/to/file.orb"`` will
always yield the same thing.

```lua
local Net = {}
```
```lua
function Net.__index(net, ref)
   -- resolve reference
   -- make Skein
   -- net carries a reference to parent lume:
   local skein = Skein(ref, net.lume)
   return skein
end
```
## Methods


### Lume:bundle()

``:bundle()`` takes the contents of the shuttle, and runs


We need to detect or flag asynchrony: ``:shuttle`` will block if not on an
event loop, while if it is on an event loop, it will launch each network
operation (file access counts!) inside its own coroutine.


We need to coalesce after all transformations complete, so we can put all the
commits into a single transaction, before running all file writes in a final
coroutine.  So the coroutine places itself in the ``.rack``, a Set, and ``yield``s
so that the database operations can be wrapped in a single transaction.

```lua
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
```
### Lume:persist()

Sets up a UV idler which checks ``.count`` until it's 0, then runs the
coroutines inside a transaction, and finally runs them again to write changed
files.

```lua
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
```
### Lume:run(watch)

Runs a bundle, and if ``watch`` is set to true, launch the watcher and run a
second bundle when the watcher quits.

```lua
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
```
### Lume(dir)

Creates a Lume, rooted in the provided Directory, which may be a string or a
Dir.


This generates the Deck, and puts all the associated Files on the shuttle for
later processing.


##### An aside regarding memory

  I grew up poor, and that malnourished inner child cringes a bit at an
architecture which dictates that all sources should be held in memory
simultaneously.


I'll do what I can, in designing the API, to make this an artifact of the
algorithm, rather than a requirement of it.  Should ``bridge`` survive into
adulthood, someone, somewhere, will push into larger and larger repositories,
and at some point we may need to fall back on a more memory-constrained
approach.


This would be a nice problem to have!


#### _findSubdirs(lume, dir)

  Called by the constructor to find the directories for knitted and woven
artifacts, should they happen to exist.


This function annotates the lume, which means we shouldn't return it.  Instead,
we return a boolean indicating that the directory is "well formed".


We currently ignore this, but that is likely to change.

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
                       or _Bridge.modules_conn
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
```
```lua
return new
```
