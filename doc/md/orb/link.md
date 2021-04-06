# Link


  A [link](httk://this.page) is borrowed more\-or\-less wholesale from org
mode\.  We reverse the order of slug and anchor, in the style of Markdown,
because in a readable document format, the part you're expected to read should
come first\.


### Link Grammar

```lua
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"
local fragments = require "orb:orb/fragments"
local WS  = require "orb:orb/metas/ws"
local s = require "status:status" ()
s.grumpy = true

local Twig = require "orb:orb/metas/twig"
```

```peg
   link         ←  link-head link-text link-close WS*
                   (link-open anchor link-close)?
                   (WS* hashtag WS*)* link-close
                /  link-head link-text link-close obelus link-close

   link-head    ←  "[["
   link-close   ←  "]"
   link-open    ←  "["
   link-text    ←  (!"]" 1)*

   anchor       ←  h-ref / url / bad-form
   `h-ref`      ←  pat ref
   ref          ←  (h-full / h-local / h-other)
   `h-full`     ←  project col doc (hax fragment)?
   `h-local`    ←  doc (hax fragment)?
   `h-other`    ←  (!"]" 1)+  ; this might not be reachable?
   project      ←  (!(":" / "#" / "]") 1)*
   doc          ←  (!("#" / "]") 1)+
   fragment     ←  (!"]" 1)+
   pat          ←  "@"
   col          ←  ":"
   hax          ←  "#"

   ;; urls probably belong in their own parser.
   ;; this might prove to be true of refs as well.
   url          ←  "http://example.com"
   bad-form     ←  (!"]" 1)*
   obelus       ←  (!"]" 1)+
   WS           ←  { \n}+
```

```lua
link_str = link_str .. fragments.hashtag

local link_M = Twig :inherit "link"
```

```lua
local function obelusPred(ob_mark)
   return function(twig)
      local obelus = twig:select "obelus" ()
      if obelus and obelus:span() == ob_mark then
         return true
      end
      return false
   end
end

function link_M.toMarkdown(link, scroll)
   local link_text = link:select("link_text")()
   link_text = link_text and link_text:span() or ""
   local phrase = "["
   phrase = phrase ..  link_text .. "]"
   local link_anchor = link:select("anchor")()
   if link_anchor then
      link_anchor = link_anchor:span()
   else
      -- look for an obelus
      local obelus = link:select("obelus")()
      if obelus then
         -- find the link_line
         local ob_pred = obelusPred(obelus:span())
         local link_line = link
                             :root()
                             :selectFrom(ob_pred, link.last + 1) ()
         if link_line then
            link_anchor = link_line :select "link" () :span()
         else
            local line_pos = obelus:linePos()
            local link_err = "link line not found for obelus: "
                             .. obelus:span() .. " on line " .. line_pos
            scroll:addError(link_err)
            link_anchor = link_err
         end
      else
         link_anchor = ""
      end
   end
   phrase = phrase .. "(" ..  link_anchor .. ")"
   scroll:add(phrase)
end
```

```lua
local Link_Metas = { Twig,
                     link = link_M,
                     WS   = WS, }
local link_grammar = Peg(link_str, Link_Metas)
```

```lua
return subGrammar(link_grammar.parse, "link-nomatch")
```


## Link

Most of the complexity of a link is in the document\-resolving portion, which
we call a ref\.

Links are always surrounded by one pair of brackets, and must have one more
pair between them: whitespace between the two opening brackets is
illegal, so `[[` always opens a link\.  For links without attribute tags or an
obelus, the closing token must also be exactly `]]`\.

If there is only one such inner box, and no contents between the first "\]" and
the second, the contents are a bare ref, like 
\[\[http://example\.com\]\]
\.

If there are two boxes, then the first contains the link text, and the second
the link ref: 
\[\[An example website\] \[http://example\.com\]\]
\.  This is the
same order as Markdown, but the opposite of that used in org\-mode and the HTML
standard\.  We feel that, in a source document, the description is the
interesting part to a reader, and having to skip the anchor in order to keep
reading breaks the flow of the sentence\.

We also offer a short form: 
\[\[A description\]Obelus\]
 will look for a
corresponding ref line: 
\[Obelus\]: http://example\.com
, and use that as the
ref\.  The obelus can be anything so long as there are no spaces or newlines,
and whitespace is forbidden on both sides of the obelus\.  You can't wrap it
in brackets or curly brackets either, for obvious reasons, and it can't be a
hashtag: the actual rule is that an obelus can't begin with `#`, `{`, or `[`\.

A ref line must be preceded and followed by a block separator, that is, either
a newline, or at least two, depending on whether the grammar can distinguish
the line from the preceding style\.  Good style is to use at least two
newlines, and usually exactly two\.  You can reuse obeluses, and the ref line
must be below the link, by any amount that's comfortable: the engine will
match the next note with the same text, and will warn if it isn't able to find
one\.

To expand, if you have a [link like this]([[link like this]†]) and another [link like this](https://example.com/both-links-resolve-to-this),
they will both expand to the next ref line with that obelus\.  If you then
make another link below that ref line, with the same obelus, it will resolve
to the next ref line with that obelus\.

Attributes are expressed as hashtags at the end: 
\[\[An Image\]
\[@img/doge\.jpg\]\#img\]
 is one example\.  Whitespace is allowed around hashtags,
and you may use as many as you need\.


### Ref

  A ref is a superset of the URI, used to identify where in the weird wide web
of data the link is to be resolved to\.

Normal refs are simply URIs, which don't need elaboration here\.

Anything which doesn't fit the URI pattern is a short link, and I'm still
working on the syntax here\.  These use the Bridge namespace conventions to
resolve links between projects and within documents in a flexible way\.

One note: newlines in a URI are legal, and will be ignored by the engine\.
They must be between parts of the URI, or reassembly will give unexpected
results\.  This is only true for URIs in links, not in ref lines: the latter
don't have a distinct closing character, so the parser knows its done with a
ref when it finds the line end\.


#### @ Refs

An important class of short\-form refs are named refs or @ refs\.

These always refer to an orb file, or a part of it\.

`@name` is an internal reference, with a name resolution policy which is TBD,
but will be based on the GitHub schema for anchor reference resolution\.  If
there's an explicitly named entity with that name, the link will resolve to it\.

`@:folder/file` refers to a module inside the same project\.  This is a
reference to our `require` syntax, `"project:module"`, with the project
elided\.  `@project:folder/file`, therefore, is a reference across projects,
with the same fully\-qualified form as in `require`: the namespace is assumed
to be the native namespace, unless provided, or overridden in the manifest\.

In a cross\-document reference, we use the familiar `#` form for an anchor
within a document `@fully.qualified/project:folder/file#fragment`\.  This
generalizes to query syntax as well\.

Note that `.orb` is not needed and should be elided, although we'll make the
parser smart enough to accept it\.  Orb documents take on several extensions
depending on where they end up\.

Sometimes we want to expand a large URL which is named elsewhere\.  This is
not an @ ref, although it looks kind of like one:

```orb
[[a long link][`@named-entity()`]]
```

Uses our normal inlining syntax to paste the value of `@named-entity` into the
ref position\.
