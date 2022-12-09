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
local string_ =
   m.Ct(m.Cc("STRING")*m.P("\"") * m.C((any-m.P("\""))^0) * m.P("\""));
local integer = m.Ct(m.Cc("INTEGER")*m.C(digit^1));
local varname = m.R("AZ")^1 * m.R("09")^0;
local floatvar = m.Ct(m.Cc("FLOATVAR")*m.C(varname));
local stringvar = m.Ct(m.Cc("STRINGVAR")*m.C(varname) * m.P("$"));
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
local stopstatement = m.P {
   m.Cc"END" * m.P("STOP") * space
};
local remstatement = m.P {
   m.C(m.P("REM")) * any^0
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
local ifstart = m.V"ifstart";
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
      m.Ct(
	 gotostatement + gosubstatement + forstatement + nextstatement
	    + endstatement + stopstatement + printstatement + numericassignment
	    + returnstatement + stringassignment + dimstatement +
	    inputstatement + endstatement + ifstatement + remstatement ),
   printstatement = m.C(m.P("PRINT")) * space * m.Ct(printlist),
   stringlval = stringelement + stringvar,
   stringelement = stringvar * space * m.P("(") * space * exprlist * space * m.P(")"),
   stringassignment =
      m.Cc("LETS") * m.P("LET")^-1 * space *
      stringlval * space * m.P("=") * space * stringexpr * space,
   stringexpr = string_ + stringvar,
   printexpr = stringexpr + expr,
   printlist = (printexpr * space * m.C((m.S(";,")*space))^-1 )^0,
   inputitem = stringlval + floatlval,
   inputlist = (inputitem * space * m.P(",")*space)^-1 * inputitem,
   inputstatement = m.C(m.P("INPUT")) * space *
      (stringexpr * space * m.P(";") * space)^-1 * inputlist,
   ifstatement = m.C(m.P("IF")) * space * logicalexpr * space *
      m.P("THEN") * space * (m.Ct (m.Cc("GOTO") * lineno) * space + statement),
   exprlist = m.Ct(( expr * space * m.P(",") * space)^0 * expr),
   dimdef = anyvar * space * m.P("(") * space * exprlist * space * m.P(")"),
   dimlist = ( dimdef * space * m.P(",") * space)^0 * dimdef,
   dimstatement = m.C(m.P("DIM")) * space * dimlist,
   logicalexpr = Or,
   Or = m.Ct(m.Cc("OR") * (And * space * m.P("OR") * space)^0 * And),
   And = m.Ct(m.Cc("AND") * (Not * space * m.P("AND") * space)^0 * Not),
   Not = m.Ct((m.C("NOT") * space+m.Cc("EQV")) *
	 ( comparison + m.P("(") * space * Or * space * m.P(")") )),
   comparison = m.Ct(
      m.Cc("COMPAREF") * expr * space * comparisonop * space * expr 
	 + m.Cc("COMPARES") * stringexpr * space * stringcomparisonop * space * stringexpr),
   forstatement =
      m.C(m.P("FOR")) * space * floatvar * space * m.P("=") * space * expr
      * space * m.P("TO") * space * expr * space *
      ( m.P("STEP") * space * expr * space )^-1,
   numericassignment =
      m.Cc("LETN") * m.P("LET")^-1 * space *
      floatlval * space * m.P("=") * space * expr * space,
   expr = Sum,
   Sum =
      m.Ct(m.Cc("SUM") * ( Product * space * m.C(m.S("+-")) * space)^0 * Product) * space,
   Product = m.Ct(m.Cc("PRODUCT") * ( Unary * space * m.C(m.S("*/")) * space)^0 * Unary) * space,
   Unary = m.Ct(m.Cc("UNARY") * m.C(m.S("+-"))^-1 * Value),
   Value = integer + floatlval + m.P("(") * space * Sum * m.P(")"),
   floatlval = element + floatvar,
   -- Array access/function/builtin call
   arg = expr + logicalexpr + stringexpr,
   arglist = m.Ct(( arg * space * m.P(",") * space)^0 * arg),
   element = m.Ct(m.Cc("ELEMENT") * floatvar * space * m.P("(") * space * exprlist * space * m.P(")")),
   statementlist = (statement * m.P(":") * space )^0 * statement,
   line = m.Ct(lineno * space * m.Ct(statementlist) * m.Cp()),
};

local prog = {};
local nerr = 0;
-- Read and parse input file
local count = 1;
local targets = {} -- Jump table
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
	 prog[#prog+1] = {"TARGET",m[1]};
	 targets[m[1]] = #prog;
	 for k,v in ipairs(m[2]) do
	    --print(">>",k,v[1]); --Confirm first-level commands are captured
	    prog[#prog+1] = v;
	 end
      end
   end      
   count = count + 1;
end
file:close();

-- Machine state
local pc = 1;
local basiclineno = 0;
local quit = false;
local substack = {};

-- Symbol tables
local fvars, svars = {}, {};

function eval(expr)
   if type(expr) == "table" then
      if expr[1] == "STRING" then
	 return expr[2];
      elseif expr[1] == "UNARY" then
	 if #expr == 3 then
	    if expr[2] == "-" then
	       return -eval(expr[3]);
	    else
	       return eval(expr[3]);
	    end
	 else
	    return eval(expr[2]);
	 end
      elseif expr[1] == "PRODUCT" then
	 local val = eval(expr[2])
	 for i=3,#expr,2 do
	    if expr[i] == "*" then
	       val = val * eval(expr[i+1]);
	    else
	       val = val / eval(expr[i+1]);
	    end
	 end
	 return val;
      elseif expr[1] == "SUM" then
	 local val = eval(expr[2])
	 for i=3,#expr,2 do
	    if expr[i] == "+" then
	       val = val + eval(expr[i+1]);
	    else
	       val = val - eval(expr[i+1]);
	    end
	 end
	 return val;
      elseif expr[1] == "INTEGER" then
	 return tonumber(expr[2]);
      elseif expr[1] == "FLOATVAR" then
	 return fvars[expr[2]];
      elseif expr[1] == "STRINGVAR" then
	 return svars[expr[2]];
      else
	 print(false,"Bad expr "..tostring(expr[1]).." at "..basiclineno);
      end
   else
      print(false,"Parser failure at "..pc);
   end
   return tostring(expr);
end

function doinput(inputlist)
   local i=2;
   if inputlist[i][1] == "STRING" then
      io.write(inputlist[i][2].."? ");
      i=i+1;
   end
   local input = io.read("*l");
   for j=i,#inputlist do
      local vartype = inputlist[j][1];
      local varname = inputlist[j][2];
      if vartype == "STRINGVAR" then
	 svars[varname] = input;
      end
      --print(inputlist[j][1]);
   end
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
	 element = tostring(eval(element));
      end
      ncol = ncol+#element;
      outstr = outstr..element;
   end
   if flush then
      outstr = outstr.."\n";
   end
   io.write(outstr);
end

function doletn(lval,expr)
   local target = lval[2];
   fvars[target] = eval(expr);
end

function dolets(lval,expr)
   local target = lval[2];
   svars[target] = eval(expr);
end

function logicaleval(expr)
   if expr[1] == "OR" then
      local val = logicaleval(expr[2]);
      for i=3,#expr do
	 val = val or logicaleval(expr[i]);
      end
      return val;
   elseif expr[1] == "AND" then
      local val = logicaleval(expr[2]);
      for i=3,#expr do
	 val = val and logicaleval(expr[i]);
      end
      return val;
   elseif expr[1] == "NOT" then
      local val = logicaleval(expr[2]);
      return not val;
   elseif expr[1] == "EQV" then
      local val = logicaleval(expr[2]);
      return val;
   elseif expr[1] == "COMPAREF" then
      local val1 = eval(expr[2]);
      local val2 = eval(expr[4]);
      local val = false;
      if expr[3] == "=" then
	 val = val1 == val2;
      elseif expr[3] == "<>" then
	 val = val1 ~= val2;
      elseif expr[3] == ">=" then
	 val = val1 >= val2;
      elseif expr[3] == "<=" then
	 val = val1 <= val2;
      elseif expr[3] == ">" then
	 val = val1 > val2;
      elseif expr[3] == "<" then
	 val = val1 < val2;
      else
	 assert(false);
      end      
      return val;
   elseif expr[1] == "COMPARES" then
      local val1 = eval(expr[2]);
      local val2 = eval(expr[4]);
      local val = false;
      if expr[3] == "=" then
	 val = val1 == val2;
      elseif expr[3] == "<>" then
	 val = val1 ~= val2;
      else
	 assert(false);
      end      
      return val;
   else
      print("Failed to interpret",expr[1]);
      assert(false);
   end
   return nil;
end

local exec;

function doif(test,statement)
   local switch = logicaleval(test);
   if switch then
      exec(statement); -- And fall through
   else
      while pc < #prog and prog[pc][1] ~= "TARGET" do
	 pc = pc+1;
      end
      pc = pc-1;
   end
end

function exec(stat)
   if stat[1] == "TARGET" then
      basiclineno = stat[2];
   elseif stat[1] == "REM" then
      -- Do nothing
   elseif stat[1] == "PRINT" then
      doprint(stat[2]);
   elseif stat[1] == "INPUT" then
      doinput(stat);
   elseif stat[1] == "LETN" then
      doletn(stat[2],stat[3]);
   elseif stat[1] == "LETS" then
      dolets(stat[2],stat[3]);
   elseif stat[1] == "GOTO" then
      pc = targets[stat[2]]-1;
   elseif stat[1] == "IF" then
      doif(stat[2],stat[3]);
   elseif stat[1] == "END" then
      quit = true;
   elseif stat[1] == "GOSUB" then
      table.insert(substack,pc);
      pc = targets[stat[2]]-1;
   elseif stat[1] == "RETURN" then
      pc = table.remove(substack);
   elseif stat[1] == "DATA" or
      stat[1] == "DEF" or
      stat[1] == "DIM" or --<<<
      stat[1] == "FOR" or --<<<
      stat[1] == "NEXT" or --<<<
      stat[1] == "ON" or
      stat[1] == "RANDOMIZE" or
      stat[1] == "READ" or
      stat[1] == "RESTORE" then
	 print("Not handled",stat[1]);
   else
      print("Unknown statement",stat[1]);
   end
   pc = pc + 1;
end

if nerr == 0 and mode == 2 then
   while true do
      exec(prog[pc]);
      if quit or pc > #prog then
	 -- Run off end of program
	 break;
      end
   end
end
