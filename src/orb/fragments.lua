









local fragments = {}



local hashtag_str = [[

   hashtag  <-  "#" symbol
]]

fragments.hashtag = hashtag_str



local handle_str = [[

   handle <- "@" symbol ; this rule may require further elaboration.
]]
fragments.handle = handle_str



local symbol_str = [[

   symbol  <-  (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)
]]
fragments.symbol = symbol_str



return fragments
