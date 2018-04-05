# grym


  `grym` is the command-line utility for bootstrapping the Grimoire language.


It works in a reasonably-familiar, Unixey sort of way, as a command-line tool.


Unlike most such tools I produce, it doesn't take from `stdin` or write to
`stdout`.  Instead it will happily make major changes to your files, sweeping
entire subdirectories, by default.


Not unlike `git` in that singular respect, except it's harder to persuade `git`
to mangle things.  We'll include a few simple sanity checks. 


Like `git`, `grym` is mostly invoked with secondary commands.


# grym [a-z]+


### grym knit

  This generates `/src/` from `/org/`.


### grym weave

  This generates `/doc/` from `/org/`.


### grym unravel

  This regenerates `/org/` from `/src/`.


### grym invert

  This takes a directory called `/src/` and creates an `/org/` from it, as 
best it's able. 


This being a rough-and-ready kind of operation, if we find anything at all
in `/org/` before we start, we'll copy it over somewhere temporary. 


### grym init

  This checks for the codex directory structure and if it finds one writes a 
`.grym` file in the home directory.  This will almost certainly turn into a 
directory, the question is whether that `.git` style organization is under
`.bridge` or both that and `.grym`.


I want to give it a chance to just be a config file. 


## Considerations

  One of the early philosophical decisions in Grimoire: it will do things to
your source files, in-place.  The first example is filtering, also the first
step.


Any file that Grimoire opens will have tabs replaced with two space marks,
all trailing whitespace pruned, "\r" excised where encountered, and any
line consisting only of what Unicode considers spacemarks is replaced with "". 


The line between formatting and linting is blurry but in general Grimoire wants
things to be a certain way and isn't shy about making it so.  A rule like
two spaces to begin a sentence allows for trivial sentence-counting and 
navigation, and the number of phrases like "Dr." in the English language is 
finite.


Preceding each section with two blank lines, and starting the first 
paragraph with two spaces of indentation, gives a good flow to the document
which computers and humans can both follow.


Asking for the pure-prose content of a line to stretch no more than 77 
columns is a reasonable standard for reading monospaced text.  In nearly all
languages, two characters to begin a comment and one for leading whitespace
allows this convention to fit in the 80-column standard. 


To support this I intend to allow links to have newlines in them which are
filtered out during weaving.  Grimoire succeeds when it's readable by anyone
who speaks the language used in the document. 




