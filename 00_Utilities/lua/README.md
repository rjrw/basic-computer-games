# Lua utilities for Basic Computer Games

## Basic interpreter and compiler

In this directory, `basic.lua` is an interpreter for Basic written in
Lua using the [`lpeg`](http://www.inf.puc-rio.br/~roberto/lpeg/) parser
library.  There is an initial capability to generate standalone output,
which is work-in-progress towards translation to more fluent Lua code,
inspired in part by
[plusFORT SPAG](https://polyhedron.com/?product=plusfort#sp).

This is intended primarily as a capability for code which has been found
to be correct using another interpreter, so error diagnostics are
currently somewhat limited.

To use it, two Lua support modules need to be installed on the system,
e.g. by some appropriate variant of
```
   $ luarocks install lpeg
```
and, to enable strict mode for debugging,
```
   $ luarocks install std.strict
```
The default mode is to act as an interpreter.

```
Usage: ./basic.lua [opts] <file>.bas
Options:
  --help    Print this help
  -d[file]  Dump (optimized) parser output as standalone Lua script
  -O        Run optimization phase on parser output before execution/dump
  -p        Parse source only, showing syntax errors and warnings
  -v        Enable verbose output of progress
```
The `-d` option dumps an executable Lua script after the parsing and
(optional) optimization phases, rather than executing it immediately.

The default output is as a number of data tables, with a loader
function which uses a run time library to guide execution.

The `-O` option activates optimizations which include translating
elements of the data tables into chunks of Lua code, which can then be
loaded and executed by Lua.  The intention is to translate
increasingly large parts of the tree into native Lua source chunks.

### Notes

The language grammar is split into two components, to allow a *match-time
capture* to implement rule caching for expressions.  This dramatically
reduces the time required to parse code with deeply nested parentheses.

### Known Bugs

  - Integer variables and arrays are not yet implemented
  - Error diagnostics are limited
  - Run-time diagnostics can be confusing, as they include both Basic and Lua script line numbers
