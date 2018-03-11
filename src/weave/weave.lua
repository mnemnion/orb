local u = require "lib/util"

local Node = require "peg/node"

local m = require "grym/morphemes"


local W, w = u.inherit(Node)

function W.weaveMd(weaver, doc, phrase)
  local phrase = phrase or ""

  -- Add the local weave to Markdown
  local md = ""
  if doc.toMarkdown then
    md = doc:toMarkdown() or ""
  end
  local phrase = phrase .. md

  for _, node in ipairs(doc) do
    phrase = phrase .. W.weaveMd(weaver, node, phrase)
  end

  return phrase
end

local function new(Weaver, doc)
    local weaver = setmetatable({}, W)


    return weaver
end

return u.export(w, new)

