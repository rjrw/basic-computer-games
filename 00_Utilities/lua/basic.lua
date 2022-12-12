#!/usr/bin/env lua

-- $Id: test.lua $

--require"strict"    -- just to be pedantic

local m = require"lpeg";
local rtl = require"basicrtl";

-- Parse = 1, interpret = 2, compile = 3, compile & optimize = 4
local mode = 2;
local verbose = false;

local narg = 1;
while narg < #arg do
   if arg[narg] == "-i" then
      mode = 2;
   elseif arg[narg] == "-p" then
      mode = 1;
   elseif arg[narg] == "-c" then
      mode = 3;
      error("Compilation not yet implemented");
   elseif arg[narg] == "-v" then
      verbose = true;
   else
      break;
   end
   narg = narg+1;
end
if #arg ~= narg then
   print("Usage: basic.lua [opts] <file>.bas");
   os.exit(1);
end
local file = assert(io.open(arg[narg]));

local any = m.P(1);
local space = m.S" \t"^0;
local digit = m.R("09");
local stringval =
   m.Ct(m.Cc("STRING")*m.P("\"") * m.C((any-m.P("\""))^0) * m.P("\""));
local float = m.P( m.P("-")^0 * (digit^0 * m.P(".") * digit^1 + digit^1 * m.P(".")^-1) *(m.P("E")*m.S("+-")^-1*digit^1)^-1);
local floatval = m.Ct(m.Cc("FLOATVAL")*m.C(float));
local varname = m.R("AZ")^1 * m.R("09")^0;
local floatvar = m.Ct(m.Cc("FLOATVAR")*m.C(varname));
local stringvar = m.Ct(m.Cc("STRINGVAR")*m.C(varname) * m.P("$"));
local anyvar = m.P { stringvar + floatvar };
local lineno = m.C(digit^1);
local gotostatement = m.P {
   m.Cc("GOTO") * m.P("GO") * space * m.P("TO") * space * lineno * space
};
local literal = m.P {
   floatval + stringval + m.Ct(m.Cc("STRING")*m.C((any-m.S(", \t"))^1))
};
local datalist = m.P {
   space * ( literal * space * m.P(",") * space ) ^0 * literal * space
};
local datastatement = m.P {
   m.C(m.P("DATA")) * datalist
};
local gosubstatement = m.P {
   m.Cc("GOSUB") * m.P("GO") * space * m.P("SUB") * space * lineno * space
};
local nextlist = m.P {
   ( floatvar * space * m.P"," * space)^0 * floatvar * space
};
local nextstatement = m.P {
   m.C(m.P("NEXT")) * space * nextlist * space +
   m.C(m.P("NEXT"))
};
local endstatement = m.P {
   m.C(m.P("END")) * space
};
local stopstatement = m.P {
   m.Cc"END" * m.P("STOP") * space
};
local remstatement = m.P {
   m.C(m.P("REM")) * any^0
};
local returnstatement = m.P {
   m.C(m.P("RETURN")) * space
};
local randomizestatement = m.P {
   m.C(m.P("RANDOMIZE")) * space
};
local restorestatement = m.P {
   m.C(m.P("RESTORE")) * space * (lineno * space)^-1
};
local stringexpr = m.V"stringexpr";
local concat = m.V"concat";
local stringassignment = m.V"stringassignment";
local printexpr = m.V"printexpr";
local printlist = m.V"printlist";
local printstatement = m.V"printstatement";
local inputstatement = m.V"inputstatement";
local readstatement = m.V"readstatement";
local inputlist = m.V"inputlist";
local inputitem = m.V"inputitem";

local comparisonop = m.P {
   m.C(m.P("=") + m.P("<>") + m.P("<=") + m.P(">=") + m.P("<") + m.P(">"))
};
local Sum = m.V"Sum";
local Product = m.V"Product"
local Power = m.V"Power"
local Unary = m.V"Unary";
local Value = m.V"Value";
local Or = m.V"Or";
local And = m.V"And";
local Not = m.V"Not";
local Statement = m.V"Statement";
local ifstatement = m.V"ifstatement";
local ifstart = m.V"ifstart";
local expr = m.V"expr";
local rawexpr = m.V"rawexpr";
local numericassignment = m.V"numericassignment";
local dimstatement = m.V"dimstatement";
local dimlist = m.V"dimlist";
local dimdef = m.V"dimdef";
local forstatement = m.V"forstatement"
local onstatement = m.V"onstatement"
local defstatement = m.V"defstatement";
local comparison = m.V"comparison";
local floatlval = m.V"floatlval";
local floatrval = m.V"floatrval";
local stringlval = m.V"stringlval";
local stringrval = m.V"stringrval";
local stringelement = m.V"stringelement";
local arg = m.V"arg";
local arglist = m.V"arglist";
local dummylist = m.V"dummylist";
local exprlist = m.V"exprlist";
local element = m.V"element";
local index = m.V"index";
local funcall = m.V"funcall";
local stringindex = m.V"stringindex";
local statement = m.V"statement";
local statementlist = m.V"statementlist";
local linegrammar = {
   "line";
   statement =
      m.Ct(
	 gotostatement + gosubstatement + forstatement + nextstatement
	    + endstatement + stopstatement + printstatement 
	    + returnstatement + dimstatement
	    + inputstatement + endstatement + ifstatement + remstatement
	    + onstatement + datastatement + randomizestatement + restorestatement
	    + readstatement + defstatement
	 -- Assignments need to come late to avoid clashes with other statements
	 -- e.g. IF ((Z+P)/2)= looking like an array assignment.
	    + numericassignment + stringassignment ),
   printstatement = m.C(m.P("PRINT")) * space * m.Ct(printlist),
   inputstatement = m.C(m.P("INPUT")) * space *
      (m.Cc("PROMPT") * stringexpr * space * m.P(";") * space)^-1 * inputlist,
   readstatement = m.C(m.P("READ")) * space * inputlist,
   ifstatement = m.C(m.P("IF")) * space * expr * space *
      m.P("THEN") * space * (m.Ct (m.Cc("GOTO") * lineno) * space + statement),
   dimstatement = m.C(m.P("DIM")) * space * dimlist,
   defstatement = m.C(m.P("DEF")) * space * m.P("FN") * space
      * m.C(varname) * space * m.P("(") * space * dummylist * space * m.P(")")
      * space * m.P("=") * space * expr,
   forstatement =
      m.C(m.P("FOR")) * space * floatvar * space * m.P("=") * space * expr
      * space * m.P("TO") * space * expr * space *
      ( m.P("STEP") * space * expr * space )^-1,
   onstatement =
      m.C(m.P("ON")) * space * expr * space * m.P("GO") * space * m.P("TO") * space *
      (lineno * space * m.P(",") * space)^0 * lineno * space,
   numericassignment =
      m.Cc("LETN") * m.P("LET")^-1 * space *
      floatlval * space * m.P("=") * space * expr * space,
   stringassignment =
      m.Cc("LETS") * m.P("LET")^-1 * space *
      stringlval * space * m.P("=") * space * stringexpr * space,
   -- Argument lists
   exprlist = m.Ct(( expr * space * m.P(",") * space)^0 * expr),
   dimdef = m.Ct(anyvar * space * m.P("(") * space * exprlist * space * m.P(")")),
   dimlist = ( dimdef * space * m.P(",") * space)^0 * dimdef,
   printexpr = stringexpr + expr + m.C(m.S(";,"))*space,
   printlist = (printexpr * space )^0,
   inputitem = stringlval + floatlval,
   inputlist = (inputitem * space * m.P(",") * space)^0 * inputitem * space,
   dummylist = m.Ct( (m.C(varname)*space*m.P(",")*space)^0*m.C(varname)),
   -- Expression hierarchy
   expr = rawexpr,
   rawexpr = Or,
   Or = m.Ct(m.Cc("OR") * (And * space * m.P("OR") * space)^0 * And),
   And = m.Ct(m.Cc("AND") * (Not * space * m.P("AND") * space)^0 * Not),
   Not = m.Ct((m.C("NOT") * space+m.Cc("EQV")) * comparison),
   comparison = m.Ct(
      m.Cc("COMPARE") *
	 ( stringexpr * space * comparisonop * space * stringexpr
	      + ( Sum * space * comparisonop * space)^0 * Sum ) ),
   Sum =
      m.Ct(m.Cc("SUM") * ( Product * space * m.C(m.S("+-")) * space)^0 * Product) * space,
   Product = m.Ct(m.Cc("PRODUCT") * ( Power * space * m.C(m.S("*/")) * space)^0 * Power) * space,
   Power = m.Ct(m.Cc("POWER") * ( Unary * space * m.S("^") * space)^0 * Unary) * space,
   -- TODO: address ambiguity about the handling of -1 -- is it "-" "1" or "-1"?
   Unary = m.Ct(m.Cc("UNARY") * m.C(m.S("+-"))^-1 * Value),
   Value = floatval + floatrval + m.P("(") * space * expr * space * m.P(")"),
   -- String expression hierarchy
   stringexpr = concat,
   concat = m.Ct(m.Cc("CONCAT") *
		    (stringrval * space * m.P("+") * space)^0 * stringrval),
   -- Lowest-level groups
   floatlval = element + floatvar,
   floatrval = funcall + index + floatvar,
   stringlval = stringelement + stringvar,
   stringelement = m.Ct(m.Cc("STRINGELEMENT") * stringvar * space *
			   m.P("(") * space * exprlist * space * m.P(")")),
   stringrval = stringval + stringindex + stringlval,
  -- Array access/function/builtin call
   arg = stringexpr + expr,
   arglist = m.Ct(( arg * space * m.P(",") * space)^0 * arg),
   element = m.Ct(m.Cc("ELEMENT") * floatvar * space * m.P("(") * space * exprlist * space * m.P(")")),
   funcall = m.Ct(m.Cc("FUNCALL") *
		     m.P("FN") * space *
		     floatvar * space * m.P("(") * space * arglist * space * m.P(")")),
   index = m.Ct(m.Cc("INDEX") *
	       --m.Cmt(m.P"",function (s,p,c) print("Matching INDEX at",p); return true; end) *
		  floatvar * space * m.P("(") * space * arglist * space * m.P(")")),
   stringindex = m.Ct(m.Cc("STRINGINDEX") * stringvar * space * m.P("(") * space * arglist * space * m.P(")")),
   statementlist = (statement * m.P(":") * space )^0 * statement,
   line = m.Ct(lineno * space * m.Ct(statementlist) * m.Cp()),
};
-- Cache values for expr rule, to speed up run time
local basicexpr;
local cache = {};
local function matchexpr(s, p)
   -- Clear cache if subject has changed
   if cache.subject ~= s then
      cache.subject = s;
      cache.vals = {};
   end
   if cache.vals[p] == nil then
      local captures, pos = basicexpr:match(s,p-1);
      if captures == nil then
	 cache.vals[p] = {nil};
      else
	 table.insert(captures,1,pos);
	 cache.vals[p] = captures;
      end
   end
   return table.unpack(cache.vals[p]);
end
linegrammar.expr = m.Cmt(any,matchexpr);
local exprgrammar = {};
for k,v in pairs(linegrammar) do
   exprgrammar[k] = v;
end
exprgrammar[1] = "exprtagged";
exprgrammar.exprtagged = m.Ct(rawexpr) * m.Cp();
basicexpr = m.P(exprgrammar);
local basicline = m.P(linegrammar);

local prog, data, datatargets = {}, {}, {};
local nerr = 0;
-- Read and parse input file
local count = 1;
local targets = {} -- Jump table
for line in file:lines() do
   if verbose then print(line); end
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
	 prog[#prog+1] = {"TARGET",m[1]};
	 targets[m[1]] = #prog;
	 for k,v in ipairs(m[2]) do
	    --print(">>",k,v[1]); --Confirm first-level commands are captured
	    prog[#prog+1] = v;
	    if v[1] == "DATA" then
	       datatargets[m[1]] = #data+1;
	       for i = 2, #v do
		  table.insert(data,v[i]);
	       end
	    end
	 end
      end
   end      
   count = count + 1;
end
file:close();

if nerr == 0 and mode == 2 then
   rtl.run(prog, targets, data, datatargets);
end
