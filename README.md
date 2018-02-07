# Grimoire

Grimoire is a [metalanguage for magic spells](org/grimoire.org).

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

## Dependencies

We use [Penlight](https://github.com/stevedonovan/Penlight) for strict mode and some filesystem i/o. A copy is provided in `/lib`. 

Grimoire makes heavy use of [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/), which should be a part of any Lua installation.

## Incorporation

`pegylator` builds heavily on Philip Janda's work on [luaepnf](https://siffiejoe.github.io/lua-luaepnf/). Our modified version may be found [here](src/peg/epnf.lua). 

## Luajit

Grimoire is written with an eye towards running in a Luajit environment, but also aims to be fully 5.2 compliant. No particular instructions for running on Luajit should be needed. Do note that Penlight and lpeg will need to be provided in compatible forms.

## Current Behavior

This is a bootstrap sequence because I require the code-generation tools for **bridge**. 

Currently `grym` has a bunch of tooling, `pegylator`, which will be broken off into its own install. The next step is to implement [ownership](/org/grimoire.org#ownership).

The current [grammar](src/grymmyr.lua) is meant as a single-pass, all-in-one, fully-specified [PEG](https://en.wikipedia.org/wiki/Parsing_expression_grammar) for the language. 

This is the hard way to actually implement Grimoire, but a necessary part of the ultimate behavior of **barbarian**. 









