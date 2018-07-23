# Splicing


I've been thinking about how to approach existing codebases.


The simplest approach is to have one page per file, and interiorize the whole
thing.  But that gets messy if you're trying to upstream changes.


I want something more like this:

@fancy-table```C-example
/* Fancy C hashtable goes here
...
*/
```

Splice is a specialization, we'd usually put it in a drawer:


:[config]:
#Splice outfile.c#comments no
line references are to the original file, such that deletions and additions
in a single pass don't affect one another's offset.


The subtle bit is turning a transclusion into a splice.  Normally edits in a
transclusion are either shared with source (the default) or are isolated in
the document, call that an exerpt maybe.


In a splice, edits to the transclusion are mirrored in the sorcery file, but
in a way that the splicing document is blind to.


Splices are slightly delicate and might need to be manually adjusted if an
upstream pushes large changes.  They'll be pretty useful in practice.


This lets me unleash the full might of Orb on codebases such as LuaJIT, where
trying to hoover the whole thing into a literate translation would be a lot of
work, and hostile to the goal of getting change sets onto master.


A splice can be turned back into an ordinary transclusion. The difference is
that working on a file in splice mode is archaeological. Any of the changes
can be unapplied, so we can go nuts on other people's code and still offer a
tasteful, minimal patch set, without getting involved in cherry-picking.


Even within our own codebases, splices may work better than the more
traditional literate macro for conditional compilation and the like.
