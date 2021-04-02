# Predicator

This is perhaps premature generalization, but:

Here we provide a function to return a knitting predicate, for matching a
codeblock to a particular hashtag\.

The example we're using is `#asLua`, but there will be others one day\.

```lua
return function(hashtag)
   return function(codeblock, skein)
      local tags = skein.tags[codeblock]
      if tags and tags(hashtag) then
         return true
      else
         return false
      end
   end
end
```
