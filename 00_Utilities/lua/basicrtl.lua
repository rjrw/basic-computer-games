local m = {};

local parser = require"basicparser";
-- local _ENV = require 'std.strict' (_G)

-- Builtin function table

local function abs(x)
   if x < 0 then
      return -x;
   end
   return x;
end

local function len(x)
   return #x;
end

local function sgn(x)
   if x < 0 then
      return -1;
   end
   return 1;
end

local function spc(x)
   return string.rep(" ",x);
end

local builtins =
   { ABS = abs, ASC = string.byte, ATN = math.atan, COS = math.cos,
     EXP = math.exp, INT = math.floor, LEN=len, LOG = math.log, SGN = sgn,
     SIN = math.sin, SPC = spc, SQR = math.sqrt,
     TAN = math.tan, VAL=tonumber };

m.builtins = builtins;

do
   local builtins = m.builtins;
   builtins["s_CHR"] = string.char;
   builtins["s_LEFT"] = function(s,j) return s:sub(1,j) end
   builtins["s_RIGHT"] = function(s,j) return s:sub(-j) end
   builtins["s_STR"] = tostring
   builtins["s_MID"] = function(...)
      local s, i, j = ...;
      if j then
	 return s:sub(i,i+j-1)
      end
      return s:sub(i);
   end
   
   local function makernd()
      local rndval=0.1;
      local function RND(arg)
	 if arg <= 0 then
	    math.randomseed(math.floor(-arg));
	 end
	 if arg ~= 0 then
	    rndval = math.random();
	 end
	 return rndval;
      end
      local function randomize()
	 local now = os.time();
	 local date = os.date("*t",now);
	 local midnight = os.time{year=date.year, month=date.month,
				  day=date.day, hour=0};
	 rndval = math.randomseed(math.floor(midnight-now));
      end
      return RND, randomize;
   end
   builtins.RND, dorandomize = makernd();
end


local function printtab(basicenv,n)
   n = math.floor(n);
   local m = basicenv._m;
   local printstr = ""
   if n > m.printcol then
      printstr = string.rep(" ",n-m.printcol);
   end
   return printstr;
end

local ops = {};

local function eval(basicenv,expr)
   local t = type(expr);
   if t == "number" or t == "string" then
      return expr;
   end
   if t ~= "table" then
      error("Parser failure, found expression of type "..t);
   end
   local op = ops[expr[1]] or
      error("Bad expr "..tostring(expr[1]));
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
   local val = eval(basicenv,expr[3]);
   if expr[2] == "-" then
	 return -val;
   end
   return val;
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

local function dochunk(basicenv,expr)
   if not expr.__cache then
      local chunk = "_ENV=...; return "..expr[2];
      expr.__cache = load(chunk);
   end
   return expr.__cache(basicenv);
end

local function dofloatvar(basicenv,expr)
   return basicenv[expr[2]];
end

local function dofloatlvar(basicenv,expr)
   return expr[2];
end

local function doexpr(basicenv,expr)
   return eval(basicenv,expr[2]);
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
      return printtab(basicenv,args[1]);
   end
   local builtins = builtins;
   local builtin = exprtype == "FLOATARR" and
      builtins[name] or builtins["s_"..name];
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
   if not val then
      error("Array "..name.." not known");
   end
   for _, v in ipairs(args) do
      if v < 0 or v > #val then
	 error("Out of bounds array access");
      end
      val = val[v];
   end
   return val;
end

local function dostringindex(basicenv,expr)
   local name = expr[2][2];
   local exprtype = expr[2][1];
   local arglist = expr[3];
   local args = {};
   for k,v in ipairs(expr[3]) do
      args[#args+1] = eval(basicenv,v);
   end
   local builtins = builtins;
   local builtin = exprtype == "FLOATARR" and
      builtins[name] or builtins["s_"..name];
   if builtin then
      return builtin(table.unpack(args));
   end
   local val = basicenv["sa_"..name] or
      error("Array "..name.."$ not known");
   for _, v in ipairs(args) do
      if v < 0 or v > #val then
	 error("Out of bounds array access");
      end
      val = val[v];
   end
   return val;
end

local function f2l(val)
   return val ~= 0;
end
local function l2f(val)
   return val and -1 or 0;
end

local function door(basicenv,expr)
   local val = f2l(eval(basicenv,expr[2]));
   for i=3,#expr do
      val = val or f2l(eval(basicenv,expr[i]));
   end
   return l2f(val);
end

local function doand(basicenv,expr)
   local val = f2l(eval(basicenv,expr[2]));
   for i=3,#expr do
      val = val and f2l(eval(basicenv,expr[i]));
   end
   return l2f(val);
end

local function donot(basicenv,expr)
   local val = eval(basicenv,expr[2]);
   return l2f(~f2l(val));
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
ops.COMPARE   = docompare;
ops.FLOATVAL  = dofloatval;
ops.FLOATVAR  = dofloatvar;
ops.FLOATLVAR = dofloatlvar;
ops.STRINGVAR = dostringvar;
ops.INDEX     = doindex;
ops.STRINGINDEX = dostringindex;
ops.FUNCALL   = dofuncall;
ops.CHUNK     = dochunk;
ops.EXPR      = doexpr;

local write = io.write;

local function assigns(basicenv,lval,value)
   local ttype = lval[1];
   local label = lval[2];
   if ttype == "STRINGELEMENT" then
      if #lval[3] > 2 then
	 error("More than 2-dimensional access not yet implemented");
      end
      local eltype = label[1];
      if eltype ~= "STRINGARR" then
	 error("Non-string access not yet implemented");
      end
      if #lval[3] == 1 then
	 local index = eval(basicenv,lval[3][1]);
	 basicenv["sa_"..label[2]][index] = value;
      else
	 local i1, i2 = eval(basicenv,lval[3][1]),eval(basicenv,lval[3][2]);
	 basicenv["sa_"..label[2]][i1][i2] = value;
      end
   else
      basicenv["s_"..label] = value;
   end
end

local function assignf(basicenv,lval,value)
   if lval[1] == "FLOATLVAR" then
      lval = lval[2];
   end
   local ttype = lval[1];
   local label = lval[2];
   if ttype == "FLOATVAR" then
      basicenv[label] = value;
   elseif ttype == "ELEMENT" then
      if #lval[3] > 2 then
	 error("More than 2-dimensional access not yet implemented");
      end
      local eltype = label[1];
      if eltype ~= "FLOATARR" then
	 error("Non-floating access not yet implemented");
      end
      local arrname = "fa_"..label[2];
      if #lval[3] == 1 then
	 -- Create default size array
	 local index = eval(basicenv,lval[3][1]);
	 if basicenv[arrname] == nil then
	    local store = {};
	    for j = 0, 10 do
	       store[j] = 0.0;
	    end
	    basicenv[arrname] = store;
	 end
	 basicenv[arrname][index] = value;
      else
	 local i1, i2 = eval(basicenv,lval[3][1]),eval(basicenv,lval[3][2]);
	 basicenv[arrname][i1][i2] = value;
      end
   else
      error("Type mismatch in floating assignment");
   end
end

local function donothing(basicenv,stat)
end

-- Literals
local function dofloatval(basicenv, stat)
   return tonumber(stat[2]);
end

local function dostring(basicenv, stat)
   return stat[2];
end

-- Definitions
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
      if dimtype == "FLOATARR" then
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

local function dodef(basicenv,stat)
   basicenv["FN"..stat[2][2]] = {args = stat[3], expr = stat[4]};
end

-- Assignments
local function doletn(basicenv,stat)
   local lval = stat[2];
   local expr = stat[3];
   assignf(basicenv,lval,eval(basicenv,expr))
end
local function dolets(basicenv,stat)
   local lval = stat[2];
   local expr = stat[3];
   assigns(basicenv,lval,eval(basicenv,expr))
end

-- Control flow: END, GOTO, GOSUB/RETURN, IF, ON, FOR/NEXT
local function doend(basicenv,stat)
   basicenv._m.quit = true;
end

-- Utilities: m_goto/ m_gosub
local function m_goto(basicenv,label)
   local m = basicenv._m;
   m.pc = m.labels[label]-1;
end
local function m_gosub(basicenv,label)
   local m = basicenv._m;
   table.insert(m.substack,m.pc);
   m_goto(basicenv,label);
end

local function dogoto(basicenv,stat)
   m_goto(basicenv,stat[2]);
end

local function dogosub(basicenv,stat)
   local m = basicenv._m;
   m_gosub(basicenv,stat[2]);
end

local function doreturn(basicenv,stat)
   local m = basicenv._m;
   m.pc = table.remove(m.substack);
end

local function doif(basicenv,stat)
   -- Logic is inverted, as machine default is to fall through to next
   -- operation
   local test = stat[2];
   if f2l(eval(basicenv,test)) then
      m_goto(basicenv,stat[3]);
   else
      m_goto(basicenv,stat[4]);
   end
end

local function doon(basicenv,stat)
   local switch = math.floor(eval(basicenv,stat[2]));
   local m = basicenv._m;
   local loc = 3+switch;
   if switch > 0 and loc <= #stat then
      if stat[3] == "GOTO" then
	 m_goto(basicenv,stat[loc]);
      else
	 m_gosub(basicenv,stat[loc]);
      end
   end
end

local function dofor(basicenv,stat)
   local control = stat[2][2][2];
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
	 local var = stat[i][2];
	 if var[1] ~= "FLOATVAR" then
	    error("NEXT tag must be floating variable");
	 end
	 local frame = forstack[#forstack];
	 local control = frame[2];
	 while control ~= var[2] do
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

-- Internal data: READ/RESTORE
local function doread(basicenv,stat)
   local m = basicenv._m;
   for i=2,#stat do
      if m.datapc > #m.data then
	 error("Error: out of data"); 
      end
      local dat = m.data[m.datapc];
      local value = eval(basicenv,dat);
      local dtype = type(dat)
      local lval = stat[i];
      if dtype == "number" then
	 assignf(basicenv,lval, value);
      elseif dtype == "string" then
	 assigns(basicenv,lval, value);
      else
	 error("READ data type "..dtype.." not implemented");
      end
      m.datapc = m.datapc+1;
   end
end

local function dorestore(basicenv,stat)
   local m = basicenv._m;
   if #stat then
      m.datapc = 1;
   else
      m.datapc = m.datalabels[stat[2]];
   end
end

-- Input/output PRINT/INPUT
local function doprint(basicenv,stat)
   local printlist=stat[2];
   local m = basicenv._m;
   local printstr="";
   local flush = true;
   local j = 1;
   for j=1,#printlist do
      local element = printlist[j]
      flush = true;
      local val = "";
      if element[1] == "PRINTSEP" then
	 if element[2] == ";" then
	    flush = false;
	 elseif element[2] == "," then
	    local newcol = 14*(math.floor(m.printcol/14)+1);
	    val = printtab(basicenv,newcol);
	    flush = false;
	 end
      elseif element[1] == "PRINTVAL" then
	 val = eval(basicenv,element[2]);
	 if type(val) == "number" then
	    if val>=0 then
	       val = " "..tostring(val).." ";
	    else
	       val = tostring(val).." ";
	    end
	 end
      else
	 error("Unknown printexpr type "..element[1]);
      end
      printstr = printstr..val;
      m.printcol = m.printcol + #val;
   end
   write(printstr);
   if flush then
      write("\n");
      m.printcol = 0;
   end
end
local function doinput(basicenv,inputlist)
   local i=2;
   local prompt = "? ";
   if inputlist[i] == "PROMPT" then
      prompt = eval(basicenv,inputlist[i+1])..prompt;
      i=i+2;
   end
   -- Cursor will move back to l.h.s. once input is accepted
   basicenv._m.printcol = 0;
   local j = i;
   local fields = {};
   local input = "";
   while i+#fields <= #inputlist do
      if j == i then
	 write(prompt);
      else
	 write("?? ");
      end
      local next = io.read("*l");
      if input ~= "" then
	 next = input..","..next
      end
      fields = parser.input:match(next);
      if not fields then
	 write("Error, input format not recognized\n");
	 fields = {};
      else
	 input = next;
      end
   end
   for iv,v in ipairs(fields) do
      local input = v[2];
      local item = inputlist[j];
      if item[1] == "FLOATLVAR" then
	 item = item[2];
      end
      local vartype = item[1];
      local varname = item[2];
      if vartype == "STRINGVAR" or vartype == "STRINGELEMENT" then
	 assigns(basicenv,item,input);
      elseif vartype == "FLOATVAR" or vartype == "ELEMENT" then
	 if v[1] == "STRING" then
	    write("Error, expected numeric input -- retry input line\n");
	    j = i;
	    break;
	 end
	 assignf(basicenv,item,tonumber(input));
      else
	 error("Vartype "..vartype.." not yet supported");
      end
      j = j+1;
      if j > #inputlist then
	 if iv ~= #fields then
	    write("Extra input text ignored\n");
	 end
	 return
      end
      --print(inputlist[j][1]);
   end
end

local function exec(basicenv,stat)
   basicenv.lineno = stat.line;
   basicenv.pos = stat.pos;
   local m = basicenv._m;
   local cmd = m.statements[stat[1]] or
      error("Unknown statement "..stat[1]);
   cmd(basicenv,stat);
end

local function doblock(basicenv,stat)
   local blockstats = stat[2];
   for _,stat in ipairs(blockstats) do
      exec(basicenv, stat);
   end
end

-- Machine state
-- Symbol table -> environment
-- Loose names are floats, fa_xxx is floating array, s_xxx is string,
-- sa_xxx is string array
local function makemachine(prog, data, datalabels)
   local statements = {
      LABEL     = donothing,
      END       = doend,
      REM       = donothing,
      FLOATVAL  = dofloatval,
      STRING    = dostring,
      DIM       = dodim,
      DATA      = donothing,
      RESTORE   = dorestore,
      READ      = doread,
      DEF       = dodef,
      LETN      = doletn,
      LETS      = dolets,
      GOTO      = dogoto,
      GOSUB     = dogosub,
      RETURN    = doreturn,
      FOR       = dofor,
      NEXT      = donext,
      ON        = doon,
      PRINT     = doprint,
      INPUT     = doinput,
      RANDOMIZE = dorandomize,
      IF        = doif,
      BLOCK     = doblock      
   };
   -- Create jump table
   local labels = {};
   for k,v in ipairs(prog) do
      if v[1] == "LABEL" then
	 labels[v[2]] = k;
      end
   end

   return {
      prog = prog,
      labels = labels,
      data = data,
      datalabels = datalabels,
      statements = statements,
      pc = 1,
      datapc = 1,
      quit = false,
      substack = {},
      forstack = {},
      lineno = 0,
      -- Output state
      printcol = 0,
   };
end

local function run(prog, data, datalabels)
   local basicenv = {
      _m=makemachine(prog, data, datalabels)
   };
   
   basicenv.TAB=function(n) return printttab(basicenv, n); end;

   while true do
      local m = basicenv._m;
      local status, err = pcall(
	 function () exec(basicenv,prog[m.pc]) end
      );
      m.pc = m.pc + 1;
      if not status then
	 local errorlocation = "BASIC line "..
	    tostring(basicenv.lineno)..":"..tostring(basicenv.pos);
	 print("At "..errorlocation);
	 print(err);
	 m.quit = true;
      end
      if m.quit or m.pc > #prog then
	 -- Run off end of program
	 return;
      end
   end
end

m.run = run;
m.ops = ops;
m.eval = eval;

return m;
