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
local integer = digit^1;
local varname = m.R("AZ")^1 * m.R("09")^0;
local floatvar = varname;
local lineno = digit^1;
local gotostatement = m.P {
   m.P("GO") * space * m.P("TO") * space * lineno * space
};
local gosubstatement = m.P {
   m.P("GO") * space * m.P("SUB") * space * lineno * space
};
local nextlist = m.P {
   ( floatvar * space * m.P"," * space)^0 * floatvar * space
};
local nextstatement = m.P {
   m.P("NEXT") * space * nextlist * space
      + m.P("NEXT")
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
local comparisonop = m.P {
   m.P("=") + m.P("<>") + m.P("<=") + m.P(">=") + m.P("<") + m.P(">")
};
local Sum = m.V"Sum";
local Product = m.V"Product"
local Unary = m.V"Unary";
local Value = m.V"Value";
local Or = m.V"Or";
local And = m.V"And";
local Not = m.V"Not";
local expr = m.P {
   "Sum";
   Sum = ( Product * space * m.R("+-") * space)^0 * Product * space,
   Product = ( Unary * space * m.R("*/") * space)^0 * Unary * space,
   Unary = m.R("+-")^-1 * Value,
   Value = integer + m.V"F" + m.P("(") * space * Sum * m.P(")"),
   F = m.V"E" + floatvar,
   -- Array access builtin call
   E = floatvar * space * m.P("(") * space * Sum * m.P(")")
};
local numericassignment = m.P {
   floatvar * space * m.P("=") * space * expr * space
};
local forstatement = m.P {
   m.P("FOR") * space * floatvar * space * m.P("=") * space * expr
      * space * m.P("TO") * space * expr * space *
      ( m.P("STEP") * space * expr * space )^-1
};
local comparison = m.P {
   expr * space * comparisonop * space * expr
};
local logicalexpr = m.P {
   "Or";
   Or = (And * space * m.P("OR") * space)^0 * And,
   And = (Not * space * m.P("AND") * space)^0 * Not,
   Not = (m.P("NOT") * space)^-1 *
      ( comparison
	   + m.P("(") * space * Or * space * m.P(")") )
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
   + gosubstatement
      + forstatement
      + nextstatement
      + ifstatement
      + endstatement
      + printstatement
      + numericassignment
      + returnstatement
}; 
local statementlist = m.P{
   (statement * m.P(":") * space )^0 * statement
};
local numbered = m.P{
   lineno * space * statementlist,
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
