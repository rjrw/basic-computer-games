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
local stringvar = varname * m.P("$");
local anyvar = m.P { floatvar + stringvar };
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
local returnstatement = m.P {
   m.P("RETURN") * space
};
local stringexpr = m.V"stringexpr";
local stringassignment = m.V"stringassignment";
local printexpr = m.V"printexpr";
local printlist = m.V"printlist";
local printstatement = m.V"printstatement";
local inputstatement = m.V"inputstatement";
local inputlist = m.V"inputlist";
local inputitem = m.V"inputitem";

local comparisonop = m.P {
   m.P("=") + m.P("<>") + m.P("<=") + m.P(">=") + m.P("<") + m.P(">")
};
local stringcomparisonop = m.P {
   m.P("=") + m.P("<>")-- + m.P("<=") + m.P(">=") + m.P("<") + m.P(">")
};
local Sum = m.V"Sum";
local Product = m.V"Product"
local Unary = m.V"Unary";
local Value = m.V"Value";
local Or = m.V"Or";
local And = m.V"And";
local Not = m.V"Not";
local Statement = m.V"Statement";
local logicalexpr = m.V"logicalexpr"
local ifstatement = m.V"ifstatement";
local expr = m.V"expr";
local numericassignment = m.V"numericassignment";
local dimstatement = m.V"dimstatement";
local dimlist = m.V"dimlist";
local dimdef = m.V"dimdef";
local forstatement = m.V"forstatement"
local comparison = m.V"comparison";
local floatlval = m.V"floatlval";
local stringlval = m.V"stringlval";
local stringelement = m.V"stringelement";
local arg = m.V"arg";
local arglist = m.V"arglist";
local exprlist = m.V"exprlist";
local element = m.V"element";
local statement = m.V"statement";
local statementlist = m.V"statementlist";
local basicline = m.P {
   "line";
   statement =
   gotostatement + gosubstatement + forstatement + nextstatement
      + ifstatement + endstatement + printstatement + numericassignment
      + returnstatement + stringassignment + dimstatement + inputstatement,
   printstatement = m.P("PRINT") * space * printlist,
   stringlval = stringelement + stringvar,
   stringelement = stringvar * space * m.P("(") * space * exprlist * space * m.P(")"),
   stringassignment =
      m.P("LET")^-1 * space *
      stringlval * space * m.P("=") * space * stringexpr * space,
   stringexpr = string_ + stringvar,
   printexpr = stringexpr + expr,
   printlist = (printexpr * space * (m.P(";")*space)^-1 )^0,
   inputitem = stringlval + floatlval,
   inputlist = (inputitem * space * m.P(",")*space)^-1 * inputitem,
   inputstatement = m.P("INPUT") * space *
      (stringexpr * space * m.P(";") * space)^-1
      * inputlist,
   ifstatement = m.P("IF") * space * logicalexpr * space *
      m.P("THEN") * space * ( lineno * space + statementlist ),
   exprlist = ( expr * space * m.P(",") * space)^0 * expr,
   dimdef = anyvar * space * m.P("(") * space * exprlist * space * m.P(")"),
   dimlist = ( dimdef * space * m.P(",") * space)^0 * dimdef,
   dimstatement = m.P("DIM") * space * dimlist,
   logicalexpr = Or,
   Or = (And * space * m.P("OR") * space)^0 * And,
   And = (Not * space * m.P("AND") * space)^0 * Not,
   Not = (m.P("NOT") * space)^-1 *
      ( comparison
	   + m.P("(") * space * Or * space * m.P(")") ),
   comparison = expr * space * comparisonop * space * expr
      + stringexpr * space * stringcomparisonop * space * stringexpr,
   forstatement =
      m.P("FOR") * space * floatvar * space * m.P("=") * space * expr
      * space * m.P("TO") * space * expr * space *
      ( m.P("STEP") * space * expr * space )^-1,
   numericassignment =
      m.P("LET")^-1 * space *
      floatlval * space * m.P("=") * space * expr * space,
   expr = Sum,
   Sum = ( Product * space * m.S("+-") * space)^0 * Product * space,
   Product = ( Unary * space * m.S("*/") * space)^0 * Unary * space,
   Unary = m.S("+-")^-1 * Value,
   Value = integer + floatlval + m.P("(") * space * Sum * m.P(")"),
   floatlval = element + floatvar,
   -- Array access/function/builtin call
   arg = expr + logicalexpr + stringexpr,
   arglist = ( arg * space * m.P(",") * space)^0 * arg,
   element = floatvar * space * m.P("(") * space * exprlist * space * m.P(")"),
   statementlist = (statement * m.P(":") * space )^0 * statement,
   line = lineno * space * statementlist,
};

local count = 1;
for line in file:lines() do
   local mend = m.match(basicline, line);
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
