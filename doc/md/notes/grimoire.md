 #+title: Grimoire: a metalanguage for magic spells.# Introduction# Musings on Metasyntax## Constraints### Usable### Readable### Parsable## Structure### Encoding#### Internationalization### Prose and Structure### Ownership#### The Cling Rule#+begin_example#+end_example#+begin_example#tag#+end_example#+begin_example#tag#+end_example### Whitespace, Lines, and Indentation.#### Whitespace#### Lines#### Indentation### Order of Recognition### Blocks## Syntax### Headers  #+begin_example# Top Header## Second Header  #+end_example#+begin_example# Top Header ▼## Second Header ►#+end_example#### Header Lines#### Zero-header tag##### TODO Move to API Section### Prose blocks#+begin_example#+end_example### Prose markup#+BEGIN_EXAMPLE#### Latex### Comments### Marks#### Plural Hashtags### Classes### Links#+begin_example### Cookies#+begin_example#### Radio cookies### Drawers#+BEGIN_EXAMPLE#+begin_example### Runes#+begin_src# Top Header ▼## Second Header ►#+end_src### Lists#+BEGIN_EXAMPLE#+BEGIN_EXAMPLE#+END_EXAMPLE### Embedded Data### Tables#+begin_src org  #formulas {{ @2$2, @a-formula }}#+begin_src org#formulas -#+begin_src org    #formulas: etc...#+end_src### Clocks### Code#### Inline Code#+begin_src lua#### Code Blocks#+begin_example#+end_example#+begin_example#+end_example```lua
-- some lua code
```
#+end_example```lua
-- some lua code
```
```lua
-- some lua code
```
```lua
return 4 + 5
```
#@nine-> 9@nine```lua
return 4 + 5
```
#@nine-> 9#+end_example#+begin_example```lua
-- some lua code:
return 2 + 3
```
# Runtime## Literate or Live?### Unraveling the Mystery## Source, Tangle and Weave### Unraveling the Tangle### Backweaving