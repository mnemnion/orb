# Manifest


  Manifests are how we configure Orb documents\.

In essence they are simply [TOML](@:lon/loml) code blocks, which can be
found within a specific file, or more usually in a top\-level Orb document
called `manifest.orb`\.

Presumably we'll have a global manifest in `$BRIDGE_HOME` as well\.

Other than that I have basically no idea what this is actually going to look
like\.  Any code block with `#!toml #manifest` in it will end up in the
appropriate Manifest, and access is of course through the skein\.


### Fields

  This will be a list of all key/value pairs and subtables recognized by the
manifest format\.


-  weave:  A table for weave\-specific configuration\.

   - module\_url:  The base for [refs](httk://) within the module itself\.

   - project\_url:  The project base url\.

       We'll need to do a bit of magic to make this work, because
       the Git\(Hub|Lab\) style of constructing URLs isn't as simple
       as project\_url \+ module\_name \+ rest\_of\_the\_ref\.

       So the weave table will have some way to construct the
       intermediate information, with a "sensible" default: for a
       markdown weave on Gitlab, `/-/blob/trunk/doc/md/`\.


- knit:  A table for knit\-specific configuration\.

    This will ultimately include versioning for various dependencies,
    which is a complex system with several unfilled prerequisites\.

    Or maybe the bridge\-specific stuff goes in a `bridge` table\.  TBD\.


## Implementation

  The Manifest itself is just a container: you feed it data, and it represents
that data as Lua tables\.

TOML codeblocks, like any codeblock, just have a `code_body` Node, which isn't
normally parsed within it\.

We want to be able to read from a Manifest without blocking any potential
fields \(I think?\) so we'll use `__call` to do the two things a Manifest is
expected to do: `manifest(codeblock)` will add the TOML to the existing
Manifest, and `manifest(true)` will return a new Manifest inheriting from the
old one\.

We use the latter for e\.g\. encountering a `#manifest` block inside a file, or
if we have a global `manifest.orb`, we use it to create the `.manifest` field
on the Lume\.  I'm not in love with this code signature, but at least at the
moment I prefer it to having a mixture of methods and plain\-old\-data\.
