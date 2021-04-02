#


A metalanguage for magic spells\.


##

We put `core` in the global namespace, and `nil` it out on exit\.

This is kind of a bad habit, but there's nothing really *wrong* with it, so
it's not worth fixing in this case\.  But I don't expect to do it elsewhere\.

```lua
core = require "core:core"
```


##

```lua
local Orb = {}
```


##

`orb:orb` is effectively a entry point for the Lume\.

That might not always be true, the Lume is a good design and I don't expect
to have to ditch it, but looser coupling with the rest of the system is a
priority\.

So we'll retain the Orb table, even though the Lume is its only field\.

```lua
Orb.lume = require "orb:lume/lume"
```

```lua
core = nil

return Orb
```
