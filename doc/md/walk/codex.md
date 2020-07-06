# Codex

A Codex is currently a directory in our Orb\-style format\.

We're trying to work our way into a proper database\.


## Instance Fields

- docs:  Array keyed by full path name of file, and the spun\-up Doc as
    the value\.

- files:  Array keyed by full path name of file, and a string of the read file
    as the value\. I think\. \#todo check

- srcs:  Array keyed by Path of file, and a string of the knit
    source files\. This might also be a File; God what a mess\.

- bytecodes: Array indexted by Path of file, value is a string that is a dump
    of the bytecode of the compiled sorcery\.






- orb:  The deck containing the source Orb files\.

- src:  The deck containing the knit src files\.


```lua
local pl_mini = require "orb:util/plmini"
local write = pl_mini.file.write
```

```lua
local s = require "status:status" ()
s.verbose = false

local Dir  = require "fs:fs/directory"
local File = require "fs:fs/file"
local Path = require "fs:fs/path"
local Deck = require "orb:walk/deck"
local ops  = require "orb:walk/ops"
local git_info = require "orb:util/gitinfo"

local knitter = require "orb:knit/knitter"

local Watcher = require "helm:helm/watcher"
```


```lua
local Codex = {}
Codex.__index = Codex
local __Codices = {} -- One codex per directory
```


## spin

The spin step is passed through to the Orb deck\.

This needs to generalize on a per\-file basis\.

Currently spinning just loads files into the Deck\(s\)\.

```lua
function Codex.spin(codex)
   codex.orb:spin()
end
```


## serve

```lua
local function changer(codex)
   local function onchange(watcher, fname)
      local full_name = tostring(codex.orb) .. "/" .. fname
      print ("changed " .. full_name)
      if codex.docs[full_name] and full_name:sub(-4) == ".orb" then
         local doc = Doc(codex.files[full_name]:read())
         local knit_doc = knitter:knit(doc)
         local knit_name = tostring(codex.src) .. "/"
                           .. fname : sub(1, -5) .. ".lua"
         local written = write(knit_name, tostring(knit_doc))
         print("knit_doc is type " .. type   (knit_doc))
      else
         print("false")
      end
   end

   return onchange
end


local function renamer(codex)
   local function onrename(watcher, fname)
      print ("renamed " .. fname)
   end

   return onrename
end

function Codex.serve(codex)
   codex.server = Watcher { onchange = changer(codex),
                            onrename = renamer(codex) }
   codex.server(tostring(codex.orb))
end
```


### Codex:gitInfo\(\)

The git info for a codex can change during runtime, this method will refresh
it\.

\#todo

```lua
function Codex.gitInfo(codex)
   codex.git_info = git_info(tostring(codex.root))
   return codex.git_info
end
```


### Codex:projectInfo\(\)

Returns a table containing info about the project useful for querying and
updating the database\.

Uses `git_info` and presumes the information is fresh\.

```lua
function Codex.projectInfo(codex)
   local proj = {}
   proj.name = _Bridge.args.project or codex.project
   if codex.git_info.is_repo then
      proj.repo_type = "git"
      proj.repo = codex.git_info.url
      proj.home = codex.home or ""
      proj.website = codex.website or ""
      local alts = {}
      for _, repo in ipairs(codex.git_info.remotes) do
         alts[#alts + 1] = repo[2] ~= proj.repo and repo[2] or nil
      end
      proj.repo_alternates = table.concat(alts, "\n")
   end
   return proj
end
```


### Codex:versionInfo\(\)

Returns information about the version, in a database\_friendly format\.

Currently just searches the `_Bridge.args`, but we want to provide a
consistent interface for allowing in\-document version pinning\.

```lua
function Codex.versionInfo(codex)
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


### buildCodex

Puts together a codex for a given project\.

- \#Todo:

  -  The names for the Dirs are all off\.  For one thing, we use that
      convention for methods, it should be orb\_dir\.  Worse, we name them after
      the conventional directory name, when clarity would dictate that we call
      them `orb_dir`, `knit_dir`, and `weave_dir`\.

```lua
local function buildCodex(dir, codex)
   local isCo = false
   local orbDir, srcDir, libDir = nil, nil, nil
   local docDir, docMdDir, docDotDir, docSvgDir = nil, nil, nil, nil
   codex.root = dir
   local subdirs = dir:getsubdirs()

   for i, sub in ipairs(subdirs) do
      local name = sub:basename()
      if name == "orb" then
         s:verb("orb: " .. tostring(sub))
         orbDir = sub
         codex.orb = sub
         -- dumb hack because I mutated this parameter >.<
         codex.orb_base = sub
      elseif name == "src" then
         s:verb("src: " .. tostring(sub))
         srcDir = Dir(sub)
         codex.src = sub
      elseif name == "doc" then
         s:verb("doc: " .. tostring(sub))
         docDir = sub
         codex.doc = sub
         local subsubdirs = docDir:getsubdirs()
         for j, subsub in ipairs(subsubdirs) do
            local subname = subsub:basename()
            if subname == "md" then
               s:verb("doc/md: " .. tostring(subsub))
               docMdDir = subsub
               codex.docMd = subsub
            elseif subname == "dot" then
               s:verb("doc/dot: " .. tostring(subsub))
               docDotDir = subsub
               codex.docDot = subsub
            elseif subname == "svg" then
               s:verb("doc/svg: " .. tostring(subsub))
               docSvgDir = subsub
               codex.docSvg = subsub
            end
         end
      end
   end

   if orbDir and srcDir and docDir then
      codex.codex = true
   end
   return codex
end
```


### Codex\(dir\)

Makes a codex given a directory, in string or Path form\.

```lua
local function new(dir)
   if type(dir) == "string" then
      dir = Dir(dir)
   end
   if __Codices[dir] then
      return __Codices[dir]
   end
   local codex = setmetatable({}, Codex)
   codex = buildCodex(dir, codex)
   codex.project = dir.path[#dir.path] -- hmmm?
   if codex.orb then
      codex.orb = Deck(codex, codex.orb)
   end
   codex.git_info = git_info(tostring(dir))
   codex.docs  = {}
   codex.files = {}
   codex.srcs  = {}
   codex.docMds = {}
   codex.docSvgs = {}
   codex.docDots = {}
   -- codex.docHTMLs = {} #todo

   codex.bytecodes = {}
   return codex
end
```


```lua
Codex.idEst = new
return new
```
