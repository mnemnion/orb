# Anchor


  An anchor is the part of a hypertext link representing the destination\.

Our anchors come in two flavors: the familiar URI, and "ref"s\.


#### imports

```lua
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"
```


## Ref

  A ref is a short link, meant to be an Orb\-native way of referring betweeen
documents\.

I'm still working on the syntax here\.  These use the Bridge namespace
conventions to resolve links between projects and within documents in a
flexible way\.

I intend to make newlines withi n an anchor legal, such that they will be
ignored by the engine\.  They must be between parts of the URI, or ref\.  It's
easier to implement without this and add it later\.


### @ Refs

Refs begin with an `@` sign, making them a sort of handle\.

These always refer to a document or directory in an Orb project, or, a section
within one\.

`@name` is an internal reference, with a name resolution policy which is TBD,
but will be based on the GitHub schema for anchor reference resolution\.  If
there's an explicitly named entity with that name, the link will resolve to it\.

`@:folder/file` refers to a module inside the same project\.  This is a
reference to our `require` syntax, `"project:module"`, with the project
elided\.  `@project:folder/file`, therefore, is a reference across projects,
with the same fully\-qualified form as in `require`: the namespace is assumed
to be the native namespace, unless provided, or overridden in the manifest\.

It's valid to refer to just a project as well, as `@full.domain/project:` or
`@project:` for the default domain\.

In a cross\-document reference, we use the familiar `#` form for an anchor
within a document `@fully.qualified/project:folder/file#fragment`\.  At
present, we don't support queries in refs, but perhaps we should\.  I'm pretty
sure that `@named-ref` is the same as `@project:module/file#named-ref`, if
we're inside project\-module\-file\.

There's no need to elide the domain, a la `@/project:file`, which iscurrently\) not a valid ref\.  If one isn't provided, the resolved URL will be
based
\( on the `default_domain` field in the [manifest](@br-guide:orb#manifests)\.

Note that `.orb` is not needed and should be elided, although we'll make the
parser smart enough to accept it\.  Orb documents take on several extensions
depending on where they end up\.


```peg
        ref  ←  pat ( domain net project col doc-path
                    / project col doc-path
                    / doc-path ) (hax fragment)*

     domain  ←  (!"/" 1)+
    project  ←  (!":" 1)*
   doc-path  ←  (!"#" 1)*
   fragment  ←  (!"]" 1)+
        net  ←  "/"
        pat  ←  "@"
        col  ←  ":"
        hax  ←  "#"
```


#### Inline expansion \(not an @ref\) \#NYI

Epistemic status: maybe?

Sometimes we want to expand a large URL which is named elsewhere\.  This is
not an @ ref, although it looks kind of like one:

```orb
[[a long link][`@named-entity()`]]
```

Uses our normal inlining syntax to paste the value of `@named-entity` into the
ref position\.

We haven't added any inline expansion capability anywhere in Orb yet, so this
one is going to sit on the shelf for awhile\.


## Anchor

```peg
   anchor  ←  ref / url / bad-form
      url  ←  "http://example.com" ; placeholder
 bad-form  ←  (! "]" 1)+
```

```lua
anchor_str = anchor_str .. "\n\n" .. ref_str


-- We'll need some custom metatables soon, but: not this instant.
local anchor_grammar = Peg(anchor_str, {Twig})

return subGrammar(anchor_grammar.parse, "anchor-nomatch")
```
