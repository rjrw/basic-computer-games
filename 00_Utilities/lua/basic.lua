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
local string_ = m.P("\"") * (any-m.P("\""))^0 * m.P("\"");
local varname = m.R("AZ")^1 * m.R("09")^0;
local floatvar = varname;
local lineno = digit^1;
local gotostatement = m.P {
   m.P("GO") * space * m.P("TO") * space * lineno * space
};
local nextstatement = m.P {
   m.P("NEXT") * space * floatvar * space
};
local endstatement = m.P {
   m.P("END") * space
};
local printexpr = m.P {
   string_ * space 
};
local printlist = m.P {
   (printexpr * space * (m.P(";")*space)^-1 )^0
};
local printstatement = m.P {
   m.P("PRINT") * space * printlist
};
local floatval = {
   floatvar * space * m.P("(") * space * digit^1 * space * m.P(")")
   + floatvar
};
local value = m.P {
   floatval +
      digit^1
};
local unary = m.P {
   m.R("+-")^-1 * value
};
local product = m.P {
   ( unary * space * m.R("*/") * space)^0 * unary * space
};
local sum = m.P {
   ( product * space * m.R("+-") * space)^0 * product * space
};
local expr = m.P {
   sum
};
local numericassignment = m.P {
   floatvar * space * m.P("=") * space * expr * space
};
local forstatement = m.P {
   m.P("FOR") * space * floatvar * space * m.P("=") * space * expr
      * space * m.P("TO") * space * expr * space *
      ( m.P("STEP") * space * expr * space )^-1
};
local comparisonop = m.P {
   m.P("=") + m.P("<>") + m.P("<=") + m.P(">=") + m.P("<") + m.P(">")
};
local logicalexpr = m.P {
   expr * space * comparisonop * space * expr
};
local ifstatement = m.P {
   m.P("IF") * space * logicalexpr * space *
      m.P("THEN") * space * lineno * space
};
local returnstatement = m.P {
   m.P("RETURN") * space
};
local statement = m.P {
   gotostatement
      + forstatement
      + nextstatement
      + ifstatement
      + endstatement
      + printstatement
      + numericassignment
      + returnstatement
}; 
local compoundstatement = m.P{
   (statement * m.P(":") * space )^0 * statement
};
local numbered = m.P{
   lineno * space * compoundstatement,
};

local count = 1;
for line in file:lines() do
   local mend = m.match(numbered, line);
   if not mend then
      io.write("Syntax Error\n");
      io.write(line, "\n");
   elseif mend ~= #line+1 then
      io.write("Syntax Error\n");
      io.write(line, "\n");
      io.write(string.rep(" ",mend-1).."^\n");
   end
end
file:close();
