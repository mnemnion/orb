# Grimoire

Grimoire is a metalanguage for magic spells.

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

## Dependencies

We use [Penlight](https://github.com/stevedonovan/Penlight) for strict mode and some filesystem i/o. A copy is provided in `/lib`. 

Grimoire makes heavy use of [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/), which should be a part of any Lua installation.

## Luajit

Grimoire is written with an eye towards running in a Luajit environment, but also aims to be fully 5.2 compliant. No particular instructions for running on Luajit should be needed. Do note that Penlight and lpeg will need to be provided in compatible forms.