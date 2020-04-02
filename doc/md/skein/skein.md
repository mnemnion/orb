# Skein


  A skein is an object for holding a Doc, with all its derivative works.


The first toolchain was a bootstrap, which was accomplished by the simple
expedient of perfect uniformity.  Every file in the ``orb`` directory of a
project was presumed to have some Lua in it, and there is a one-to-one
correspondence between ``orb`` on the one hand, and ``src`` on the other, same
for the weave.  Every line of Lua is found in the same place as it is in the
Orb file, and so on.


This was a useful paradigm, but now we have the new parser, and we need to
walk back some of those design choices.  The Orb files must remain the source
of truth, but everything else changes: Orb files may affect each other,
mutate each other both in ways which are written to disk and ways which are
not, and may generate multiple artifacts of the same sort, or one Orb document
may be a source of code in a knit or weave derived ultimately from another.


We took this general-to-specific approach to the extreme where compilation in
the old method is all-or-nothing.  We briefly had the ability to knit (but not
weave) a single document, but surrendered it.


Now we'll build from a single file outward.  We keep the semi-literate style
for now, but make a single skein capable of everything that needs: parsing,
formatting, spinning, knitting, weaving, and writing all changes to both the
filesystem and the module database.


Then we'll rebuild the Codex, with as few of the old assumptions as possible.
In particular, we'll leave out Decks at first, and add them back if they
actually prove useful, which they might.  That gets us to feature-parity with
the old compiler, which we may then remove.


With careful engineering, this will put us in a position for Docs to be
dependent on other Docs, which we can resolve with inter-skein communication.

```lua
local Skein = {}
Skein.__index = Skein
```
```lua
function Skein.load(path)

end
```
```lua
function Skein.filter(skein)

end
```
```lua
function Skein.format(skein)

end
```
```lua
function Skein.knit(skein)

end
```
```lua
function Skein.weave(skein)

end
```
```lua
function Skein.commit(skein, stmts)

end
```
```lua
function Skein.persist(skein)

end
```
```lua
local function new()
   local skein = setmetatable({}, Skein)

   return skein
end

Skein.idEst = new
```
```lua
return new
```
