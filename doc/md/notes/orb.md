# Orb format## Metalanguage## Goals## Encoding#### Tabs## Prose and Structure## Ownership### Blocking#### The Cling Rule```orb
| x | y | z |

#tag


someprose on a block
```
```orb
| x | y | z |


#tag

someprose on a block
```
```orb
| x | y | z |

#tag

someprose on a block
```
## Structural elements### Headlines```peg
    headline = WS?  '*'+  ' '  prose  NL
```
### Tags and Taglines```peg
  hashtag = WS+  '#'  symbol
```
```peg
  hashline = WS?  '#'  symbol  ' '  prose  NL
  handleline = WS?  '@'  symbol  ' '  prose  NL
```
### List```peg
  listline-un = WS? '- ' prose NL
```
```peg
  listline-li = WS? digits '. ' prose NL
```
```orb
  - list entry
   prose directly under, bad style
```
```orb
  - list entry
    continues list entry
```
#### List Boxes```orb
  - [ ] #todo finish orb.orb
    - [X] Metalanguage
    - [X] Prose and Structure
    - [REVISE] Link
    - [ ] Code Block

  - Fruits
    - ( ) Bananas
    - (*) Coconuts
    - ( ) Grapes
```
#### Key/value pairs```orb
 - first key:
   - value : another value
   - 42 : the answer
```
### Code Block```orb
#!orb
*** Some Orb content
#/orb
```
```sh
#!/usr/bin/python

from future import bettertools
```
### Table```orb
| 2  | 4  | 6  | 8  |
| 10 | 12 | 14 | 16 |
```
```orb
| a  | b  | c  | d  |
~ 3  | 6  | 9  | 12 |
| 18 | 21 | 24 | 27 |
```
```orb
| cat, | chien,  | gato,    \
| hat  | chapeau | sombrero |
```
### Link### Categories### Drawer```orb
:[a-drawer]:
contents
:[a-drawer]:
```
