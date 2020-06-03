# orb tag


This is an inner verb, in the sense that while one can call it from an outer
context it is normally invoked as the next step after ``spin``ning a Doc.


``orb tag`` operates the tag engine.


This turns Hashtag and Hashline classes into metadata on the AST.


This metadata is in turn used to guide the realization of subsequent steps.


The design work is in the [tag engine notes](hts://~/notes/tag-engine.orb).


#### asserts

```lua

```
#### requires

```lua
local esp = require "espalier:espalier"
```
## OrbTag

```lua
local OrbTag = esp.stator()
```
