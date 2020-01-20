# Tag Engine


The tag engine is how we control custom behavior in Orb.


## Mechanism

The tag pass is driven by the [[espalier/stator][hts://@espalier/stator.orb]]
module.


The algorithm is driven by ``org-mode``'s capitalization paradigm.


### =#Capital= and =#miniscule= hashtags

A Capital tag inherits. Thus a tag at the top level of a Doc is part of the
state unless and except as overridden, for each visitation of each leaf.


A miniscule tag is restricted to the **block** it is found in.  This means
hoisting, which is something we do infrequently, but after each block parse a
single-round hoist must be performed and the state revisited if there's
anything sitting in the lift.


Good style would therefore front-load so this can be a single pass.  But
clarity above all else.


## Tags

```lua
local TagEngine = require "stator" ()
```

These are intended to be assembled into ``org agenda`` and there's every reason
to simply do this during the tag visitation.


So we attach a singleton ``Agenda`` table to the ``stator`` system and add to a
``__repr`` bank.  It should suffice to capture back references to the spots in
the Doc which correspond to the #Todo, and use the ``span`` to retrieve
the text itself for display en scroll or en femto.


Or en ``ent``, as we proceed.


Additional tags we'll need sooner than later: ``#Knit``, ``#NoKnit``, and hence
``#knit`` and ``#noKnit``.   These produce directives in the form of a boolean
``true`` or ``false``, these respectively force and forbid ``knit``ting during that
transduction.


We would expect a drawer as a top level ``.deck`` tag saying ``#NoKnit`` in a
``~/notes/`` folder. This would forbid knitting, doing away with a bunch of
spurious sorcery.

### #transclude

This will be added as link syntax starts to stabilize.  I'm making progress
there.


So alright let's try a transclusion:

```orb
#!lua #transclude @notes/compiler.orb#code#!sql
local create_code_table = [[
<<@>>
]]
#/lua
```

Well.  Suffice to say that doesn't display correctly in Sublime Text yet.


It sure looks right.  The "@notes/compiler.orb#code#!sql" goes to the
``@notes`` folder, this is an elision of ``@~notes`` unless there's a ``br/notes``
which I suggest against.  For now.


Then takes ``*** code`` from ``./notes/compiler.orb``, retrieves the first ``#!sql``
block it encounters, and transcludes it at the ``<<@>>`` mark.


There will be more complex expansions but this is the most basic and powerful.


I intend to mostly follow the GitHub standard, cross-compatibly with that of
GitLab, for constructing URIs into codebases.


We will use this to specify patches into existing codebases, such that
complex changes can be kept in a useful directory and opinions, strategies,
and the like might accumulate around these patches.


### #patch

Let's patch something and transclude.

```orb
#!orb @notes/compiler.orb -- etc.
** SQLite table CREATEs


*** code

  The =code= table has a key =code_id=, a =blob= field =binary=, and a
=hash= field.  I think the =hash= field should be SHA3, just as a
best-practices sort of thing. As it turns out, after running a test, SHA512
is substantially faster.  Now, this may or may not be true of SHA512 in pure
LuaJIT, but that's less important.

So we want to open/create with:

#!sql @code
CREATE TABLE IF NOT EXISTS code (
   code_id INTEGER PRIMARY KEY AUTOINCREMENT,
   hash TEXT UNIQUE NOT NULL ON CONFLICT DO NOTHING,
   binary BLOB NOT NULL
);
#/sql

strictly speaking =blob= should also be UNIQUE but that's comparatively
expensive to check and guaranteed by the hash.

#!lua #patch @compile/loader.orb#l66 #transclude @code
local create_code_table = [[
<<@>>
]]
#/lua
#/orb
```
#### exegesis: =#!lua #patch @compile/loader.orb#l66 #transclude @code=

This says:  we have a Lua patch, to at compile slash loader dot orb,
hash Lima 61, hashtag transclude at code.


Implication: lines must be combed after each transclusion to keep other
patch references to the same Doc in sync.


The transclusion expands to this:

```lua
local create_code_table = [[
CREATE TABLE IF NOT EXISTS code (
   code_id INTEGER PRIMARY KEY AUTOINCREMENT,
   hash TEXT UNIQUE ON CONFLICT IGNORE NOT NULL,
   binary BLOB NOT NULL
);
]]
```

Which is then patched to line 66 of loader.orb.


The ``#noKnit`` is a custom, for this document.  The expansion doesn't have it,
go on, check ``^_^``.


Bears repeating, any subsequent references into loader.orb **must** be adjusted
in place, and emphasizing that this is copied all the way down to the disk
representation of the orb document.


That is what ``loader.orb`` looks like now due to manual transclusion aka
copypasta.


Note the hashtag ``#dontEdit``.  That's just a reminder of what happens if you
do.  Transclusion should work both ways but until it does...


That trick calls for source mapping.  I believe we're weaving together the
necessary infrastructure to put that in the codex, so stay tuned.


So clear enough what that _should_ do.


### #Alias @a @Alice, #alias @b @Bob  [ ]  #Todo

These assign a short name to a long one.


This is to be used in Capital within a ``.deck`` file as an import, where the
``@handle`` would be a fully-qualified version string.


For an example.
