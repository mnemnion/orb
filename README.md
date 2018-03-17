# Grimoire

  Grimoire is a [metalanguage for magic spells](orb/notes/grimoire.org).

The source code can be found in the [orb directory](orb/), and a [viewable
Markdown weave](doc/md/) is also available for perusal. The 
[sorcery directory](src/) is generated and may be safely left well alone.


## Installation

  This edition of Grimoire is a pure Lua implementation. 

To run from the `/src` directory type:

```sh
export LUA_PATH="./?.lua;./?/?.lua;./lib/?.lua;./lib/?/?.lua;$LUA_PATH"
```

Then simply 

```sh
lua grym.lua
```

or interactively as you choose. 

As a convenience, this is provided as a [shell script](grym).


### Extras

  There is a [Sublime Text Package](etc/Grimoire.sublime-syntax) which
provides a smooth-enough experience editing our bootstrap orb files.

I'll keep maintaining it until we have a native editing environment.
Orb format is intended to be stable, so it should continue to suffice.

Pull requests with packages for other editors are welcome!


## Dependencies

  We use [Penlight](https://github.com/stevedonovan/Penlight) for strict mode
  and some filesystem i/o. A copy is provided in `/lib`. 

Grimoire makes good use of [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/),
which should be a part of any Lua installation.


## Incorporation

  `pegylator` builds heavily on Philip Janda's work on 
[luaepnf](https://siffiejoe.github.io/lua-luaepnf/). Our modified version may
be found [here](src/peg/epnf.lua). 


## Luajit

  Grimoire is written with an eye towards running in a Luajit environment, 
but also aims to be fully 5.2 compliant. No particular instructions for
running on Luajit should be needed. Do note that Penlight and lpeg will need
to be provided in compatible forms.


## Current Behavior

  This is a bootstrap sequence because I require the code-generation tools 
for **bridge**. 

`grym` will currently do precisely three things: `grym invert` will do nothing,
because it can mangle the `orb` directory and we don't want that. You can manually enable this ability in [orb/grym.orb](orb/grym.orb).

`grym knit` will knit through an `orb` directory to produce a `src` directory.
At present, this is alpha-quality, with a simple, one-to-one correspondence 
between orb file and sorcery file.  You may use any language so long as it is
Lua. 

`grym weave` will generate Markdown documentation of the orb files in the `doc/md` directory.  This provides headers, code blocks, and not much else.


### Next

  I need to write a Sublime package for working directly with orb files, then
will turn my attention to parsing within the prose and structure blocks for
awhile, to improve the markdown rendering.

In approximate order: 

- Links
- emphasis, italic, literal
- underline and strikethrough (no Markdown equivalent)

At that point, it will be time to focus on using the toolchain.  I'll brush up
`knit` a bit to line up sorcery code and code blocks, maybe add some guards
and a minimal `grym unravel`. 









