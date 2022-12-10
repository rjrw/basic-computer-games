#!/usr/bin/env lua

-- $Id: test.lua $

-- require"strict"    -- just to be pedantic

local m = require"lpeg";

-- Parse = 1, interpret = 2, compile = 3, compile & optimize = 4
local mode = 1;
local verbose = false;

local narg = 1;
while narg < #arg do
   if arg[narg] == "-i" then
      mode = 2;
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
local float = m.P( (digit^0 * m.P(".") * digit^1 + digit^1 * m.P(".")^-1) *(m.P("E")*m.S("+-")^-1*digit^1)^-1);
local floatval = m.Ct(m.Cc("FLOATVAL")*m.C(float));
local varname = m.R("AZ")^1 * m.R("09")^0;
local floatvar = m.Ct(m.Cc("FLOATVAR")*m.C(varname));
local stringvar = m.Ct(m.Cc("STRINGVAR")*m.C(varname) * m.P("$"));
local anyvar = m.P { stringvar + floatvar };
local lineno = m.C(digit^1);
local gotostatement = m.P {
   m.Cc("GOTO") * m.P("GO") * space * m.P("TO") * space * lineno * space
};
local literal = m.P { floatval + stringval + m.Ct(m.Cc("STRING")*m.C((any-m.S(", \t"))^1)) };
local datastatement = m.P {
   m.C(m.P("DATA")) * space * ( literal * space * m.P(",") * space ) ^0 * literal * space
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
local logicalexpr = m.V"logicalexpr"
local ifstatement = m.V"ifstatement";
local ifstart = m.V"ifstart";
local expr = m.V"expr";
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
local call = m.V"call";
local stringcall = m.V"stringcall";
local statement = m.V"statement";
local statementlist = m.V"statementlist";
local basicline = m.P {
   "line";
   statement =
      m.Ct(
	 gotostatement + gosubstatement + forstatement + nextstatement
	    + endstatement + stopstatement + printstatement + numericassignment
	    + returnstatement + stringassignment + dimstatement +
	    inputstatement + endstatement + ifstatement + remstatement +
	    onstatement + datastatement + randomizestatement + restorestatement +
	    readstatement + defstatement ),
   printstatement = m.C(m.P("PRINT")) * space * m.Ct(printlist),
   stringlval = stringelement + stringvar,
   stringelement = m.Ct(m.Cc("STRINGELEMENT") * stringvar * space *
			   m.P("(") * space * exprlist * space * m.P(")")),
   stringassignment =
      m.Cc("LETS") * m.P("LET")^-1 * space *
      stringlval * space * m.P("=") * space * stringexpr * space,
   stringexpr = concat,
   concat = m.Ct(m.Cc("CONCAT") *
		    (stringrval * space * m.P("+") * space)^0 * stringrval),
   stringrval = stringval + stringcall + stringlval,
   printexpr = stringexpr + expr + m.C(m.S(";,"))*space,
   printlist = (printexpr * space )^0,
   inputitem = stringlval + floatlval,
   inputlist = (inputitem * space * m.P(",") * space)^0 * inputitem * space,
   inputstatement = m.C(m.P("INPUT")) * space *
      (m.Cc("PROMPT") * stringexpr * space * m.P(";") * space)^-1 * inputlist,
   readstatement = m.C(m.P("READ")) * space * inputlist,
   ifstatement = m.C(m.P("IF")) * space * logicalexpr * space *
      m.P("THEN") * space * (m.Ct (m.Cc("GOTO") * lineno) * space + statement),
   exprlist = m.Ct(( expr * space * m.P(",") * space)^0 * expr),
   dimdef = m.Ct(anyvar * space * m.P("(") * space * exprlist * space * m.P(")")),
   dimlist = ( dimdef * space * m.P(",") * space)^0 * dimdef,
   dimstatement = m.C(m.P("DIM")) * space * dimlist,
   dummylist = m.Ct( (m.C(varname)*space*m.P(",")*space)^0*m.C(varname)),
   defstatement = m.C(m.P("DEF")) * m.S(" \t")^1 * m.P("FN") * space
      * m.C(varname) * space * m.P("(") * space * dummylist * space * m.P(")")
      * space * m.P("=") * space * expr,
   logicalexpr = Or,
   Or = m.Ct(m.Cc("OR") * (And * space * m.P("OR") * space)^0 * And),
   And = m.Ct(m.Cc("AND") * (Not * space * m.P("AND") * space)^0 * Not),
   Not = m.Ct((m.C("NOT") * space+m.Cc("EQV")) *
	 ( comparison + m.P("(") * space * Or * space * m.P(")") )),
   comparison = m.Ct(
      m.Cc("COMPAREF") * expr * space * comparisonop * space * expr 
	 + m.Cc("COMPARES") * stringexpr * space * comparisonop * space * stringexpr),
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
   expr = Sum,
   Sum =
      m.Ct(m.Cc("SUM") * ( Product * space * m.C(m.S("+-")) * space)^0 * Product) * space,
   Product = m.Ct(m.Cc("PRODUCT") * ( Power * space * m.C(m.S("*/")) * space)^0 * Power) * space,
   Power = m.Ct(m.Cc("POWER") * ( Unary * space * m.S("^") * space)^0 * Unary) * space,
   Unary = m.Ct(m.Cc("UNARY") * m.C(m.S("+-"))^-1 * Value),
   Value = floatval + floatrval + m.P("(") * space * expr * m.P(")"),
   floatlval = element + floatvar,
   floatrval = call + floatvar,
   -- Array access/function/builtin call
   arg = logicalexpr + stringexpr + expr,
   arglist = m.Ct(( arg * space * m.P(",") * space)^0 * arg),
   element = m.Ct(m.Cc("ELEMENT") * floatvar * space * m.P("(") * space * exprlist * space * m.P(")")),
   call = m.Ct(m.Cc("CALL") * floatvar * space * m.P("(") * space * arglist * space * m.P(")")),
   stringcall = m.Ct(m.Cc("STRINGCALL") * stringvar * space * m.P("(") * space * arglist * space * m.P(")")),
   statementlist = (statement * m.P(":") * space )^0 * statement,
   line = m.Ct(lineno * space * m.Ct(statementlist) * m.Cp()),
};

local prog, data, datatarget = {}, {}, {};
local datapc = 1;
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
	       datatarget[m[1]] = #data+1;
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

-- Machine state
local pc = 1;
local basiclineno = 0;
local quit = false;
local substack,forstack = {}, {};

-- Symbol tables
local fvars, svars, favars, savars = {}, {}, {}, {};

local printstr = "";
function printtab(n)
   if n > #printstr then
      printstr = printstr..string.rep(" ",n-#printstr);
   end
   return "";
end

function abs(x)
   if x < 0 then
      return -x;
   end
   return x;
end

function len(x)
   return #x;
end

function sgn(x)
   if x < 0 then
      return -1;
   end
   return 1;
end

function spc(x)
   return string.rep(" ",x);
end

-- Builtin function table
local builtins =
   { ABS = abs, ASC = string.byte, ATN = math.atan, COS = math.cos,
     EXP = math.exp, INT = math.floor, LEN=len, LOG = math.log, SGN = sgn,
     SIN = math.sin, SPC = spc, SQR = math.sqrt, STR=tostring,
     TAB = printtab, TAN = math.tan, VAL=tonumber };
builtins["CHR$"] = string.char;
builtins["LEFT$"] = function(s,j) return s:sub(1,j) end
builtins["RIGHT$"] = function(s,j) return s:sub(-j) end
builtins["MID$"] = function(...)
   local s, i, j = ...;
   if j then
      return s:sub(i,i+j-1)
   end
   return s:sub(i);
end

function makernd()
   local rndval=0.1;
   function RND(arg)
      if arg <= 0 then
	 math.randomseed(math.floor(-arg));
      end
      if arg ~= 0 then
	 rndval = math.random();
      end
      return rndval;
   end
   function randomize()
      local now = os.time();
      local date = os.date("*t",now);
      local midnight = os.time{year=date.year, month=date.month,
			       day=date.day, hour=0};
      rndval = math.randomseed(math.floor(midnight-now));
   end
   return RND, randomize;
end
local randomize;
builtins.RND, randomize = makernd();

function eval(expr)
   if type(expr) == "table" then
      if expr[1] == "STRING" then
	 return expr[2];
      elseif expr[1] == "CONCAT" then -- string concatenation
	 local val = eval(expr[2]);
	 for i=3,#expr do
	    val = val..eval(expr[i]);
	 end
	 return val;
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
	 local val = eval(expr[2]);
	 for i=3,#expr,2 do
	    if expr[i] == "*" then
	       val = val * eval(expr[i+1]);
	    else
	       val = val / eval(expr[i+1]);
	    end
	 end
	 return val;
      elseif expr[1] == "POWER" then
	 local val = eval(expr[#expr]);
	 for i=#expr-1,2,-1 do
	    val = eval(expr[i]) ^ val;
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
      elseif expr[1] == "FLOATVAL" then
	 return tonumber(expr[2]);
      elseif expr[1] == "FLOATVAR" then
	 if fvars[expr[2]] == nil then
	    return 0;
	 end
	 return fvars[expr[2]];
      elseif expr[1] == "STRINGVAR" then
	 return svars[expr[2]];
      elseif expr[1] == "CALL" then
	 local name = expr[2][2];
	 local exprtype = expr[2][1];
	 local arglist = expr[3];
	 local args = {};
	 for k,v in ipairs(expr[3]) do
	    args[#args+1] = eval(v);
	 end
	 local builtin = exprtype == "FLOATVAR" and builtins[name] or builtins[name.."$"];
	 if builtin then
	    return builtin(table.unpack(args));
	 end
	 local val = favars[name];
	 if val then
	    for _, v in ipairs(args) do
	       val = val[v];
	    end
	    return val;
	 else
	    error("Array "..name.." not known");
	 end
      elseif expr[1] == "STRINGCALL" then
	 local name = expr[2][2];
	 local exprtype = expr[2][1];
	 local arglist = expr[3];
	 local args = {};
	 for k,v in ipairs(expr[3]) do
	    args[#args+1] = eval(v);
	 end
	 local builtin = exprtype == "FLOATVAR" and builtins[name] or builtins[name.."$"];
	 if builtin then
	    return builtin(table.unpack(args));
	 end
	 local val = savars[name];
	 if val then
	    for _, v in ipairs(args) do
	       val = val[v];
	    end
	    return val;
	 else
	    error("Array "..name.."$ not known");
	 end
      else
	 error("Bad expr "..tostring(expr[1]).." at "..basiclineno);
      end
   else
      error("Parser failure at "..pc);
   end
   return tostring(expr);
end

function doinput(inputlist)
   local i=2;
   local prompt = "? ";
   if inputlist[i] == "PROMPT" then
      prompt = eval(inputlist[i+1])..prompt;
      i=i+2;
   end
   local input = "";
   while input == "" do
      io.write(prompt);
      input = io.read("*l");
   end
   for j=i,#inputlist do
      local vartype = inputlist[j][1];
      local varname = inputlist[j][2];
      if vartype == "STRINGVAR" then
	 svars[varname] = input;
      elseif vartype == "FLOATVAR" then
	 fvars[varname] = tonumber(input);
      else
	 error("Vartype "..vartype.." not yet supported");
      end
      --print(inputlist[j][1]);
   end
end
function doprint(printlist)
   printstr="";
   local flush = true;
   local j = 1;
   for j=1,#printlist do
      local element = printlist[j]
      flush = true;
      if element == ";" then
	 flush = false;
      elseif element == "," then
	 local newcol = 14*(#printstr/14+1);
	 printtab(newcol);
	 flush = false;
      else
	 local val = eval(element);
	 if type(val) == "number" then
	    if (val>0) then
	       val = " "..tostring(val).." ";
	    else
	       val = tostring(val).." ";
	    end
	 end
	 printstr = printstr..val;
      end
   end
   if flush then
      printstr = printstr.."\n";
   end
   io.write(printstr);
end

function doletn(lval,expr)
   local ttype = lval[1];
   local target = lval[2];
   local value = eval(expr)
   if ttype == "ELEMENT" then
      local eltype = target[1];
      if #lval[3] > 2 then
	 error("More than 2-dimensional access not yet implemented");
      end
      if eltype ~= "FLOATVAR" then
	 error("Non-floatvar access not yet implemented");
      end
      if #lval[3] == 1 then
	 local index = eval(lval[3][1]);
	 favars[target[2]][index] = value;
      else
	 local i1, i2 = eval(lval[3][1]),eval(lval[3][2]);
	 favars[target[2]][i1][i2] = value;
      end
   else
      fvars[target] = value;
   end
end

function dolets(lval,expr)
   local ttype = lval[1];
   local target = lval[2];
   local value = eval(expr);
   if ttype == "STRINGELEMENT" then
      local eltype = target[1];
      if #lval[3] > 2 then
	 error("More than 2-dimensional access not yet implemented");
      end
      if eltype ~= "STRINGVAR" then
	 error("Non-stringvar access not yet implemented");
      end
      if #lval[3] == 1 then
	 local index = eval(lval[3][1]);
	 savars[target[2]][index] = value;
      else
	 local i1, i2 = eval(lval[3][1]),eval(lval[3][2]);
	 savars[target[2]][i1][i2] = value;
      end
   else
      svars[target] = value;
   end
end

function doon(stat)
   local switch = math.floor(eval(stat[2]));
   if switch > 0 and switch+2 <= #stat then
      pc = targets[stat[2+switch]]-1;
   end
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
   elseif expr[1] == "COMPAREF" or expr[1] == "COMPARES" then
      local val = eval(expr[2]);
      for i = 3, #expr, 2 do
	 local op, val2 = expr[i], eval(expr[i+1]);
	 if op == "=" then
	    val = val == val2;
	 elseif op == "<>" then
	    val = val ~= val2;
	 elseif op == ">=" then
	    val = val >= val2;
	 elseif op == "<=" then
	    val = val <= val2;
	 elseif op == ">" then
	    val = val > val2;
	 elseif op == "<" then
	    val = val < val2;
	 else
	    error("Operator "..op.." not recognized");
	 end
      end
      return val;
   else
      error("Failed to interpret "..expr[1]);
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
   end
   pc=pc-1;
end

function dofor(stat)
   local var = stat[2][2];
   fvars[var] = eval(stat[3]);
   local frame = {
      pc, var, eval(stat[4]), 1};
   if #stat == 5 then
      frame[4] = eval(stat[5]);
   end   
   table.insert(forstack,frame);
end

function donext(stat)
   if #stat == 1 then
      local frame = forstack[#forstack];
      local var = frame[2];
      local last = frame[3];
      local step = frame[4];
      local oldval = fvars[var];
      local newval = oldval + step;
      fvars[var] = newval;
      if step*(newval-last) <= 0 then
	 pc = frame[1];
	 return;
      else
	 table.remove(forstack);
      end
   else
      for i=2,#stat do
	 if stat[i][1] ~= "FLOATVAR" then
	    error("NEXT tag must be floating variable");
	 end
	 local frame = forstack[#forstack];
	 local var = frame[2];
	 while var ~= stat[i][2] do
	    table.remove(forstack);
	    frame = forstack[#forstack];
	    var = frame[2];
	 end
	 local last = frame[3];
	 local step = frame[4];
	 local oldval = fvars[var];
	 local newval = oldval + step;
	 fvars[var] = newval;
	 if step*(newval-last) <= 0 then
	    pc = frame[1];
	    return;
	 else
	    table.remove(forstack);
	 end
      end
   end
end

function dodim(stat)
   for i = 2,#stat do
      local dimvar = stat[i][1];
      local dimtype = dimvar[1];
      local name = dimvar[2];
      local shape = stat[i][2];
      if #shape > 2 then
	 error("Don't yet handle more than 2-dimensional arrays");
      end
      local store = {};
      if dimtype == "FLOATVAR" then
	 if #shape == 1 then
	    for j = 0, eval(shape[1]) do
	       store[j] = 0.0;
	    end
	 else
	    for j = 0, eval(shape[1]) do
	       store[j] = {};
	       for k = 0, eval(shape[2]) do
		  store[j][k] = 0.0;
	       end
	    end
	 end
	 favars[name] = store;
      else
	 if #shape == 1 then
	    for j = 0, eval(shape[1]) do
	       store[j] = "";
	    end
	 else
	    for j = 0, eval(shape[1]) do
	       store[j] = {};
	       for k = 0, eval(shape[2]) do
		  store[j][k] = "";
	       end
	    end
	 end
	 savars[name] = store;
      end	 
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
   elseif stat[1] == "DIM" then
      dodim(stat);
   elseif stat[1] == "FOR" then
      dofor(stat);
   elseif stat[1] == "NEXT" then
      donext(stat);
   elseif stat[1] == "ON" then
      doon(stat);
   elseif stat[1] == "DATA" then
      -- Do nothing at run time
   elseif stat[1] == "RESTORE" then
      if #stat then
	 datapc = 1;
      else
	 datapc = datatargets[stat[2]];
      end
   elseif stat[1] == "READ" then
      for i=2,#stat do
	 local target = stat[i];
	 local dat = data[datapc][2];
	 if target[1] == "FLOATVAR" then
	    if data[datapc][1] ~= "FLOATVAL" then
	       error("Type mismatch from data to read");
	    end
	    fvars[target[2]] = tonumber(dat);
	 elseif target[1] == "STRINGVAR" then
	    if data[datapc][1] ~= "STRING" then
	       error("Type mismatch from data to read");
	    end
	    svars[target[2]] = dat;
	 else
	    error("READ target type "..tostring(target[1]).." not implemented");
	 end
	 datapc = datapc+1;
      end
   elseif stat[1] == "RANDOMIZE" then
      randomize();
   elseif stat[1] == "DEF" then
      error("Not handled "..stat[1]);
   else
      error("Unknown statement "..stat[1]);
   end
   pc = pc + 1;
end

if nerr == 0 and mode == 2 then
   while true do
      local status, err = pcall(function () exec(prog[pc]) end);
      if not status then
	 print("At BASIC line "..basiclineno);
	 print(err);
	 quit = true;
      end
      if quit or pc > #prog then
	 -- Run off end of program
	 break;
      end
   end
end
