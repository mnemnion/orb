



























































































local init, new
local s = require "core/status" ()
s.angry = false
local Phrase = {}
Phrase.it = require "core/check"





















local function spill(phrase)
   local new_phrase = init()
   for k, v in pairs(phrase) do
      new_phrase[k] = v
   end
   new_phrase.intern = nil

   return new_phrase
end


local function __concat(head_phrase, tail_phrase)
   if type(head_phrase) == 'string' then
      -- bump the tail phrase accordingly
      if tail_phrase.intern then
         tail_phrase = spill(tail_phrase)
      end

      table.insert(tail_phrase, 1, head_phrase)
      tail_phrase.len = tail_phrase.len + #head_phrase
      return tail_phrase
   end
   local typica = type(tail_phrase)
   if typica == "string" then
      if head_phrase.intern then
         head_phrase = spill(head_phrase)
      end
      head_phrase[#head_phrase + 1] = tail_phrase
      head_phrase.len = head_phrase.len + #tail_phrase
      return head_phrase
      elseif typica == "table" and tail_phrase.idEst == new then
      local new_phrase = init()
      head_phrase.intern = true -- head_phrase is now in the middle of a string
      tail_phrase.intern = true -- tail_phrase shouldn't be bump-catted
      new_phrase[1] = head_phrase
      new_phrase[2] = tail_phrase
      new_phrase.len = head_phrase.len + tail_phrase.len
      return new_phrase
   end

   return nil, "tail phrase was unsuitable for concatenation"
end








local function __tostring(phrase)
  local str = ""
  for i,v in ipairs(phrase) do
    str = str .. tostring(v)
  end

  return str
end



local PhraseMeta = {__index = Phrase,
                  __concat = __concat,
                  __tostring = __tostring}




init = function()
   return setmetatable ({}, PhraseMeta)
end

new = function(phrase_seed)
   phrase_seed = phrase_seed or ""
   local phrase = init()
   local typica = type(phrase_seed)
   if typica == "string" then
      phrase[1] = phrase_seed
      phrase.len = #phrase_seed
   else
      s:complain("Error in Phrase", "cannot accept phrase seed of type" .. typica,
                 phrase_seed)
   end
   return phrase
end

Phrase.idEst = new








local function spec()
   local a = new "Sphinx of " .. "black quartz "
   a: it "phrase-a"
      : passedTo(tostring)
      : gives "Sphinx of black quartz "
      : fin()

   local b = a .. "judge my " .. "vow."
   b: it "phrase-b"
      : passedTo(tostring)
      : gives "Sphinx of black quartz judge my vow."
      : fin()

end

spec()




return new
