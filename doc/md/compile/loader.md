# loader

This is ultimately something to add to ``package.loaders``.


I need to add a bunch of database manipulation here, so it will probably also
have the parts of the compiler which write changes to the database.

```lua
local sql = require "sqlite"
```
```lua
local Loader = {}
```
```lua
return Loader
```
