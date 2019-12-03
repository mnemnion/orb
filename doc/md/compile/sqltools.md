# SQL tools


  A collection of helper functions for working with the SQLite database.


May be migrated to ``sql.orb`` in ``pylon`` if they prove their worth.

```lua
local sql = assert (sql)
```
```lua
local SQLtools = {}
```
### unwrapKey(result_set)

Unwraps the first result, of the first row, of returned results.


Intended to be used for a unique foreign key, hence the name.


Will coerce cdata into a Lua number for ease of use.


Assumes that (at least) ``"i"`` was passed to ``conn:exec``.

```lua
function SQLtools.unwrapKey(result_set)
   if result_set and result_set[1] and result_set[1][1] then
      local id = result_set[1][1]
      if type(id) == "cdata" then
         return tonumber(id)
      else
         return id
      end
   else
      return nil
   end
end
```
### tableResults(sql_result, [num | "all"])

Unwraps one or more results from a sql_result, which assume that (at least)
``"k"`` was passed to ``conn:exec``.


This converts from a column-oriented to a row-oriented form, and coerces cdata
integers into Lua reals.


If no ``num`` is provided, returns one table, with column names as the keys and
values as the values.


If a number is provided, including 1, it returns a table of tables, up to the
number requested.


If the string ``"all"`` is provided, it converts all results in the set.


```lua
function SQLtools.tableResults(sql_result, num)
   local one_result = false
   local result_tab = {num = num}
   if not num then
      num = 1
      one_result = true
   end
   assert(type(num) == "number" or num == "all")
   for key, column in pairs(sql_result) do
      if type(key) == "string" then
         if num == "all" then
            for i,v in pairs(column) do
               if type(v) == "cdata" then
                  v = tonumber(v)
               end
               result_tab[i] = result_tab[i] or {}
               result_tab[i][key] = v
            end
         else
            for i = 1, num do
               local v = type(column[i]) == "cdata"
                         and tonumber(column[i])
                         or column[i]
               result_tab[i] = result_tab[i] or {}
               result_tab[i][key] = v
            end
         end
      end
   end
   if one_result then
      return result_tab[1]
   else
      return result_tab
   end
end
```
```lua
return SQLtools
```
