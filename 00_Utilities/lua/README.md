# Lua utilities for BASIC Computer Games

## Lua BASIC interpreter and compiler

In this directory, `basic.lua` is an interpreter for Basic written in
Lua using the `lpeg` parser library.

To use it, two Lua support modules need to be installed on the system,
by some appropriate variant of
{
   luarocks install lpeg
   # To enable strict mode for debugging
   luarocks install std.strict
}

The default mode is to act as an interpreter.  The `-d` option dumps
the interpreter state before the code is executed, as a pure Lua
script.

The default output is in essence a simple data tree, with a loader
function which uses a run time library to guide execution.

The `-O` option activates optimizations which include translating
elements of this data tree into chunks of Lua code, which can then be
loaded and executed by Lua.  The intention is to translate
increasingly large parts of the tree into native Lua source chunks.
