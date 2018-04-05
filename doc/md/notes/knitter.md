# Knitter


  In Dr. Knuth's vision of literate programming, the two paths from source
are called weaving and tangling.  In Grimoire, we weave, but also, knit. 


We do not practice to deceive, nor tangle when our web we weave.


The parser is coming together nicely, and we are actually within a day or 
so of being ready to start knitting.  A knitter which suffices to self-host 
grimoire and pegylator only really needs taglines and code blocks, both of
which we are supporting. Huzzah!


## Rationale

  The change of name goes deeper than aesthetics.  [[https://orgmode.org/worg/org-contrib/babel/][Babel]]
introduces a feedback loop between the enclosing code and the document itself,
a critical development.  We expect to extend this to the weave also, which is 
a browser view into the overall contents of the grimoire.


These interactive elements would be frustrating and error-prone to add without
the editing environment, parse engine, and efficient data structure to back
them.  By contrast, the pipelined approach to producing source code for 
subsequent compiliation is straightforward to implement, and provides the
foundation for writing pure C with some prayer of a good outcome. 


## Tag Engine

  All Grimmorian operations are driven by tag directives.  We have exactly
two types of tag, the `#hashtag` and the `@handle`.  The hashtag is for the
engine, and the handle for userspace. 


Hashtags handle any library that Grimoire expects to be able to load, user
contributed or core.  Thus `#import` is the base case of hashtag, bringing
a set of tags into the local namespace.


Failing to find a namespace must not be considered an error.  It will be 
warned against and no semantics will be associated with any tags so defined.


Grimoire, like any other language in existence, will have a global static
namespace.  We at least intend to offer a separation mark between handle and
name; emacs has done just fine without this, but it's easier on the eyes. 


Here we intend to stick to the tags we need to knit a self-hosting Grimoire. 


### #export

  This is a tag one might find in a header block for code, like so:
`#!lua  #export`.  


Found thus, without other attributes, the code block will be appended to
$name-of-file - '.org' + '.lua'.  Subsequent blocks will not need an
`#export` tag. 


Grimoire is somewhat snippy about code organization and will knit 
`org/anything.gm` into `src/anything.*` for as many languages as it
encounters.  While this will be configurable at some point, I don't need
or particularly want it to be, at least where the org/src genres are
concerned.


#### #export #addguards

 This will add a language-specific comment line before each line of 
knit source code.


Guards allow for low-stress editing of the knit documents, which can be
unraveled into the source with `grym unravel`, provided guards are in place.


#### #export «filename»

Exports to `filename`, and sets this as the default path to append code
blocks of that language. The `«` and `»` are literal, " is not a
substitute.


Note that a filename starting with `/` goes into `…/src/` by default. 


### #noexport

  This behaves as befits an antonym.  Subsequent blocks are `#noexport`
by default, these act as a toggle.


#### #noexport #this

  Interrupts export for one code block only. 


### #EOF, #eof

  Two tags of the same meaning.  Intended for the footer line of a code
block, they enforce an end-of-file.  This causes export to end as though
`#noexport` were used.  It is likely a synonym at first, but with possible
drift since `#noexport` might take arguments while `#EOF` will not.


Note that all-caps versions of most tags are simply ignored, EOF is an
acronym and `#eof` is the redundant synonym.


### #embed-doc-as-comment

  A top-level directive, this will cause the non-code portions of the
grimoire file to be exported as language-specific comments into the 
knit file.


Paired with `#addguards` this will result in two files of the same length.


### #knit

  Why don't we have this tag?  Knitting is a more general act than
simply concatenating code blocks. 


There is a history in a few languages, notably Coffeescript and Haskell,
of developing the simple 'linear literate' paradigm as a supported option,
then not really using it. 


Grimoire can and must grow into something greater than this. 


## Next steps

  That might even be enough tags to self-host. It's fairly close at least. 


I can and will write a simple unraveler which relies on a directive to
insert comments between appended blocks.  Since I'm not implementing any 
macro expansion at first, this is simple enough and will allow me to keep
working directly on the `.lua` files while keeping the `/org` documents
up to date.


This is better for the pipelined version, when we get to `femto` and
`bridge` we'll have an interactive environment which can provide code-only
views into the actual source document. 


It's an important tool for bringing existing projects over to Grimoire
format. 
