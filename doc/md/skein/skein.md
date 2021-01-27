# Skein


  A skein is an object for holding a Doc, with all its derivative works\.

The first toolchain was a bootstrap, which was accomplished by the simple
expedient of perfect uniformity\.  Every file in the `orb` directory of a
project was presumed to have some Lua in it, and there is a one\-to\-one
correspondence between `orb` on the one hand, and `src` on the other, same
for the weave\.  Every line of Lua is found in the same place as it is in the
Orb file, and so on\.

This was a useful paradigm, but now we have the new parser, and we need to
walk back some of those design choices\.  The Orb files must remain the source
of truth, but everything else changes: Orb files may affect each other, mutate
themselves and each other, both in ways which are written to disk and ways
which are not, and may generate multiple artifacts of the same sort; or one
Orb document may be a source of code in a knit or weave derived ultimately
from another\.

We took this general\-to\-specific approach to the extreme where compilation in
the old method is all\-or\-nothing\.  We briefly had the ability to knit \(but not
weave\) a single document, but surrendered it\.

Now we'll build from a single file outward\.  We keep the semi\-literate style
for now, but make a single skein capable of everything that needs: parsing,
formatting, spinning, knitting, weaving, and writing all changes to both the
filesystem and the module database\.

Then we'll rebuild the Codex, with as few of the old assumptions as possible\.
In particular, we'll leave out Decks at first, and add them back if they
actually prove useful, which they might\.  That gets us to feature\-parity with
the old compiler, which we may then remove\.

With careful engineering, this will put us in a position for Docs to be
dependent on other Docs, which we can resolve with inter\-skein communication\.


## Instance fields

These are successively created and manipulated over the course of actions
taken on the skein\.


- lume:  A skein carrys a reference to its enclosing lume, which is
    necessary to enable more complex kinds of inter\-document activity\.

    \#Todo this needs to be more flexible and general\.  The Lume, as
    written, requires a codex\-normal directory structure, has completely
    walked it, has hooks into the `bridge.modules` database, and so on\.
    This needs to be appropriately generalized\.


- source:  The artifacts of the source file:

  - path:  The Path of the original document\.

  - text:  String representing the contents of the document file\.

  - doc:  The Doc node corresponding to the parsed source doc\.

  - modified:  \#NYI, a flag to mark if the source document itself has been
      modified and needs to be written to disk\.


- knitted:  The artifacts produced by knitting the source\.  Currently, this is
    a key\-value map, where the key is the `code_type` field and the
    value is a Scroll\.


- woven:  The artifacts produced by weaving the source\.

  - md:  The Markdown weave of the source document\.

  - \#Todo:

    - html:  An HTML weave of the source document\.




    - pdf:  Just kidding\! Unless\.\.\.

    - latex:  Same, basically

    - pandoc:  I mean, maybe?


- bytecode:  Perhaps a misnomer; this is best defined as artifacts produced by
    further compilation of the knit, suitable for writing to the
    modules database or otherwise using in executable form\.

    For the core bridge modules, this is LuaJIT bytecode, but in
    other cases it could be object code, or a \.jar file, minified JS,
    and the like\.


- completions:  \#NYI\.  These are closures with the necessary information to
    provide the parameters needed to complete them\. An example
    would be a transclusion or macroexpansion which draws from a
    namespace that isn't in the source file\.

    This is the only approach which generalizes across projects,
    and across compilation scenarios:  We want, at the limit, to
    be able to process a single source file, while opening and
    processing only those additional files needed to complete its
    cycle\.


#### imports

```lua
local s = require "status:status" ()
local a = require "anterm:anterm"
s.chatty = true
s.angry = false
```

```lua
local Doc      = require "orb:orb/doc"
local knitter  = require "orb:knit/knit" ()
local compiler = require "orb:compile/compiler"
local database = require "orb:compile/database"

local File   = require "fs:fs/file"
local Path   = require "fs:fs/path"
local Scroll = require "scroll:scroll"
```

```lua
local Skein = {}
Skein.__index = Skein
```


## Methods

  Skeins are in the chaining style: all methods return the skein at the
bottom\. If additional return values become necessary, they may be supplied
after\.

Generally, the state created and manipulated by method calls is attached to
the skein itself\.

Methods are listed in the order in which they are expected to be executed\.
Some \(knit and weave, notably\) will probably function correctly in another
order, while others will not; certainly we can't process anything without
loading it in some fashion\.

We may offer an affordance for working outside the filesystem, but we surely
don't need it now\.


### Skein:load\(\)

This loads the Path data into the `skein.source.text` field\.

If called inside a coroutine and uv even loop, this uses a callback, allowing
us to employ the threadpool for parallelizing the syscall and read penalty\.

```lua
function Skein.load(skein)
   local ok, text = pcall(skein.source.file.read, skein.source.file)
   if ok then
      skein.source.text = text
   else
      s:complain("fail on load %s: %s", tostring(skein.source.file), text)
   end
   return skein
end
```


### Skein:filter\(\)

Optional step which mostly replaces tabs in the non\-codeblock portions of the
text\.  Any changes will flip the `modified` flag\.

Currently a no\-op\.


```lua
function Skein.filter(skein)
   return skein
end
```


### Skein:spin\(\)

This spins the textual source into a parsed document\.

It will eventually perform some amount of post\-processing as well, such as
in\-place expansion of notebook\-style live documents\.

```lua
function Skein.spin(skein)
    local ok, doc = pcall(Doc, skein.source.text)
    if not ok then
       s:complain("couldn't make doc: %s, %s", doc, tostring(skein.source.file))
    end
    skein.source.doc = doc
   return skein
end
```


### Skein:format\(\)

\#NYI,

```lua
function Skein.format(skein)
   return skein
end
```


### Skein:knit\(\)

Produces sorcery, derived 'source code' in the more usual sense\.

Referred to as a 'tangle' in the traditional literate coding style\.

```lua
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
```


### Skein:weave\(\)

This produces derived human\-readable documents from the source\.

We currently produce only Markdown, and as such, there isn't a Weaver instance,
instead, we simply do everything inside the method\.

The roadmap will favor HTML as the first\-class output format\.

This will probably take parameters to specify subcategories of possible
documents; by default, it will produce all the rendered formats it is capable
of producing\.

Eventually, `weaver:weave(skein)` should be the entire method for
`Skein:weave()`, and Scroll will be a dependency of that module, not of Skein
itself\.

```lua
function Skein.weave(skein)
   if not skein.woven then
      skein.woven = {}
   end
   local woven = skein.woven
   woven.md = {}
   local ok, err = pcall(function()
      local scroll = Scroll()
      skein.source.doc:toMarkdown(scroll)
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
```


#### Skein:compile\(\)

Takes a knitted Skein and compiles the Scroll if it knows how\.

"Compile" in this case means: check for syntax errors, and render into a form
suitable for persistance into the database, and/or further processing\.

It's unclear what this stage will look like for, in particular, C files; it's
perfectly clear what it looks like for our default, semi\-literate golden path
for Lua artifacts, so we'll start there\.

```lua
function Skein.compile(skein)
   compiler:compile(skein)
   return skein
end
```

### Skein:commit\(stmts\)

This commits modules to the database, provided with a collection of prepared
statements sufficient to complete the operation\.

```lua
local commitSkein = assert(database.commitSkein)

function Skein.commit(skein, stmts, ids, git_info, now)
   assert(stmts)
   assert(ids)
   assert(git_info)
   assert(now)
   commitSkein(skein, stmts, ids, git_info, now)
   return skein
end
```


### Skein:transact\(stmts\)

This calls `:commit` inside a transaction, for use in file\-watcher mode and
any other context where the commit itself is a full transaction\.

Necessary because the module and code are written out separately\.

`now` is an optional field, which is provided by the database if left out\.

```lua
function Skein.transact(skein, stmts, ids, git_info, now)
   assert(stmts)
   assert(ids)
   assert(git_info)
   skein.lume.db.begin()
   commitSkein(skein, stmts, ids, git_info, now)
   skein.lume.db.commit()
   return skein
end
```


### Skein:persist\(\)

Writes derived documents out to the appropriate areas of the filesystem\.


#### writeOnChange\(scroll, dont\_write\)

Compares the new file with the old one\. If there's a change, prints the name
of the file, and writes it out\.

```lua
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
```

```lua
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
```


### Skein:transform\(\)

Does the whole dance\.

We need some better way to get all the database machinery decorated onto the
Skein, because currently we overuse parameters for that\.

```lua
function Skein.transform(skein)
   local db = skein.lume.db
   skein
     : load()
     : spin()
     : knit()
     : weave()
     : compile()
     : transact(db.stmts, db.ids, db.git_info, skein.lume:now())
     : persist()
   return skein
end
```


### new\(path, lume\)

Takes a path to the source document, which may be either a Path or a bare
string\.

Also receives the handle of the enclosing lume, which we aren't using yet,
and might not need\.

```lua
local function new(path, lume)
   local skein = setmetatable({}, Skein)
   skein.source = {}
   if not path then
      error "Skein must be constructed with a path"
   end
   -- handles: string, Path, or File objects
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
```


```lua
return new
```
