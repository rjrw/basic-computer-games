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

-- Machine state
local function makemachine(prog, targets, data, datatargets)
   return {
      prog = prog,
      targets = targets,
      data = data,
      datatargets = datatargets,
      pc = 1,
      datapc = 1,
      basiclineno = 0,
      quit = false,
      substack = {},
      forstack = {},
      -- Output state
      printstr = "",
      printcol = 0
   };
end

-- Symbol table -> environment
-- Loose names are floats, fa_xxx is floating array, s_xxx is string,
-- sa_xxx is string array
local basicenv = {_m=makemachine(prog, targets, data, datatargets)};

local function printtab(basicenv,n)
   n = math.floor(n);
   local m = basicenv._m;
   if n > m.printcol then
      m.printstr = m.printstr..string.rep(" ",n-m.printcol);
      m.printcol = n;
   end
   return "";
end

local ops = {};

local function eval(basicenv,expr)
   if type(expr) ~= "table" then
      error("Parser failure at "..basicenv._m.pc);
   end
   local op = ops[expr[1]];
   if not op then
      error("Bad expr "..tostring(expr[1]).." at "..basicenv._m.basiclineno);
   end      
   return op(basicenv, expr);
end

local function doconcat(basicenv,expr)
   -- string concatenation
   local val = eval(basicenv,expr[2]);
   for i=3,#expr do
      val = val..eval(basicenv,expr[i]);
   end
   return val;
end

local function dounary(basicenv,expr)
   if #expr == 3 then
      if expr[2] == "-" then
	 return -eval(basicenv,expr[3]);
      else
	 return eval(basicenv,expr[3]);
      end
   else
      return eval(basicenv,expr[2]);
   end
end

local function dopower(basicenv,expr) 
   local val = eval(basicenv,expr[#expr]);
   for i=#expr-1,2,-1 do
      val = eval(basicenv,expr[i]) ^ val;
   end
   return val;
end

local function doproduct(basicenv,expr)
   local val = eval(basicenv,expr[2]);
   for i=3,#expr,2 do
      if expr[i] == "*" then
	 val = val * eval(basicenv,expr[i+1]);
      else
	 val = val / eval(basicenv,expr[i+1]);
      end
   end
   return val;
end

local function dosum(basicenv,expr)
   local val = eval(basicenv,expr[2]);
   for i=3,#expr,2 do
      if expr[i] == "+" then
	 val = val + eval(basicenv,expr[i+1]);
      else
	 val = val - eval(basicenv,expr[i+1]);
      end
   end
   return val;
end

local function dofloatval(basicenv,expr)
   return tonumber(expr[2]);
end

local function dofloatvar(basicenv,expr)
   if basicenv[expr[2]] == nil then
      return 0;
   end
   return basicenv[expr[2]];
end

local function dostringvar(basicenv,expr)
   return basicenv["s_"..expr[2]];
end

local function doindex(basicenv,expr)
   local name = expr[2][2];
   local exprtype = expr[2][1];
   local arglist = expr[3];
   local args = {};
   for k,v in ipairs(expr[3]) do
      args[#args+1] = eval(basicenv,v);
   end
   if name == "TAB" then
      printtab(basicenv,args[1]);
      return "";
   end
   local builtins = rtl.builtins;
   local builtin = exprtype == "FLOATVAR" and builtins[name] or builtins["s_"..name];
   if builtin then
      return builtin(table.unpack(args));
   end
   local val = basicenv["fa_"..name];
   if val == nil then
      val = {};
      for j=0,10 do
	 val[j] = 0.0;
      end
      basicenv["fa_"..name] = val;
   end
   if val then
      for _, v in ipairs(args) do
	 if v < 0 or v > #val then
	    error("Out of bounds array access");
	 end
	 val = val[v];
      end
      return val;
   else
      error("Array "..name.." not known");
   end
end

local function dostringindex(basicenv,expr)
   local name = expr[2][2];
   local exprtype = expr[2][1];
   local arglist = expr[3];
   local args = {};
   for k,v in ipairs(expr[3]) do
      args[#args+1] = eval(basicenv,v);
   end
   local builtins = rtl.builtins;
   local builtin = exprtype == "FLOATVAR" and builtins[name] or builtins["s_"..name];
   if builtin then
      return builtin(table.unpack(args));
   end
   local val = basicenv["sa_"..name];
   if val then
      for _, v in ipairs(args) do
	 if v < 0 or v > #val then
	    error("Out of bounds array access");
	 end
	 val = val[v];
      end
      return val;
   else
      error("Array "..name.."$ not known");
   end
end

local function door(basicenv,expr)
   local val = eval(basicenv,expr[2]);
   if #expr > 2 then
      val = val ~= 0
      for i=3,#expr do
	 val = val or (eval(basicenv,expr[i]) ~= 0);
      end
      val = val and -1 or 0;
   end
   return val
end

local function doand(basicenv,expr)
   local val = eval(basicenv,expr[2]);
   if #expr > 2 then
      val = val ~= 0
      for i=3,#expr do
	 val = val and (eval(basicenv,expr[i]) ~= 0);
      end
      val = val and -1 or 0;
   end
   return val
end

local function donot(basicenv,expr)
   local val = eval(basicenv,expr[2]);
   return val and 0 or -1;
end

local function doeqv(basicenv,expr)
   local val = eval(basicenv,expr[2]);
   return val;
end

local function docompare(basicenv,expr)
   local val = eval(basicenv,expr[2]);	 
   for i = 3, #expr, 2 do
      local op, val2 = expr[i], eval(basicenv,expr[i+1]);
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
      val = val and -1 or 0;
   end
   return val;
end

local function dofuncall(basicenv,expr)
   local name = "FN"..expr[2][2];
   local exprtype = expr[2][1];	 
   local arglist = expr[3];
   local func = basicenv[name];
   local args = {};
   -- Evaluate real arguments
   for i = 1,#arglist do
      args[i] = eval(basicenv,arglist[i]);
   end
   -- Replace dummy arguments in symbol table,
   -- keeping originals if present
   for k,v in ipairs(func.args) do
      local t = basicenv[v]; 
      basicenv[v] = args[k];
      args[k] = t;
   end
   local val = eval(basicenv,func.expr);
   -- Put original values back into dummy slots
   for k,v in ipairs(func.args) do
      basicenv[v] = args[k];
   end
   return val;
end

-- Operator dispatch table
ops.STRING    = function(basicenv,expr) return expr[2]; end;
ops.CONCAT    = doconcat;
ops.UNARY     = dounary;
ops.PRODUCT   = doproduct;
ops.POWER     = dopower;
ops.SUM       = dosum;
ops.OR        = door;
ops.AND       = doand;
ops.NOT       = donot;
ops.EQV       = doeqv; 
ops.COMPARE   = docompare;
ops.FLOATVAL  = dofloatval;
ops.FLOATVAR  = dofloatvar;
ops.STRINGVAR = dostringvar;
ops.INDEX     = doindex;
ops.STRINGINDEX = dostringindex;
ops.FUNCALL   = dofuncall;

local write = io.write;

local function doinput(inputlist)
   local i=2;
   local prompt = "? ";
   if inputlist[i] == "PROMPT" then
      prompt = eval(basicenv,inputlist[i+1])..prompt;
      i=i+2;
   end
   local input = "";
   while input == "" do
      write(prompt);
      input = io.read("*l");
   end
   for j=i,#inputlist do
      local vartype = inputlist[j][1];
      local varname = inputlist[j][2];
      if vartype == "STRINGVAR" or vartype == "STRINGELEMENT" then
	 assigns(inputlist[j],input);
      elseif vartype == "FLOATVAR" or vartype == "ELEMENT" then
	 assignf(inputlist[j],tonumber(input));
      else
	 error("Vartype "..vartype.." not yet supported");
      end
      --print(inputlist[j][1]);
   end
end

local function doprint(basicenv,stat)
   local printlist=stat[2];
   local m = basicenv._m;
   m.printstr="";
   local flush = true;
   local j = 1;
   for j=1,#printlist do
      local element = printlist[j]
      flush = true;
      if element == ";" then
	 flush = false;
      elseif element == "," then
	 local newcol = 14*(math.floor(m.printcol/14)+1);
	 printtab(basicenv,newcol);
	 flush = false;
      else
	 local val = eval(basicenv,element);
	 if type(val) == "number" then
	    if val>=0 then
	       val = " "..tostring(val).." ";
	    else
	       val = tostring(val).." ";
	    end
	 end
	 m.printstr = m.printstr..val;
	 m.printcol = m.printcol + #val;
      end
   end
   if flush then
      m.printstr = m.printstr.."\n";
      m.printcol = 0;
   end
   write(m.printstr);
end

local function assignf(lval,value)
   local ttype = lval[1];
   local target = lval[2];
   if ttype == "FLOATVAR" then
      basicenv[target] = value;
   elseif ttype == "ELEMENT" then
      local eltype = target[1];
      if #lval[3] > 2 then
	 error("More than 2-dimensional access not yet implemented");
      end
      if eltype ~= "FLOATVAR" then
	 error("Non-floatvar access not yet implemented");
      end
      if #lval[3] == 1 then
	 local index = eval(basicenv,lval[3][1]);
	 if basicenv["fa_"..target[2]] == nil then
	    local store = {};
	    for j = 0, 10 do
	       store[j] = 0.0;
	    end
	    basicenv["fa_"..target[2]] = store;
	 end
	 basicenv["fa_"..target[2]][index] = value;
      else
	 local i1, i2 = eval(basicenv,lval[3][1]),eval(basicenv,lval[3][2]);
	 basicenv["fa_"..target[2]][i1][i2] = value;
      end
   else
      error("Type mismatch in floating assignment");
   end
end

local function doletn(basicenv,stat)
   local lval = stat[2];
   local expr = stat[3];
   assignf(lval,eval(basicenv,expr))
end

local function assigns(lval,value)
   local ttype = lval[1];
   local target = lval[2];
   if ttype == "STRINGELEMENT" then
      local eltype = target[1];
      if #lval[3] > 2 then
	 error("More than 2-dimensional access not yet implemented");
      end
      if eltype ~= "STRINGVAR" then
	 error("Non-stringvar access not yet implemented");
      end
      if #lval[3] == 1 then
	 local index = eval(basicenv,lval[3][1]);
	 basicenv["sa_"..target[2]][index] = value;
      else
	 local i1, i2 = eval(basicenv,lval[3][1]),eval(basicenv,lval[3][2]);
	 basicenv["sa_"..target[2]][i1][i2] = value;
      end
   else
      basicenv["s_"..target] = value;
   end
end

local function dolets(basicenv,stat)
   local lval = stat[2];
   local expr = stat[3];
   assigns(lval,eval(basicenv,expr))
end

local function doon(basicenv,stat)
   local switch = math.floor(eval(basicenv,stat[2]));
   local m = basicenv._m;
   if switch > 0 and switch+2 <= #stat then
      m.pc = m.targets[stat[2+switch]]-1;
   end
end


local statements = {};

local function doif(basicenv,stat)
   local test = stat[2];
   local substat = stat[3];
   local m = basicenv._m;
   if eval(basicenv,test) ~= 0 then
      -- If true, run sub-statement and fall through to rest of line
      local cmd = statements[substat[1]];
      if cmd == nil then
	 error("Unknown statement "..substat[1]);
      end
      cmd(basicenv,substat);
   else
      -- Walk forward to next line
      local prog = m.prog;
      local targetpc = m.pc;
      while targetpc < #prog and prog[targetpc+1][1] ~= "TARGET" do
	 targetpc = targetpc+1;
      end
      -- This is a no-op, but calculation of target can better be
      -- moved to compile time, and this value appended to stat table
      local target = prog[targetpc][2];
      m.pc = m.targets[target];
   end
end

local function dofor(basicenv,stat)
   local control = stat[2][2];
   local init = eval(basicenv,stat[3]);
   local last = eval(basicenv,stat[4]);
   local step = #stat == 5 and eval(basicenv,stat[5]) or 1;
   basicenv[control] = init;
   local frame = { basicenv._m.pc, control, last, step};
   table.insert(basicenv._m.forstack,frame);
end

local function donext(basicenv,stat)
   local forstack = basicenv._m.forstack;
   if #stat == 1 then
      local frame = forstack[#forstack];
      local control = frame[2];
      local last = frame[3];
      local step = frame[4];
      local oldval = basicenv[control];
      local newval = oldval + step;
      basicenv[control] = newval;
      if step*(newval-last) <= 0 then
	 basicenv._m.pc = frame[1];
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
	 local control = frame[2];
	 while control ~= stat[i][2] do
	    table.remove(forstack);
	    frame = forstack[#forstack];
	    control = frame[2];
	 end
	 local last = frame[3];
	 local step = frame[4];
	 local oldval = basicenv[control];
	 local newval = oldval + step;
	 basicenv[control] = newval;
	 if step*(newval-last) <= 0 then
	    basicenv._m.pc = frame[1];
	    return;
	 else
	    table.remove(forstack);
	 end
      end
   end
end

local function dodim(basicenv,stat)
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
	    for j = 0, eval(basicenv,shape[1]) do
	       store[j] = 0.0;
	    end
	 else
	    for j = 0, eval(basicenv,shape[1]) do
	       store[j] = {};
	       for k = 0, eval(basicenv,shape[2]) do
		  store[j][k] = 0.0;
	       end
	    end
	 end
	 basicenv["fa_"..name] = store;
      else
	 if #shape == 1 then
	    for j = 0, eval(basicenv,shape[1]) do
	       store[j] = "";
	    end
	 else
	    for j = 0, eval(basicenv,shape[1]) do
	       store[j] = {};
	       for k = 0, eval(basicenv,shape[2]) do
		  store[j][k] = "";
	       end
	    end
	 end
	 basicenv["sa_"..name] = store;
      end	 
   end
end

local function dorestore(basicenv,stat)
   local m = basicenv._m;
   if #stat then
      m.datapc = 1;
   else
      m.datapc = m.datatargets[stat[2]];
   end
end

local function doread(basicenv,stat)
   local m = basicenv._m;
   for i=2,#stat do
      local lval = stat[i];
      local dat = m.data[m.datapc];
      local value = eval(basicenv,dat);
      local dtype = dat[1];
      if dtype == "FLOATVAL" then
	 assignf(lval, value);
      elseif dtype == "STRING" then
	 assigns(lval, value);
      else
	 error("READ data type "..tostring(lval[1]).." not implemented");
      end
      m.datapc = m.datapc+1;
   end
end

local function dogoto(basicenv,stat)
   local m = basicenv._m;
   m.pc = m.targets[stat[2]]-1;
end
local function dogosub(basicenv,stat)
   local m = basicenv._m;
   table.insert(m.substack,m.pc);
   m.pc = m.targets[stat[2]]-1;
end
local function doreturn(basicenv,stat)
   local m = basicenv._m;
   m.pc = table.remove(m.substack);
end
local function dodef(basicenv,stat)
   basicenv["FN"..stat[2]] = {args = stat[3], expr = stat[4]};
end

statements.TARGET    = function(basicenv,stat) basicenv._m.basiclineno = stat[2]; end;
statements.END       = function(basicenv,stat) basicenv._m.quit = true; end;
statements.REM       = function(basicenv,stat) end; -- Do nothing
statements.DIM       = dodim;
statements.DATA      = function(basicenv,stat) end; -- Do nothing at runtime
statements.RESTORE   = dorestore;
statements.READ      = doread;
statements.DEF       = dodef;
statements.LETN      = doletn;
statements.LETS      = dolets;
statements.IF        = doif;
statements.GOTO      = dogoto;
statements.GOSUB     = dogosub;
statements.RETURN    = doreturn;
statements.FOR       = dofor;
statements.NEXT      = donext;
statements.ON        = doon;
statements.PRINT     = doprint;
statements.INPUT     = doinput;
statements.RANDOMIZE = rtl.dorandomize;

local function exec(basicenv,stat)
   local cmd = statements[stat[1]];
   if cmd == nil then
      error("Unknown statement "..stat[1]);
   end
   cmd(basicenv,stat);
   basicenv._m.pc = basicenv._m.pc + 1;
end

if nerr == 0 and mode == 2 then
   while true do
      local prog = basicenv._m.prog;
      local status, err = pcall(
	 function () exec(basicenv,prog[basicenv._m.pc]) end
      );
      if not status then
	 print("At BASIC line "..basicenv._m.basiclineno);
	 print(err);
	 basicenv._m.quit = true;
      end
      if basicenv._m.quit or basicenv._m.pc > #prog then
	 -- Run off end of program
	 break;
      end
   end
end
