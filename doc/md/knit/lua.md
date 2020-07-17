# Lua knitter


 Our workhorse\.

Knitters are provided as a simple table with a common format\.

We may want to add a base class at some point, if it proves necessary\.

```lua
local lua_knit = {}
```


### code\_type

A knitter is always applied if the `code_type` field of the `codeblock`
matches this string\.

```lua
lua_knit.code_type = "lua"
```


### lua\_knit\.pred\(codeblock\)

A `pred`icate function which determines whether to apply the knitter if the
`code_type` is something else\.

```lua
function lua_knit.pred(codeblock)
   local should_knit = false
   for tag in codeblock:select "hashtag" do
      if tag:span() == "#asLua" then
         should_knit = true
      end
   end

   return should_knit
end
```


### lua\_knit\.knit\(codeblock, scroll, skein\)

For knitting under standard conditions\.

Adds contents to the `scroll`, no return value\.

```lua
function lua_knit.knit(codeblock, scroll, skein)
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 1 do
      scroll:add ""
   end
   scroll:add(codebody)
   -- add an extra line and skip 2, to get a newline at EOF
   scroll:add ""
   scroll.line_count = line_end + 2
end
```


### lua\_knit\.pred\_knit\(codeblock, scroll, skein\)

For knitting a matched predicate\.

This function can be almost arbitrarily complex, but a simple pattern will get
us started: ignore the type of the codeblock, and make it into a Lua string\.

The next stage will be to incorporate C by calling `ffi.cdef`\.  With
tranclusion, we can do some pretty remarkable things this way\.

```lua
local format, find, gsub = assert(string.format),
                           assert(string.find),
                           assert(string.gsub)

function lua_knit.pred_knit(codeblock, scroll, skein)
   local name = codeblock:select "name"()
   local header = ""
   if name then
      -- stringify and drop "#"
      name = name:select "handle"() :span() :sub(2)
      -- normalize - to _
      name = gsub(name, "%-", "_")
      -- two forms: =local name= or (=name.field=, name[field])
      if not (find(name, "%.") or find(name, "%[")) then
         header = "local "
      end
   else
      local linum = codeblock :select "code_start"() :linePos()
      error (format("an #asLua block must have a name, line: %d", linum))
   end
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 2 do
      scroll:add ""
   end

   header = header .. name .. " = [["
   scroll:add(header)
   scroll:add(codebody)
   scroll:add("]]")
   scroll.line_count = line_end + 2
   -- #todo search for =="]" "="* "]"== in code_body span and add more = if
   -- needful
end
```

```lua
return lua_knit
```
