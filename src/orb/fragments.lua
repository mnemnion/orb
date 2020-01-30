









local fragments = {}






local hashtag_str = [[

   hashtag  <-  "#" symbol
]]

fragments.hashtag = hashtag_str






local handle_h_str = [[

  `handle_h` = "@" symbol
]]

local handle_str = [[

   handle <- handle_h ; this rule may require further elaboration.
]] .. handle_h_str

fragments.handle = handle_str
fragments._handle = handle_h_str





















local symbol_str = [[

   `symbol`  <-  (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)
]]
fragments.symbol = symbol_str















local term_str = [[

   `t` = { \n.,:;?!)(][\"} / -1
]]
fragments.t = term_str










local gap_str = [[
    `gap`  <-  &(" " / "\n" / "(" / "[" / ")" / "]" / -1)
]]
fragments.gap = gap_str



return fragments
