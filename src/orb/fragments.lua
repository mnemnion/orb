









local fragments = {}






local hashtag_h_str = [[

   `hashtag_h`  ←  "#" symbol
]]

local hashtag_str = [[

   hashtag  ←  hashtag_h
]] .. hashtag_h_str

fragments.hashtag = hashtag_str
fragments.hashtag_h = hashtag_h_str






local handle_h_str = [[

  `handle_h`  ←  "@" symbol
]]

local handle_str = [[

   handle  ←  handle_h
]] .. handle_h_str

fragments.handle = handle_str
fragments.handle_h = handle_h_str





















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