# Bundle


  We need a way to distribute versioned orb modules, because copying the
master blob of ``bridge.modules`` isn't going to cut it, except as a bootstrap.


I'm about to start adding the ability to make actual versions as part of the
``orb`` compiling process; as part of that, we need to make plain-text Lua
tables, which represent a complete collection of a given project at a given
version.


This is for the most part straightforward; the exception is the bytecode
itself.  Lua is happy to represent this as a "string", which is just a byte
array, while we want a utf-8 encoded representation of the bytecode, such that
we can use ``loadstring`` to retrieve the raw string and write it to the
database.


This being a broadly useful feature, I intend to add it as a method to the
``codepoints`` metatable, which is currently in ``core``, but will be moved to its
own module.


The ``bundle`` module will handle two related tasks: preparing a bundle, and
importing a bundle.  Fetching bundles from remote servers, and serving
bundles, are refinements to add once we have ``portal`` and related server
affordances.


### Tasks

- [ ]  Add versions


  - [ ]  Modify SQL in ``loader`` to allow for additional values to be passed in
         to a compile cycle: notably, the version string.


         While I'm at it, ``loader`` is a terrible name for this module, come up
         with a better one.


  - [2/3]  Add calls to query the system to get relevant information, such as
           the branch name, the remote repository or repositories, latest
           commit hash for the branch, and so on.


  - [ ]  Add arguments to ``br`` for specifying a versioned edition of a
         compilation.


  - [ ]  Write ``use``, to replace ``require`` and allow for the retrieval of
         versioned modules.


- [ ]  Prepare bundle


  - [X]  Modify ``codepoints`` to provide a method which produces a valid Lua
         string which is utf-8 safe and properly escapes necessary tokens.


         We're going to go ahead and escape anything which can be escaped,
         even though e.g. bare \t and \n pose no problem for utf-8 validation,
         so we can use the short-form for strings.


         Update: It turns out that JSON, incredibly, does not allow escapes of
         the form ``\xff``, only ``\u????``, which Lua does not support.


         Hmm.  I **think** the thing to do here is Base64 encode the Lua string
         if and when it's in transport as JSON, rather than go whole-hog and
         Base64 encode it at rest.  The important part is that it be valid
         utf-8, since it's easy to imagine scenarios where tooling will break
         or corrupt the data if it isn't.


         This might be as simple as ``string.format("%q", bytecode)``; although
         when I do this in the repl, it has some malformed-input tokens, which
         may or may not be a consequence of recent changes to the string
         pretty-printer.


         Probably not; ``%q`` is designed to satisfy the Lua reader, which is
         blissfully unaware of utf8, and would in fact have more likely
         encountered Latin-1 until relatively recently.  We need to satisfy
         both the Lua reader and any utf-8 validators we happen to run into.


  - [ ]  Write a bundle exporter, which builds a bundle from a database entry.


         I was originally going to do this from a live codex, before thinking
         it over and realizing that this is nearly as inconvenient as
         exporting from the database.


  - [ ]  Add a bundle table to the ``bridge.modules`` schema; this will be
         exceptionally simple, having a foreign key to a version, a project,
         and a string-typed bundle field which stores the whole thing as a
         single text.



- [ ]  Bundle importer


  - [ ]  Write ``Bundle.importBundle``, which:


        - [ ]  Receives a string,


        - [ ]  ``loadstring``s it,


        - [ ]  Validates the resulting structure,


        - [ ]  Sub-=loadstring=s the enclosed bytecode strings,


        - [ ]  Hashes the bytecode and compares with the provided hash,


        - [ ]  ``load``s but **does not execute** the bytecode, as a corruption
               check,


        - [ ]  Writes the entire thing to the database if it happens to pass
               all these stages.


  - [ ]  Add ``br import -f filename`` to import a bundle by file, and
         ``br export -o filename`` to write a bundle from the database to a
         plaintext file.


- [ ]  Bundle exporter


  -  Since we have this nice bundle format, it might be useful to make it
     possible for the user to export their entire database as a collection of
     bundles.


     It feels kind of wasteful to store an entire bundle in the database, the
     "right thing" is to generate one from a version.  But it's easier to
     bundle up a codex 'in-flight', rather than committing it to the database
     and subsequently removing it.


     This does mean we have two ways of making a bundle, but that's okay,
     they can serve as tests for one another, since they should make
     content-identical lua tables after ``load``ing.


     I may get tired of having the bundle-a-codex code around, and delete
     it, especially since both would need to be modified when the
     bridge.modules schema changes.


     But I do want to write the importer before the exporter, it's easier that
     way, and I need bundles to test it on.


     So we're going to:


  - [ ]  Write ``bridge export``, which creates bundles from the
         ``bridge.modules`` database.

## Bundle {}

- #fields


  - project:  table with information to populate the project table:


    - name:  Must be unique.


    - repo:  Main repo URL.


    - repo_alternates:  Newline-separated list of alternate repos.


    - home:  URL to request a project bundle by version.


    - website:  Project homepage.


    - repo_type?:  If not git, the type of repository.


  - version:  The version in [Clu Semver](httk://) form. One string.


  - modules:  An array table, each contains:


    - name:  Unique within project


    - branch:  git branch


    - code:  A Lua string which, loaded, produces the bytecode.


    - type?:  If not luajit-2.1-bytecode, the type of code.


    - vc_hash:  commit on repo branch corresponding to the version.


    - hash:  SHA-512 hash of code field.

```lua
local Bundle = {}
```
```lua

```
