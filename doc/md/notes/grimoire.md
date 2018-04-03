 

# Introduction

Grimoire is a response to Babel.


Babel is simultaneously a kludge and the most potentially powerful language in existence.


Babel is a metalanguage. The structure of Org mode lets the user weave together code into a
living document, in a flexible, powerful way.


The name is charmingly apt. Babel exists at the top of a tower of abstractions that is teetering
on the verge of collapse. Org-mode is an extension of outline mode, which was a simple tree
editor task list.


Various users bolted stuff on, because that's how emacs grows, you bolt stuff onto it and it
continues to function because it's [[http://lispers.org/][made with alien technology]].


The problem with Babel is more than the syntax being clunky, though that's a problem. The issue is
more profoundly that Babel is built on Org, which is built on emacs. It's a language, yes,
parsers exist for other platforms. But as a runtime, it isn't portable without a lot of effort.


So much so, that we get a chance to start over. It's roughly as difficult to write Grimoire as it would be to
reimplement Babel in, say, Sublime.


In the process, we can:


  - streamline concepts, making them more orthogonal
  - clean up the clunkiness in the grammar
  - build a toolchain that will let us write magic spells in any number of languages, amassing a powerful
    collection of same. A grimoire, if you will: a living book in which magic is both written and performed.

# Musings on Metasyntax
## Constraints

There is a difference between a metalanguage and a literate programming language. Babel is a metalanguage,
as Grimoire is intended to be.


An effective metalanguage balances three concerns. It must be usable, readable, and parsable.

### Usable

A metalanguage is used interactively, on a deeper level than REPLs.


This is what makes working with Org so amazing. The first purpose of what became Babel
was simply editing outlines. This was outline mode, which dates back to the era when
using asterisks and =- [ ]= checkboxes in a plain ASCII text file was fairly futuristic
behavior.


You can't really call that a language either, though it's a syntax. More and more features
were attached until we have modern Babel. But because each feature was build as an extension
to the editing/runtime environment, Babel is fairly smooth to work with.


If you can handle Emacs. I can, some can't. A metalanguage is tightly coupled to its runtime,
because its runtime is its editing environment. Not much of a metalanguage if this isn't the
case.


Grimoire is the culmination of a considerable dependency chain. We need a data structure, a
parser to work with the data structure, and an editing environment that builds on these. For
maximum enjoyment, we'll want a custom terminal that enhances the xterm protocol with a few
features, most notably graphics.


Just like I have trouble writing Lua without burning huge amounts of time planning out Clu, I
can't use Org without doing the same for Grimoire. It's all related: I need a really good parser.


[[https://github.com/UpstandingHackers/hammer][hammer]] is the leading contender. But back to Grimoire.

### Readable

Grimoire is designed to be read.  It's important that the raw syntax not
 break the reader's flow.  A good metalanguage lets the user employ just
 as much magic as she's comfortable with, without imposing more.


Our syntax is  designed to support this. As such  it is deeply concerned
with matters  such as indentation  and whitespacing, which are  basic to
readability.


It will be quite possible and indeed comfortable to write pure documents
such  as blog  posts in  Grimoire form.  In that  use case  it resembles
Markdown.

### Parsable

Grimoire  documents are  intended  to be  highly  convoluted. The  basic
editing operation  is the fold. The  Grimoire editor must be  capable of
handling documents in the tens of megabytes with a complex and preserved
folding structure.


This requires  a ground-up  editing environment  rewrite to  employ data
structures   with   correct   big-O    complexity   and   an   efficient
implementation.


This  also  requires  that  the   language  be  well-designed  for  easy
recognition of the structural elements. As this document evolves, I will
be defining a grammar in the syntax preferred by barbarian.


Grimoire is  an error-free  language. There  are several  concepts which
interact to  create this, namely  structure, prose, well-  and malformed
structure, and validity.


A parser for Grimoire which doesn't  succeed without error for any utf-8
string is not valid.

## Structure

This is a top-down look at Grimoire's proposed syntax.

### Encoding

Grimoire is defined in terms of utf-8.


The core syntax is defined in terms of the reachable keys on a US keyboard.
This tradition is firmly entrenched in the mid teens, and I have no
designs on budging that at present. The miser in me likes that they're
a byte each. The lawyer in me insists that this isn't ASCII, which is a
seven-bit legacy encoding. All aspects of utf-8 are equally meaningful.


We aren't at all afraid to use Unicode characters to display aspects
of the runtime. In fact we favor this, as it marks those operations
as distinctive. Most people can't type ⦿ without effort (I can't)
and it's easy to recognize as a folded drawer once you've seen a couple.


Grimoire is case sensitive and uses lower-snake-case for built-in English
phrases. There is a convention (see classes) that uses capitalization of
user words to affect semantics. This may be overridden with other rules
for languages that lack the majuscule-miniscule distinction.


I want Grimoire to have correct Unicode handling, for some value of
correct. It can't be considered 1.0 without this.


Bidirectional handling in a context that's indentation sensitive is
an example of something subtle. Grimoire uses indentation in various
ways, so here's the rule:


Any newline that has a reversed direction ends indentation. So if
you are going ltr, issue an rtl marker, and a newline, your indentation
level is zero. If you reverse direction twice in a line, you keep
your indentation level. Three times, you lose it.


I'd love to get a Hebrew and/or Arabic fluent hacker on the project
early, to make sure this works correctly.


Another thing I want to get right is equivalence. If you have a
variable called "Glück" the compiler shouldn't complain if it's
rendered in either of the valid ways. For some sequences that's
"any of the valid ways". If we normalized your prose, you might
have problems later, so we don't want to solve it that way.

#### Internationalization

All parts of Grimoire defined in English will be namespaced
as =en:/=, and loaded by default. Other languages will be added
when there is a fluent maintainer available.


Note  that  many  words  aren't  truly English.  Notably  the  names  of
programming languages are  the same in all human languages.   A tag like
=#author= can be namespaced =#fr:/auteur= and will be, but =#!python= is not
in the =en:/= namespace.

### Prose and Structure

The major distinction Grimoire draws is between prose and structure.


Prose is the default parsing state. It is far from unstructured from the
runtime  perspective. Although  this needn't  be embedded  in the  parse
tree,  Grimoire   understands  concepts   such  as   paragraphs,  words,
punctuation,  capital letters,  languages, and  anything else  proper to
prose.


I refer to human languages, but Grimoire understands programming languages
also. In principle, all of them, it shouldn't be harder to add them than
it is to call them from shell, though getting a runtime rigged up to
another runtime always calls for some finesse to derive a good experience.


"Programming languages" is overly specific. Grimoire draws a distinction
between prose and structure. Blocks may contain either, or both.


Something that's nice about a language build on a prose/structure
relationship is that it can be error free. Anything *grym* can't build into
a structure is just prose.


Markdown has this property. Sometimes you run into crappy parsers which
build errors into Markdown, which is just obnoxious. If you [[http://daringfireball.net/projects/markdown/syntax][RTFM]],
you'll find the word "error" once. Helpfully explaining how Markdown
keeps you from making one.


We do what we can to make the document look the same as it is
in fact structured. Syntax highlighting handles the edge cases.

### Ownership

The basic structural relationship in Grimoire is ownership.


Root elements of a heirarchy own their children, blocks own
lines that refer to that block. Indentation has a subtle but
regular interaction with ownership; it does what you expect.


Edge cases are resolved using the cling rule.

#### The Cling Rule

The cling rule specifies that a group 'clings' to another group when
it is closer to that group than the other group. Ties resolve down.


This should make it intuitive to group elements that aren't grouping the
way you expect: put in whitespace until the block is visually distinguished
from the surroundings.


Cling applies between blocks which are at the same level of ownership.
Ownership has precedence over cling: all blocks underneath e.g. a header
line are owned by that line, newlines notwithstanding.


Note that indentation of e.g. lists invokes the cling rule within the
indentation level.


| x | y | z |



someprose on a block

Tags the table, but

| x | y | z |



someprose on a block

Tags the block.


Even clings are resolved forwards:

| x | y | z |


someprose on a block

Tags  the prose  block. The first and last examples should

be considered bad style.

### Whitespace, Lines, and Indentation.

Grimoire is a structured document format. There are semantics associated
with every character we encode.

#### Whitespace

Whitespace is either the space or newline character. Returns are removed,
tabs resolved to two spaces by the formatter, the latter is warned against.


Most of the token-like categories we refer to must be surrounded by
whitespace. Newlines have semantics more often than they do not.


Unicode actually contains quite a number of whitespace characters. They are
all treated as a single ordinary space. If that space is semantically meaningful,
as in the space between =*** A Headline=, it is filtered into an ordinary space.
Otherwise it's considered prose, the only filtration prose receives is tab->space
conversion.


Grimoire mercilessly enforces tab-space conversion, even on your code blocks.
I will cling to this tenet as long as I can, the tab character needs to die,
the world has decided, that key is special and shouldn't insert a special
dropping that looks like n spaces.


*make*? Outta my face with make. Yes, we'll have a make syntax, yes, it will
put the tabs back in.

#### Lines

When we refer to the beginning of a line, this allows for spaces before the
reference point. We call the absolute beginning of a line the first
position.

#### Indentation

Grimoire is an indentation-aware language. Most kinds of block can be
arcically[fn:1] ordered by means of indentation.


Indentation follows [[http://nim-lang.org/manual.html#indentation][Nim rules]].


[fn:1] There's nothing sacred about ordered subrules, and if we're making up
a new word, let's drop the silent h. Webster was a cool guy.
### Order of Recognition

Starting from the neutral context, which is always at a newline, Grimoire
tries to make one of its initializing special forms. Failing that, it will
begin a prose block.


If there is whitespace, it affects indentation level in indicated ways.
They will not directly affect the semantics of the following form, that is,
these rules apply after any potentially block-ending newline, apart from
spaces that may be found between the newline and the character.


At present,  =*=, =#=,  =|=, =-=,  , =~=,  =@=, =:=  and ={=  all create
special  contexts.  A  special  context  creates a  block  in a  context
specific way.


Blocks have a left associativity which can be recursive.

### Blocks

Grimoire is oriented around blocks.


Blocks are at least one line long,  all restarts are on a new line.  Any
syntactic structure smaller than a block we call an element.


Some types of blocks nest.  A document is a single  block.  There may be
other semantic units such as directories, I'd think a language that uses
strict  nested heirarchy  as powerfully  as Grimoire  could dictate  the
semantics of a file system, but that's currently out of scope.


Indentation is relevant to some  kinds of blocks. In general, whitespace
matters quite a  bit in a Grimoire  document. We keep some  of the warts
out because the tab character is  illegal, and there will be a mandatory
formatter, =grym  fmt= if  you will, that  does everything  from turning
=**bold**=  into =*bold*=  (because the  extra stars  weren't used),  to
newline stripping, and so on.  This is normally applied incrementally by
the runtime editing environment.


Indentation is human  readable and, with some care, a  computer may come
to the  same conclusions a  human would. I'm  still wary of  Python, but
there's no good  reason, unless the headache of most  Python not working
correctly  on my  computer, for  reasons I  can't track  down that  seem
related to  there being two languages  invoked as 'python', counts  as a
good reason.

## Syntax

Now that we've established the basic constraints, let's
start our recursive descent into the parse.

### Headers

Grimoire is arcically constrained by structure groups,
called headers.


These start on a new line and begin with any number of  =*=. These must
be followed by a space mark to be valid. Contra Babel, you may
have a content-free header line, provided a space is found before the
newline.


In weaves and the like, headers represent document structure. Their
intention is structural: they support the same syntax as lists,
but the user is expected to use lists for list purposes. Putting
[TODO] in a header line should mean you have a document-specific
task to perform in that block.


Contra Babel, you may put spaces before the beginning of a header line.


The semantics of header lines are entirely determined by
the number of stars.


If you write

# Top Header
## Second Header
The rest of the header lines are reformatted with the same
degree of indentation. Note that you still must use the
requisite number of asterisks, this is a syntax sugar giving
a more natural look to collapsed header structures. Prose blocks
needn't be indented to match.

Collapsed headers look like this:

# Top Header ▼
## Second Header ►
This indicates that the top header is partially unfolded
and that the second header is completely folded. Deleting
into the mark unfolds.

Within sections, ordinary prose rules apply. A section

may contain any number of blocks.


"begins" means first non-whitespace character. Indentation levels are tracked by
Nim rules, obviously a Grimoire document can contain no tab marks
and if any wander in they become four spaces.


Contra other block forms, tags may not precede a headline.

#### Header Lines

Anything after a run of =*= and a space, and before a newline, is
a header line.


Header lines and list lines are structured identically. If I discover
a necessary exception, I'll note it.


That structure is discussed under [[*Lists][lists]].

### Prose blocks

A prose block is preceded and followed by a single newline. Extraneous
whitespace on the bare line is filtered.


Prose blocks may not be indented in a semantically meaningful way.


prose


    prose


        prose


is not nested, nor will formatter correct it.

### Prose markup

Prose markup rules apply in any prose contexts, not just for prose blocks.


We mark =*bold*=, =/italic/=, =_underline_=, =~strikethrough~=, 
and =​=literal=​=, using the indicated marks. They must not be separated 
with whitespace from the connecting prose. Any number may be used and matched,
whitespace is allowed, so =**bold math: 4 * 5**= will highlight
correctly.


There is also [[*Inline%20Code][Inline Code]], which is formatted =`code`=.


These all follow the prose markup rule: any number of the starting
character matches the same number of the ending character in the
document string.


We make subscripts mildly annoying, =sub__script= and =super^^script=, 
to avoid colliding the former with =snake_case=. That's a lot of ways 
to parse the =_= character...


In general, prose is more 'active'  than in Babel. There are more things
you can't say without triggering a parsed data structure.  Due to quirks
of Org  involving string  escaping, =`\"\"`=  can't be  literally quoted
without repercussions. Check  out the source if you enjoy pounding your
head in frustration at the nastiness of escaped strings.


Let's just use a code block:

""literal string *containing* @some #things:of-various-sorts { that would be parsed }""

So literal strings start with a minimum of two, rather than a minimum of

one, of the " character. This is pretty-printed in edit mode as =‟literal”=,
but such a string does *not* create escaping, we rely on semantic highlighting
to make the distinction clear.


Any number of """" collapse into one set of such balanced quites.


In the woven documentation, no quotation marks appear, just the string.

#### Latex

For further markup purposes in a prose context, we escape to LaTeX. The
syntax is =`\latex`=, where the backslash causes us to use LaTeX instead
of Lua. Our TeX backend is LuaTeX, giving arbitrary levels of control from
within a Grimoire-native language.

### Comments

In a structure context, you may place line comments. These begin with =--=
and continue to the end of a line.


Commenting out a header line, or anything else, causes it to be ignored.
It does *not* result in any subdata being commented out, though it will
in the case of a headline change the ownership of the owned blocks.


The  tag =#comment=  in a  valid tag  content position  marks the  owned
region  of  the tagged  block  as  a  comment.  Nothing within  will  be
evaluated or exported, though it will be parsed.

### Marks

Marks provide global semantic categories for Grimoire. They may appear
anywhere, including a prose context, whitespace is required on both sides.


We use  a couple kinds  of marks:  =@names= name things,  and =#tags=
categorize them. Tags are semantics, while names are nominal. 


Tags that  are boundaries are  paired as  =#tag= and =#/tag=,  plus some
light sugaring. Names are never bounded


Marks in the first position own the following line. If there is indentation
below that line, they own that too. This doesn't affect the associativity.


Marks may be namespaced, as =@name.subname= or =#tag.sub-tag.sub-tag=.


If  you  require   further  namespacing,  =@many/levels/java.class=  and
=#mojo/nation.space/station=  is your  friend. Codices (that is, projects
following the bridge conventions for organization) will use namespacing
in a consistent way. 


As I continue to muse on it, I  can think of no reason why marks couldn't follow
URI syntax,  or at  least mirror  it closely.  Chaining marks  is not  valid, so
=@named@example.com= could be a valid name. 


This would mean we could say something like =@file://~/usr/blah=.


Or =#!/usr/bin/perl/=...


Yes. This  is a good idea.  Let's do this.  It doesn't displace [[*Links][link]]  syntax, it
enhances it. A  URI [[http://en.wikipedia.org/wiki/URI_scheme#Generic_syntax][may not begin with  a slash]] so this is  parse-clean for tags
and names both. Tags aren't intended to  be user extensible in the narrow sense,
but uniformity is a virtue.


I don't know why you might want to stick a query in a tag. It's not my
place to know. We just slap a parser on that puppy and continue.


Implication: The hash or at should be syntax highlighted a different color
from the tag. I'd say hash and at get the same color, with categories and
symbols getting different ones.


Apparently, [[http://blog.nig.gl/post/48802013022/although-parentheses-are-technically-allowed-in][parentheses are allowed in URLs]], but follow the link, they
suck and you should never use them. They play badly with our calling
convention for named structures, and aren't allowed in our schema.


It's not a real URI anyway, or it can be but it's also allowed to be a legal
fragment without the handle. In our case the assumed handle is =grimoire://=?


Not a real URI. But an acceptable fake one.


The actual rule for a mark is that it begins with =@= or =#= and is surrounded
by whitespace. Internal parsing of the mark is part of recognition, anything 
not recognized is subsequently ignored. It's still considered a mark for e.g. 
weaving purposes. 



#### Plural Hashtags

In some cases, such as =#formula= and =#formulas=, a tag may have a
singular or plural form. These are equivalent from the runtimes perspective.


The same concept applies to pairs such as =#export= and =#exports=, though
the linguistic distinction is not that of plurality.

### Classes

Tags are for Grimoire. A category provides runtime semantics,
cooperating with structure groups to provide the API. Names
play the role of a value in languages which provide a
value-variable distinction: every name within a documents reachable
namespace must be globally unique.


Specifically names are globally hyperstatic: any redefinition affects
the referent from the moment the parser receives it forward. Redefinitions
are warned against and have no utility, don't do it.


Classes are roughly equivalent to categories/hashtags, but
for the user. They have a light semantics similar to their
function in Org.


A class is defined as =:Class:= or =:class:= including
=:several:Classes:chained:=.


A capital letter means the class inherits onto all subgroups of the block,
a miniscule means the class is associated with the indentation level it is
found within.


You know you're programming a computer when class and category have distinct
semantics. At least there are no objects, and only two primitive types,
structure and prose.

### Links

There's nothing at all wrong with the syntax or behavior of Babel links.


Which look like this:

[[http://example.com][Hello Example]]

With various wrinkles, all supported.


We won't support legacy forms of footnoting, such as =[1]=. This applies
to legacy versions of table formulas and list syntax also.


In Grimoire  there's one way  to do things.  At least, we  avoid variant
syntax with identical semantics.

### Cookies

List line contexts (header lines and list lines) may have cookies. A
cookie looks like =[ ]=, it must have contents and a space on both sides.


Cookies are valid after the symbol that defines the list line, but before
anything else. They are also valid at the end of a list line, in which
case they are preceded by a space and followed by a newline.


Cookies are distinctive in that they may only be applied to list lines.
Most other token-like groups, specifically tags, classes, and inline drawers,
may be embedded into all prose contexts excepting literal strings.


Cookies are used similarly to cookies in Org, but with consistent semantics.
A simple cookie set is "X" and " ", the user cycles through them. TODO and
DONE are another option.


I don't want cookies to turn into lightweight tables. Still, saying to
the user "you may have precisely two cookies a line" is restrictive.
It's not a violation of the [[http://c2.com/cgi/wiki?TwoIsAnImpossibleNumber]["Two is an Impossible Number"]] principle,
because they're head and tail. I think this is ugly:

 - [ ] [ ] [ ] Oh god boxes [ ] [ ] [ ]

And whatever you're trying to model there should be a table.


You can stick a table in a list. I don't know if I mentioned, it's kind
of an obvious thing, I'll write a unit for it at some point.


Still. I can see a case for two on the left. Once you allow two, you allow
n, without excellent reason.


[[*Radio%20cookies][Radio cookies]] must be the leftmost cookie on a line, only one is of course allowed.
I could allow a single-line short form multi-radio-button interface but what
is it, a fancy text slider for some value? No. Any number of ordinary cookies
can follow. Knock yourself out.


Anything more than a couple and one should consider a class or a table.
Handrolling data structures is perverse in a markup language, and I'm
still tempted to forbid it.


I don't like distinctions without difference. A cookie at the end of a
line is filled by Grimoire, not the user. This mirrors Org's use, which is
to display either a percent or a n/m marker for completion of list items.
The user seeds the cookie, in these cases with =%= or =/=, and the runtime
does the rest.


Adding more than one such structure to the tail list would complicate the
reference syntax, which I haven't designed, and again, it's just not necessary.
Grimoire can fill in any data structure, "n-dimensional end cookie array"
isn't one we have a compelling need for.


Cookies could interact badly with link syntax. I don't think a [bare box]
qualifies as a link in Org, clearly it doesn't, we can follow that notion
and disallow "[]" as a filling for cookies.


I also think they should be allowed in table cells, which have their own
context which is mostly handwaved right now but is prose++.

#### Radio cookies

We have one 'weird cookie'. A radio cookie, which looks like =( )=,
must be present at the head position of list line contexts. All
list lines at the same level of indentation must have one, if one does.


Only one is selected at any given time. These would be awkward to add
into tables, to little gain.


This comes perilously close to pushing us into the realm of error.
The formatter adds buttons to an entire subtree if one member has it,
and if more than one is ticked off, it warns if possible or removes
all but the first mark encountered. If none are present the first
option is selected.


The runtime will not normally build an invalid radio list, but
Grimoire must import plain text.

### Drawers

A drawer is a block that's hidden by default. The computer sees it,
the user sees ⦿, or a similar rune.

:[a-drawer]:
contents
:/[a-drawer]:

This closes to a single Unicode character, such as ⦿, which can't be deleted

without opening it. Deleting into an ordinary fold marker opens the fold,
deleting towards a drawer marker skips past it.


=a-drawer=  is  a type,  not  a  name, something  like  =weave=  or =tangle=  in
practice. This may or  may not be supported with a =#weave=  tag. 


I'm not entirely sure how to interact names with drawers, perhaps like this:

:[a-drawer]:
- some contents
  - in list form
  - etc.
[:/a-drawer]:


Under the  hood, a  drawer is just  a chunked  block owned by  a tag.  An editor

should keep it closed unless it's  open, those are the only additional semantics
associated.


This lets master wizards embed unobtrusive magic into documents for apprentice
wizards to spell with.


An inline drawer looks like =:[]():=.  As usual when we say "inline" it
can be as long as you want. Being anonymous, because untagged, the only semantics
of such a drawer are to hide the contents in source mode. 

### Runes

After drawers is as good a place to put runes as any.


Runes are characters drawn from the pictographic zones of Unicode,
which describe semantic activity within a document.


Contra Org, when we have something like the aformentioned:

# Top Header ▼
## Second Header ►
or the dot which represents a drawer =⦿=, the Unicode character
is actually present in the document.

This tidily preserves the state indicated by the sigil through

any transformation we may take. If you load up last Wednesday's
version of something, it will be in last Wednesday's fold state.


This lets us have richer folding semantics, like "don't unfold when
cycling". It lets us have richer drawer semantics, and so on.


We will reserve a number of characters for this purpose, at least


| ▼ |  ► | ⦿ |
    |


It's legal to delete runes, like anything else. It's also legal to
insert them manually. Neither of these paradigms is typical;
deleting into a rune may or may not cause it to disappear in
normal edit mode.


Runes, like absolutely everything in Grimoire, are prose if encountered
in a context where they aren't valid structure.


We will most likely reuse runes inside cookies, though it's just as valid
and quite typical to use normal letters or words.

### Lists

Something that irks me about Org is basically historic. It was a TODO
list first, and became a heiarchical document editor later. As a result,
the functions that let you tag, track, and so on, are in the wrong place;
an Org file has to choose whether or not it's a task list or a document,
which doesn't fit the metalanguage paradigm cleanly.


A list looks like this:

- a list
  - can have some data
  - key :: value
  - [ ] boolean
  - multiple choice #relevant-elsewhere
    - ( ) A
    - (*) B
    - ( ) C
  - Can contain ordered Lists
    1. Such as this
    2. And this

Similar enough to Org, though `+` and `*` aren't equivalent options,

and we have radio buttons.


We also have whitespace lists:

~ a whitespace list
   has data
   organized by indentation:
     the colon is prose
     [ ] [todo] checkboxes :fred:
   also radio buttons
     (*) as you might expect
   multiple lines may be spanned \
   by C-style backslash newlines,\
     level is the same as long as \
  you keep escaping, though this is\
  confusing.
   this is the next item
   you can number them:
     1. apple
     2. persimmon
     3. mangosteen

and we're done.

### Embedded Data

Anything found in prose between ={= and =}= is EDN. Note that the
outermost pair of curlies denotes a boundary. ={ foo }= is the symbol
foo, ={ foo bar }= is the symbol *foo* and the symbol *bar*, ={{foo bar}}= is
a map with key *foo* and value *bar*.


To quote the [[https://github.com/edn-format/edn][spec]], "There is no enclosing element at the top level". The
braces mark the boundaries of the data region.


There is a mapping between lists and EDN, the basics of which will be clear
to the astute reader. The non-basics are unclear to the author as well.


Unresolved: may data be inlined into prose? What would that even mean?
slap some colors on it in the document? If we want to provide a 'this is
code but not for interpretation' mark, we will, it won't be EDN specific.
Inlining colorized code is not high on my todo list.


I don't think you can. Embeds are down here with lists and
tables in 'things you can't inline', for now.

### Tables

The way tables work in Babel is fine and needs little polish. Any modest
improvements we make will be in the face of considerable experience.


For example, I expect there's a way to make multiple literal rows serve
as a single row in existing Org, but I don't know what it is. I'll be
playing around a lot in the coming weeks, I hope.


Composability being an overarching goal, we can embed anything in a table
that we would put elsewhere.


Looks something like this:

  | a table           | very simple         |
  |-------------------+---------------------|
  | some rows         | with *bold* stuff   |
  | ""literal stuff"" | etc.                |
  | 23                | This gets filled in |


Another option would be a formula list:

  | a table           | very simple         |
  |-------------------+---------------------|
  | some rows         | with *bold* stuff   |
  | ""literal stuff"" | $23 :expenses:      |
  | 23                | This gets filled in |
   - [X] @3$2 :: @on-formula
   - [ ] @1$1 :: @off-formula

This is a point for Grimoire I dare say.


A subtle point of parsing I'm not sure is correct is =#formulas -=
or =- #formulas=. I feel like by normal associativity the latter
attaches the tag to the list, then nothing to the tag,
since the rule is a tag preceded only by whitespace owns the line
after it and indentations below it. The tag doesn't affect the indentation level
of the =-=, which could be confusing but won't be.


We should be able to tag tables like this:

             |-----------+-----------|
             |           |           |



Note the intermediate indentation of the =#formulas:= category tag.

Totally okay in this context, doesn't trigger Nim rules because the table
associates to the tag anyway.


This gives us a nice left gutter which I propose we can use in various ways.


This section can get much longer. Generalizing how tables work is incredibly
powerful. My dream is to embed APL into Grimoire. Give me an excuse to
finally learn it!

### Clocks

I think timestamps are just a drawer you put a timestamp in.


That drawer can collapse and look like ⏱.


Or we can collapse it into something from the set containing 🕞.


Which normal Emacs doesn't display. I really need to go Japanese soon.


But it would be just adorable to have a little clock representing the timestamp.
Emoji are quirky but the set contains useful icons, and it's Unicode.
Grimoire supports Unicode.

### Code

The place where it all comes together.


Grimoire has a servant language, Lua by default, but this
is of course configurable. Eventually we'll write Clu,
it's a race to see which project is finished first but they
have common dependencies, surprise, surprise.


Code and data are yin and yang in Grimoire. Code embedded in
documents is executed in various ways and times; comments within
code blocks are themselves in Grimoire data format, and so on.


Given a single language Grimoire text, we can perform a mechanical
figure-ground reversal, such that data blocks become comments and
code blocks become live. We have many more sophisticated weave and
tangle operations, but this is a designed-in property that will prove
handy: sometimes you want to take code, org it up, and then flip it
into a literate context. Upgrade path for existing codebases.


#### Inline Code

Inline code is written =`4 + 5`=. It executes in something similar to
:function mode in Babel, the call is as though it were wrapped in a function
call that looks like:

return tostring((function() return
   4 + 5
end)())

With the difference that the inline servant language is run in a session mode by default,

maintaining state between calls.


Anything named exists as a data structure in the helper language. This makes it easy to
refer to a block that contains a self-reference, so these are stored in a cycle-safe way.

#### Code Blocks

The =`inline`= syntax works like the rest, you may use any number of backticks to enclose a form.


Something like:

```
-- some code

```

is just another inline block, it's evaluated and expanded in-place into the weave, if it's named,

it is evaluated when referenced. This:


-- some code
```

is a named, *prose* block, which contains inline code.


Separated code blocks use special tags:

```lua
-- some lua code
```

The =!= and =/= characters may be multiplied if multiple levels of

nesting apply. As indeed they might in a Grimoire code block.


We need a good runtime. Playing the Inception game
with Grimoire should be an amusing headache, not a dog-slow
system killer.


They may be named like anything else:

```lua
-- some lua code
```
```lua
-- some lua code
```
```lua
return 4 + 5
```


-- equivalent:

```lua
return 4 + 5
```


Note the =#/lua()= form, which calls the code block, and the =#->= tag, which

marks an anonymous result. =#@nine->= is the automatically generated tag for
the return value of the block named =@nine=, adding =@nine()= to a prose block will
add the number 9 to the weave at that location. *bridge* will either display the result,
the call, or both, configurably, when editing the source, with syntax-highlighting to 
enforce the distinction. 


Code blocks may be indented as any other blocks, with the associated owership
rules. Code blocks so indented have a logical start equal to their level of
indentation, which is to say the program being called will not see indentation
that is proper to the Grimoire document.


Code blocks may be placed inside lists, as tables may be, but may not be
explicitly placed inside tables.


You may insert the result of a named code block in the data context
by simply saying =@a-named-block()=. If there are variables, you may pass
them, =@a-named-block(23, true)= or if you wish, by name:


The values will be inserted as per an inline reference.


Within a formula applied to a table, it is valid to use the description
syntax for a variable to supply an argument to a function.


There will be further syntax involved in building up the line that
begins a code block. It's considered good form to assign complex
code block headers into distinct tags, and use those, rather than
being explicit and repeating yourself or hiding file-local defaults
in drawers.


So we prefer something like

```lua
-- some lua code
```
# Runtime

Here, we begin to explore the interactions Grimoire is capable of.

## Literate or Live?

Babel is descended from the tradition of [[http://en.wikipedia.org/wiki/Literate_programming][literate programming]], and
Grimoire inherits this from Babel.


Grimoire is capable of producing code and documentation in the
classic literate style. This is not the aim of Grimoire: it is
a metalanguage, for working with prose, data, and code in an
integrated fashion.


What a compiler is to a REPL, literate programming is to living
documents.


In a literate programming context, we have source, which integrates
code and documentation. The source is then woven into documentation,
and tangled into code. Both are compiled, one is printed, one is run.


The word 'printed' sounds somewhat archaic, no? The number of tools
Donald Knuth had to write just to write the tools he wanted to write,
and tool the writings he wanted to tool, is simply staggering.


Traces of that legacy remain in Grimoire. Like Babel, we allow for
LaTeX embedding, with the sugar =`\latex`=. Starting Lua code with
a backslash is illegal, starting Clu code with a backslash is also
illegal.


For a Grimoire document to be printed, realistically, in today's world,
it will be translated to LaTeX, hence to PDF, sent off to a print
on demand company, and drop shipped. Some documents may in fact
make this journey, because why not? We aren't oriented around it.


The basic flow in a Grimoire context is one of excursion and return.
We have tangling and weaving, but also unraveling, where actions taken
within the weave or tangle are integrated back into the source document.

### Unraveling the Mystery

What's unraveling? When I picture Donald Knuth writing literate code,
I picture him with a notebook, writing free-flowing algorithms in a
fashion he refined his entire career. I imagine him carefully transcribing
into Web, running the compiler, going for a stroll around the Stanford
campus, and examining the changes upon his return.


On the days, and they did happen, when his program was in a state of error,
I picture him returning to his notebook first. While thinking. Perhaps
playing the organ for an hour or two, to relax. He would then correct the
notebook, then the code, then the program, which would be correct now,
most of the time.


I'm making that all up. But I'd wager I'm not far off the mark. We
don't work like that and most of us can't.


A tangle is named that because the mapping between it and the source
can be non-trivial. It's quite possible to make it undecidable what to
do with edits to the tangle. it's also possible to move edits from the tangle
back into the source, in most cases, if we structure things well.


Donald Knuth was unable to print a book that would alter his code. I'm
sure he'd have been delighted to have the ability. Our weaves can easily
be living documents, through in-browser and server side empowerment.
Those changes, too, should make it back into the source.


Ultimately I imagine many people will prefer to edit and run their
Grimoire documents entirely from a weave that provides a bit of the
ol' WYSIWYG to the experience. Well and good for them, I have my own
view of Heaven, and it isn't Heaven if we don't all fit.

## Source, Tangle and Weave

These classic concepts from literate programming are central to
the Grimoire paradigm.


In Grimoire, something like a PDF is not a true weave. It is a product;
much like an image or data derived from a simulation, it is regenerated
when necessary but has no further connection to the Grimoire environment.


Our first section discusses the format of Grimoire source code. Like Babel,
unlike Web and descendants, it is self-tangling. Grimoire will be tightly
integrated and purpose-built for this task, operating at a REPL+ level.


We still wish to use it to compile programs written in appropriate languages.
These languages needn't be educated in the ways of Grimoire, imposing this
requirement would be so onerous as to block adoption.

### Unraveling the Tangle

Babel offers limited facilities for working within source blocks. What it
doesn't offer is the critical 'unravel' operation, which takes changes to
the tangle and integrates them back into the weave.


This is a partially-solved problem, with Babel able to put comment tags into
the source which allow Emacs to jump back into your actual source from
errors in the tangle.


This is just not good enough. For any number of reasons, we need to be able
to unravel. I'll cite one: Converting existing codebases over to literacy.
The first step is to recreate the existing program on a source-line-identical
level. The entire existing developer base is familiar with the program already
and isn't going to want to start editing a bunch of Grimoire. They can most
likely be induced to accept readable metadata, and that's it.


That's all we need. Code is in one of three categories: either it is a single
literal copy from source, it's one of several copies from source, or
it's generated code that's dependent on information in the source.


We incorporate all changes to the former automatically when we unravel.
Changes to a single version of multiple copies prompts user interaction: do
you want to embed the change as its own source block, propagate it to each
instance, or decline the merge? Changes to generated code are simply
forbidden. If one is doing generation on the code base, working from
the weave is the more comfortable approach.

### Backweaving

An analogous operation is backweaving.


A weave in Grimoire is an HTML/CSS/JS document. In other words, a program.
The weave is much closer akin to the source than any tangle. Any Grimoire
program can have a weave view, though it isn't necessary; many will have
no tangle at all, containing the functionality within Grimoire.


The weave may therefore be manipulated, and we need some way to reflect
those changes back into the source. This can't be automated in a general
way. What we're left with is an EDN protocol for exchanging information
to update the weave in cooperation with some server logic and git.


So, could you write the server logic for a site as a literate program,
push it to a server that tangles and weaves it, and use the source
and Grimoire/bridge as the sysadmin view? I bet you could, it might
even be fairly popular.

#### Zero-header tag

The special [[*Tags][tag]] =#*=, which is only meaningful at the top of a document,
 indicates a 'zero header'. This lets you use the one-star level as a
series within a single document.


The related tag =#meta*= must be followed by a space and any number of
stars. This indicates a meta-level for the entire under-tree, that
exists somewhere else. Further semantics may be provided.


This section belongs in some further API section.

##### TODO Move to API Section

