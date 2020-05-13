









local fragments = {}










local gap_str = [[
    `gap`  <-  { \n([)]} / "{" / "}" / -1
]]
fragments.gap = gap_str






local hashtag_h_str = [[

   `hashtag_h`  ←  "#" (!gap 1)+
]] .. gap_str

local hashtag_str = [[

   hashtag  ←  hashtag_h
]] .. hashtag_h_str

fragments.hashtag = hashtag_str
fragments.hashtag_h = hashtag_h_str






local handle_h_str = [[

  `handle_h`  ← "@" (!gap 1)+
]] .. gap_str

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











local utf8_str = [[
   `utf8`  ←  [\x00-\x7f]
           /  [\xc2-\xdf] [\x80-\xbf]
           /  [\xe0-\xef] [\x80-\xbf] [\x80-\xbf]
           /  [\xf0-\xf4] [\x80-\xbf] [\x80-\xbf] [\x80-\xbf]
]]
fragments.utf8 = utf8_str



return fragments
