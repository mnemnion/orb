#


  A collection module for knitters\.

We want these expandable at runtime, so we provide the ones we use \(minimum\)
in Orb, and make them into a table here\.


####

A knitter must expose these fields:


- code\_type:  A string corresponding to the `code-type` field of a Doc\.
    E\.g\. `lua` for Lua source code\.

    This should probably be case insensitive, but it isn't\.  We use
    lower case for everything\.


- pred:  A function to determine if a non\-code\_type code block should be
    parsed by the knitter\.  Must return `true` or `false`; we actually
    use "truthiness" in the extant source code, but please don't abuse
    our hospitality on this\.

    Signature is `pred(codeblock, skein)`, particularly to give access to
    the tags, but obviously this opens the door to a bunch of non\-local
    effects, most of which are a bad idea\.

  - params:

    - codeblock:  A Node of class codeblock\.


- knit:  A function to knit an ordinary codeblock of type `code_type`

   - params:

     - codeblock:  A Node of class codeblock\.

     - scroll:  The scroll in which the knit is to be inserted\.

     - skein:  The skein, holding all additional state, such as the original
         Doc, file paths, and so on\.


- knit\_pred:  A function to knit a codeblock matching the predicate\.  Same
    parameters as `knit`\.


```lua
return { lua = require "orb:knit/lua",
           c = require "orb:knit/c" }
```

