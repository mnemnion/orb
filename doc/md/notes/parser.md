# A Grimoire Parser

## Introduction

I need a literate toolchain stat. I'm unwilling to write it on
Org. I've been having fun with Org but it has to go, and now is
the time.


I need this before the quipu, to write the quipu, so we're going to
forget reusable parsers and general editing structures and everything
like that for now. We're going to cut a fast parser out of Lua and
start hooking it up to things.


Pegylator is proving remarkably useful for software I thought I was
abandoning in mid-February. But I digress.


There are important structural similarities between Grimoire and Markdown.
More with Org, of course, but Markdown is more widely parsed. Let's see
what we can find.


Oh hey this looks good:


[[https://github.com/jgm/lunamark][lunamark]]


In fact this looks very good. If I can trick lunamark into thinking that
Grimoire is just some exotic flavor of Markdown I can get a **lot** of
functionality for free.


Let's try this approach and see if it flies.


Hmm. There's a lot of useful code and approaches to lpeg to steal here.
But I'm just too well-equipped with my toolchain to want to switch horses.


The Node class is a little janky but not particularly broken and is shaping
up as my common AST format when in Lualand. If those get out of whack there will
be pain sooner or later. That's worth more than being able to use the lunamark
toolchain for export and the like.


At least for now. I'll try to hold on to some of the naming conventions and see
if maybe I can talk the author into adapting the module once we're the popular
kids.

## Structure

We're going to do this in several passes.

### Chunking

Our top-level of structure is determined by [[file:grimoire.org::*Header%20Lines][header lines]], which
cooperate to form the structure of a Grimoire document.


While we're doing this, we'll chunk everything else into arrays
of lines, this will split into structure lines, blank lines,
and TBD.


I believe we can get everything into blocks on this first pass.


At this point, the data structure is still flat, but chunky, and
we have a separate vector of the header lines and their index
into the chunks.

### Ownership

We next determine basic ownership. This we do by counting all the stars
in the header lines and building a tree accordingly. This is a
recursive map of vectors containing chunks.

#### Cling Rule

Various kinds of block have [[file:grimoire.org::*The%20Cling%20Rule][cling rules]] associated with them. How this
works is still somewhat opaque, no substitute for code in actually
working it out.


We apply these rules, attaching tags to associated lists, tables and
code blocks, for example.


I think the secret sauce of the cling rule is that it never matters if
marks cling up or cling down, tags and names can come before, after, or
around the blocks they cling to.

### Block Parsing

Next we go into certain kinds of block and parse them.


This resolves the inner structure of 'structure' lines, which includes
all lists, tables, and similar. Some of these will not have been detected
yet, when this stage is done, what's left is prose, and unparsed code,
and we know which is which.


We haven't found all code, just code blocks.

### Prose Parsing

We next parse these prose regions, looking for structural elements and
handling them accordingly.

### Mark Parsing

As a final step, we parse within marks. Marks are either tags or names,
and both have a complex, TBD internal structure.

## Result

Code is not parsed by this parser, not explicitly.


Eventually, the document will have to be executed within an appropriate
sandbox before it can be either tangled or woven. We'll skip that little
refinement, Lua is the runtime for that stage so it's comfortable to add
it later.


What we do next depends on whether we're weaving or tangling. Weaving
is less interesting to me, at least for now; I'm hoping that if we get a
bit of traction some wonk at Pandoc will add our biological distinctiveness
to that collective and we'll get a big boost in the right direction.


Weaving is one of those things we can just iterate on endlesssly, and indeed
have to, document formats being what they are.


For simple tangling, we're interested in marks, edn blocks, and code blocks,
for now. Lists are the next data structure I'm interested in, with tables in
last place. I'm just not a grid kind of thinker.



## Subsequent Actions

Each of these needs its own document.

### Filtration

We normalize certain aspects, including a rigorous and unflinching programme of tab removal.

### Tangling

The tangler is the first thing I intend to write.

### Unraveling

I'm designing the tangler specifically so that I can unravel from source.


How does that work? I intend to work out those details quite soon.


Having a sense of how the structure is parsed internally is important here.


This subject has its [[file:unraveler.org::*grym%20unravel][own section]] already.

### Weaving

Naturally, we need to weave.


I don't know if this ever needs to be more customized than adding Grimoire
format to a few canonical documentation engines.


If we want to do fancy stuff with React and that, it does.

