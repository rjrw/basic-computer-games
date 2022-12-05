#!/usr/bin/env lua

-- $Id: test.lua $

-- require"strict"    -- just to be pedantic

local m = require"lpeg";

if #arg ~= 1 then
   print("Usage: basic.lua <file>.bas");
   os.exit(1);
end
local file = assert(io.open(arg[1]));

local count = 1;
for line in file:lines() do
   io.write(string.format("%6d  ",count), line, "\n");
   count = count+1;
end
file:close();
