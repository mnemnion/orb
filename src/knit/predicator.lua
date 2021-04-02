









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

