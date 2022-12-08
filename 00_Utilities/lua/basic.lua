#!/usr/bin/env lua

-- $Id: test.lua $

-- require"strict"    -- just to be pedantic

local m = require"lpeg";

-- Parse = 1, interpret = 2, compile = 3, compile & optimize = 4
local mode = 1; 

local narg = 1;
if narg < #arg and arg[narg] == "-i" then
   narg = narg+1;
   mode = 2;
end
if #arg ~= narg then
   print("Usage: basic.lua [opts] <file>.bas");
   os.exit(1);
end
local file = assert(io.open(arg[narg]));

local any = m.P(1);
local space = m.S" \t\n"^0;
local digit = m.R("09");
local string_ = m.P("\"") * m.C((any-m.P("\""))^0) * m.P("\"");
local integer = m.C(digit^1);
local varname = m.R("AZ")^1 * m.R("09")^0;
local floatvar = m.C(varname);
local stringvar = m.C(varname * m.P("$"));
local anyvar = m.P { floatvar + stringvar };
local lineno = m.C(digit^1);
local gotostatement = m.P {
   m.Cc("GOTO") * m.P("GO") * space * m.P("TO") * space * lineno * space
};
local gosubstatement = m.P {
   m.Cc("GOSUB") * m.P("GO") * space * m.P("SUB") * space * lineno * space
};
local nextlist = m.P {
   ( floatvar * space * m.P"," * space)^0 * floatvar * space
};
local nextstatement = m.P {
   m.C(m.P("NEXT")) * space * nextlist * space
      + m.C(m.P("NEXT"))
};
local endstatement = m.P {
   m.C(m.P("END")) * space
};
local returnstatement = m.P {
   m.C(m.P("RETURN")) * space
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
   m.C(m.P("=") + m.P("<>") + m.P("<=") + m.P(">=") + m.P("<") + m.P(">"))
};
local stringcomparisonop = m.P {
   m.C(m.P("=") + m.P("<>"))
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
   printstatement = m.Ct(m.C(m.P("PRINT")) * space * m.Ct(printlist)),
   stringlval = stringelement + stringvar,
   stringelement = stringvar * space * m.P("(") * space * exprlist * space * m.P(")"),
   stringassignment =
      m.Cc("LET") * m.P("LET")^-1 * space *
      stringlval * space * m.P("=") * space * stringexpr * space,
   stringexpr = string_ + stringvar,
   printexpr = stringexpr + expr,
   printlist = (printexpr * space * m.C((m.S(";,")*space))^-1 )^0,
   inputitem = stringlval + floatlval,
   inputlist = (inputitem * space * m.P(",")*space)^-1 * inputitem,
   inputstatement = m.C(m.P("INPUT")) * space *
      (stringexpr * space * m.P(";") * space)^-1
      * inputlist,
   ifstatement = m.C(m.P("IF")) * space * logicalexpr * space *
      m.P("THEN") * space * ( lineno * space + statementlist ),
   exprlist = m.Ct(( expr * space * m.P(",") * space)^0 * expr),
   dimdef = anyvar * space * m.P("(") * space * exprlist * space * m.P(")"),
   dimlist = ( dimdef * space * m.P(",") * space)^0 * dimdef,
   dimstatement = m.C(m.P("DIM")) * space * dimlist,
   logicalexpr = Or,
   Or = m.Cc("OR") * m.Ct((And * space * m.P("OR") * space)^0 * And),
   And = m.Cc("AND") * m.Ct((Not * space * m.P("AND") * space)^0 * Not),
   Not = (m.C(m.P("NOT")) * space)^-1 *
      ( comparison
	   + m.P("(") * space * Or * space * m.P(")") ),
   comparison = expr * space * comparisonop * space * expr
      + stringexpr * space * stringcomparisonop * space * stringexpr,
   forstatement =
      m.C(m.P("FOR")) * space * floatvar * space * m.P("=") * space * expr
      * space * m.P("TO") * space * expr * space *
      ( m.P("STEP") * space * expr * space )^-1,
   numericassignment =
      m.Cc("LETN") * m.P("LET")^-1 * space *
      floatlval * space * m.P("=") * space * expr * space,
   expr = Sum,
   Sum = ( Product * space * m.C(m.S("+-")) * space)^0 * Product * space,
   Product = ( Unary * space * m.C(m.S("*/")) * space)^0 * Unary * space,
   Unary = m.C(m.S("+-")^-1) * Value,
   Value = integer + floatlval + m.P("(") * space * Sum * m.P(")"),
   floatlval = element + floatvar,
   -- Array access/function/builtin call
   arg = expr + logicalexpr + stringexpr,
   arglist = m.Ct(( arg * space * m.P(",") * space)^0 * arg),
   element = floatvar * space * m.P("(") * space * exprlist * space * m.P(")"),
   statementlist = m.Ct((statement * m.P(":") * space )^0 * statement),
   line = m.Ct(lineno * space * statementlist * m.Cp()),
};

local prog = {};
local nerr = 0;
local count = 1;
for line in file:lines() do
   local m = basicline:match(line);
   if not m then
      io.write(string.format("Syntax Error at line %d\n", count));
      io.write(line, "\n");
   else
      local mend = m[#m];
      if mend ~= #line+1 then
	 io.write(string.format("Syntax Error at line %d:%d\n",
				count,mend));
	 io.write(line, "\n");
	 io.write(string.rep(" ",mend-1).."^\n");
	 nerr = nerr + 1;
      else
	 prog[#prog+1] = m;
      end
   end      
   count = count + 1;
end

function eval(expr)
   return tostring(expr);
end

function doprint(printlist)
   local j = 1;
   local ncol = 0;
   local outstr = "";
   local flush = true;
   for j=1,#printlist do
      local element = printlist[j]
      flush = true;
      if element == ";" then
	 flush = false;
	 element = "";
      elseif element == "," then
	 local newcol = 14*(ncol/14+1);
	 element = string.rep(" ",newcol-ncol)
	 flush = false;
      else
	 element = eval(element);
      end
      ncol = ncol+#element;
      outstr = outstr..element;
   end
   if flush then
      outstr = outstr.."\n";
   end
   io.write(outstr);
end

if nerr == 0 and mode == 2 then
   for i=1,#prog do
      local m = prog[i];
      local basiclineno = m[1];
      local stats = m[2];
      for i=1,#stats do
	 if stats[i][1] == "PRINT" then
	    doprint(stats[i][2]);
	 end
      end
   end
end
file:close();
