# Predicator

This is perhaps premature generalization, but:

Here we provide a function to return a knitting predicate, for matching a
codeblock to a particular hashtag\.

The example we're using is `#asLua`, but there will be others one day\.

```lua
return function(hashtag)
   return function(codeblock)
      local should_knit = false
      for tag in codeblock:select "hashtag" do
         if tag:span() == hashtag then
            should_knit = true
         end
      end

      return should_knit
   end
end
```
