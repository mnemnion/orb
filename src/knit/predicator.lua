



















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

