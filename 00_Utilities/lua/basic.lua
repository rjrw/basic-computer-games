#!/usr/bin/env lua

-- $Id: test.lua $

-- require"strict"    -- just to be pedantic

local m = require"lpeg";

if #arg ~= 1 then
   print("Usage: basic.lua <file>.bas");
   os.exit(1);
end
local file = assert(io.open(arg[1]));

local any = m.P(1);
local space = m.S" \t\n"^0;
local digit = m.R("09");
local lineno = digit^1;
local statement = m.P{
   lineno * space * any^0,
};

local count = 1;
for line in file:lines() do
   local mend = m.match(statement, line);
   if not mend then
      io.write("Syntax Error\n");
      io.write(line, "\n");
   elseif mend ~= #line+1 then
      io.write("Syntax Error\n");
      io.write(line, "\n");
      io.write(string.format("%*c^",mend-1," "));
   end
end
file:close();
