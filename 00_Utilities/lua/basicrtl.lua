local m = {};

local parser = require"basicparser";

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
   if n > m.printcol then
      m.printstr = m.printstr..string.rep(" ",n-m.printcol);
      m.printcol = n;
   end
   return "";
end

local ops = {};

local function eval(basicenv,expr)
   local t = type(expr);
   if t == "number" or t == "string" then
      return expr;
   end
   if type(expr) ~= "table" then
      error("Parser failure");
   end
   local op = ops[expr[1]];
   if not op then
      error("Bad expr "..tostring(expr[1]));
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
   local chunk = "_ENV=...; return "..expr[2];
   return load(chunk)(basicenv);
end

local function dofloatvar(basicenv,expr)
   return basicenv[expr[2]] and basicenv[expr[2]] or 0;
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
   local builtins = builtins;
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
   local builtins = builtins;
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
ops.STRINGVAR = dostringvar;
ops.INDEX     = doindex;
ops.STRINGINDEX = dostringindex;
ops.FUNCALL   = dofuncall;
ops.CHUNK     = dochunk;

local write = io.write;

local function assigns(basicenv,lval,value)
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

local function assignf(basicenv,lval,value)
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

local function doinput(basicenv,inputlist)
   local i=2;
   local prompt = "? ";
   if inputlist[i] == "PROMPT" then
      prompt = eval(basicenv,inputlist[i+1])..prompt;
      i=i+2;
   end
   local j = i;
   while j <= #inputlist do
      local input = "";
      while input == "" do
	 if j == i then
	    write(prompt);
	 else
	    write("?? ");
	 end
	 input = io.read("*l");
      end
      local fields = parser.input:match(input);
      if not fields then
	 write("Error, input format not recognized\n");
      else
	 for iv,v in ipairs(fields) do
	    local input = v[2];
	    local vartype = inputlist[j][1];
	    local varname = inputlist[j][2];
	    if vartype == "STRINGVAR" or vartype == "STRINGELEMENT" then
	       assigns(basicenv,inputlist[j],input);
	    elseif vartype == "FLOATVAR" or vartype == "ELEMENT" then
	       if v[1] == "STRING" then
		  write("Error, expected numeric input -- retry input line\n");
		  j = i;
		  break;
	       end
	       assignf(basicenv,inputlist[j],tonumber(input));
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

local function doon(basicenv,stat)
   local switch = math.floor(eval(basicenv,stat[2]));
   local m = basicenv._m;
   if switch > 0 and switch+2 <= #stat then
      m.pc = m.targets[stat[2+switch]]-1;
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
	 assignf(basicenv,lval, value);
      elseif dtype == "STRING" then
	 assigns(basicenv,lval, value);
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
local function doend(basicenv,stat)
   basicenv._m.quit = true;
end
local function donothing(basicenv,stat)
end

local function exec(basicenv,stat)
   local m = basicenv._m;
   local cmd = m.statements[stat[1]];
   if cmd == nil then
      error("Unknown statement "..stat[1]);
   end
   cmd(basicenv,stat);
end

local function doif(basicenv,stat)
   local test = stat[2];
   if f2l(eval(basicenv,test)) then
      -- If true, run sub-statement and fall through to rest of line
      local substat = stat[3];
      exec(basicenv,substat);
   else
      -- Jump over rest of line
      local m = basicenv._m;
      m.pc = m.targets[stat[4]]-1;
   end
end


-- Machine state
-- Symbol table -> environment
-- Loose names are floats, fa_xxx is floating array, s_xxx is string,
-- sa_xxx is string array
local function makemachine(prog, data, datatargets)
   local statements = {
      TARGET    = donothing,
      END       = doend,
      REM       = donothing,
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
      IF        = doif
   };
   -- Create jump table
   local targets = {};
   for k,v in ipairs(prog) do
      if v[1] == "TARGET" then
	 targets[v[2]] = k;
      end
   end

   return {
      prog = prog,
      targets = targets,
      data = data,
      datatargets = datatargets,
      statements = statements,
      pc = 1,
      datapc = 1,
      quit = false,
      substack = {},
      forstack = {},
      -- Output state
      printstr = "",
      printcol = 0
   };
end

local function run(prog, data, datatargets)
   local basicenv = {_m=makemachine(prog, data, datatargets)};
   while true do
      local m = basicenv._m;
      local lineno = prog[m.pc].line;
      local status, err = pcall(
	 function () exec(basicenv,prog[m.pc]) end
      );
      m.pc = m.pc + 1;
      if not status then
	 local errorlocation = "BASIC line "..tostring(lineno);
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

return m;
