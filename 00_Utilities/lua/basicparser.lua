local m = {};

local lpeg = require"lpeg";

-- Cache values for expr rule, to speed up run time
local basicexpr;
local function makematchexpr()
   local cache = {};
   local function matchexpr(s, p)
      -- Clear cache if subject has changed
      if cache.subject ~= s then
	 cache.subject = s;
	 cache.vals = {};
      end
      if cache.vals[p] == nil then
	 local captures, endpoint = basicexpr:match(s,p-1);
	 if captures == nil then
	    cache.vals[p] = {nil};
	 else
	    table.insert(captures,1,endpoint);
	    cache.vals[p] = captures;
	 end
      end
      return table.unpack(cache.vals[p]);
   end
   return matchexpr;
end
local matchexpr = makematchexpr();

-- Literals
local any = lpeg.P(1);
local space = lpeg.S" \t"^0;
local digit = lpeg.R("09");
local float = lpeg.P("-")^0 *
   (digit^0 * lpeg.P(".") * digit^1 + digit^1 * lpeg.P(".")^-1) *
   (lpeg.P("E")*lpeg.S("+-")^-1*digit^1)^-1;
local lineno = lpeg.C(digit^1);
local varname = lpeg.C(lpeg.R("AZ")^1 * lpeg.R("09")^0);
local comparisonop = lpeg.C(lpeg.P("=") + lpeg.P("<>") + lpeg.P("<=") +
			       lpeg.P(">=") + lpeg.P("<") + lpeg.P(">"));

-- Labelled literals
local stringval = lpeg.Ct(
   lpeg.Cc("STRING")*lpeg.P("\"") * lpeg.C((any-lpeg.P("\""))^0) *
      lpeg.P("\""));
local floatval = lpeg.Ct(lpeg.Cc("FLOATVAL")*lpeg.C(float));

local floatvar  = lpeg.Ct(lpeg.Cc("FLOATVAR") * varname);
local floatlvar = lpeg.Ct(lpeg.Cc("FLOATLVAR") * floatvar);
local floatarr  = lpeg.Ct(lpeg.Cc("FLOATARR") * varname);
local stringname = varname * lpeg.P("$");
local stringvar = lpeg.Ct(lpeg.Cc("STRINGVAR")*stringname);
local stringarr = lpeg.Ct(lpeg.Cc("STRINGARR")*stringname);


local word = (any-lpeg.S(", \t"))^1;
local wordlist = (word * lpeg.S" \t"^1 * #word)^0*word;
local unquotedstringval = lpeg.Ct(lpeg.Cc("STRING")*lpeg.C(wordlist));
local dataliteral = floatval + stringval + unquotedstringval;
local datalist = space * ( dataliteral * space * lpeg.P(",") * space ) ^0 *
   dataliteral * space;
local nextlist = ( floatlvar * space * lpeg.P"," * space)^0 * floatlvar * space;

local stringexpr = lpeg.V"stringexpr";
local concat = lpeg.V"concat";
local printexpr = lpeg.V"printexpr";
local printlist = lpeg.V"printlist";
local inputitem = lpeg.V"inputitem";
local inputlist = lpeg.V"inputlist";
local dimlist = lpeg.V"dimlist";
local dimitem = lpeg.V"dimitem";

-- Expression terms
local Sum = lpeg.V"Sum";
local Product = lpeg.V"Product"
local Power = lpeg.V"Power"
local Unary = lpeg.V"Unary";
local Value = lpeg.V"Value";
local Or = lpeg.V"Or";
local And = lpeg.V"And";
local Not = lpeg.V"Not";
local ifstatement = lpeg.V"ifstatement";
local ifstart = lpeg.V"ifstart";
local expr = lpeg.V"expr";
local rawexpr = lpeg.V"rawexpr";
local comparison = lpeg.V"comparison";
local floatlval = lpeg.V"floatlval";
local floatrval = lpeg.V"floatrval";
local stringlval = lpeg.V"stringlval";
local stringrval = lpeg.V"stringrval";
local stringelement = lpeg.V"stringelement";
local arg = lpeg.V"arg";
local arglist = lpeg.V"arglist";
local dummylist = lpeg.V"dummylist";
local exprlist = lpeg.V"exprlist";
local element = lpeg.V"element";
local index = lpeg.V"index";
local funcall = lpeg.V"funcall";
local stringindex = lpeg.V"stringindex";

-- Statements
local datastatement   = lpeg.C(lpeg.P("DATA")) * datalist;
local gotostatement   = lpeg.Cc("GOTO") * lpeg.P("GO") * space *
   lpeg.P("TO") * space * lineno * space;
local gosubstatement  = lpeg.Cc("GOSUB") * lpeg.P("GO") * space *
   lpeg.P("SUB") * space * lineno * space;
local nextstatement   = lpeg.C(lpeg.P("NEXT")) * space * nextlist * space +
   lpeg.C(lpeg.P("NEXT"));
local endstatement    = lpeg.C(lpeg.P("END")) * space;
local stopstatement   = lpeg.Cc"END" * lpeg.P("STOP") * space;
local remstatement    = lpeg.C(lpeg.P("REM")) * lpeg.C(any^0);
local returnstatement = lpeg.C(lpeg.P("RETURN")) * space;
local randomizestatement = lpeg.C(lpeg.P("RANDOMIZE")) * space;
local restorestatement = lpeg.C(lpeg.P("RESTORE")) * space *
   (lineno * space)^-1;
local printstatement = lpeg.V"printstatement";
local inputstatement = lpeg.V"inputstatement";
local readstatement = lpeg.V"readstatement";
local numericassignment = lpeg.V"numericassignment";
local stringassignment = lpeg.V"stringassignment";
local dimstatement = lpeg.V"dimstatement";

local forstatement = lpeg.V"forstatement"
local onstatement = lpeg.V"onstatement"
local defstatement = lpeg.V"defstatement";

local statement = lpeg.V"statement";
local statementlist = lpeg.V"statementlist";

-- Subset grammar for use in caching
local exprgrammar = {
   "expr";
   -- Argument lists
   exprlist = lpeg.Ct(( expr * space * lpeg.P(",") * space)^0 * expr),
   -- Expression hierarchy
   expr = rawexpr,
   rawexpr = Or,
   Or = lpeg.Ct(lpeg.Cc("OR") * (And * space * lpeg.P("OR") * space)^1 * And)
      + And,
   And = lpeg.Ct(lpeg.Cc("AND") * (Not * space * lpeg.P("AND") * space)^1 * Not)
      + Not,
   Not = lpeg.Ct(lpeg.C("NOT") * space * comparison) + comparison,
   comparison = lpeg.Ct(
      lpeg.Cc("COMPARE") *
	 ( stringexpr * space * comparisonop * space * stringexpr
	      + ( Sum * space * comparisonop * space)^1 * Sum) ) + Sum,
   Sum = lpeg.Ct(
      lpeg.Cc("SUM") *
	 ( Product * space * lpeg.C(lpeg.S("+-")) * space)^1 * Product) * space
      + Product * space,
   Product = lpeg.Ct(
      lpeg.Cc("PRODUCT") * ( Power * space * lpeg.C(lpeg.S("*/")) * space)^1
	 * Power) * space
      + Power * space,
   Power = lpeg.Ct(
      lpeg.Cc("POWER") * ( Unary * space * lpeg.S("^") * space)^1 * Unary) *
      space
      + Unary * space,
   -- TODO: address ambiguity about the handling of -1 -- is it "-" "1" or "-1"?
   Unary = lpeg.Ct(lpeg.Cc("UNARY") * lpeg.C(lpeg.S("+-")) * Value) + Value,
   Value = floatrval + lpeg.P("(") * space * expr * space * lpeg.P(")"),
   -- String expression hierarchy
   stringexpr = concat,
   concat = lpeg.Ct(
      lpeg.Cc("CONCAT") *
	 (stringrval * space * lpeg.P("+") * space)^1 * stringrval)
      + stringrval,
   -- Lowest-level groups
   floatrval = floatval + funcall + index + floatvar,
   stringrval = stringval + stringindex + stringvar,
   -- Array access/function/builtin call
   arg = stringexpr + expr,
   arglist = lpeg.Ct(( arg * space * lpeg.P(",") * space)^0 * arg),
   funcall = lpeg.Ct(
      lpeg.Cc("FUNCALL") * lpeg.P("FN") * space * floatvar * space *
	 lpeg.P("(") * space * arglist * space * lpeg.P(")")),
   index = lpeg.Ct(
      lpeg.Cc("INDEX") *
	 --lpeg.Cmt(lpeg.P"",
      --function (s,p,c) print("Matching INDEX at",p); return true; end) *
	 floatarr * space *
	 lpeg.P("(") * space * arglist * space * lpeg.P(")")),
   stringindex = lpeg.Ct(
      lpeg.Cc("STRINGINDEX") * stringarr * space *
	 lpeg.P("(") * space * arglist * space * lpeg.P(")")),
};

-- Enable caching in expression grammar, and provide raw (uncached) access
-- Tag is required to provide endpoint to pass on to lpeg.Cmt
exprgrammar.expr = lpeg.Cmt(any,matchexpr);
exprgrammar[1] = "exprtagged";
exprgrammar.exprtagged = lpeg.Ct(rawexpr) * lpeg.Cp();
basicexpr = lpeg.P(exprgrammar);

-- Additional grammar for full line parsing
local linegrammar = {
   "line";
   statement =
      lpeg.Ct(
	 gotostatement + gosubstatement + forstatement + nextstatement
	    + endstatement + stopstatement + printstatement 
	    + returnstatement + dimstatement
	    + inputstatement + endstatement + ifstatement + remstatement
	    + onstatement + datastatement + randomizestatement
	    + restorestatement + readstatement + defstatement
	 -- Assignments need to come late to avoid clashes with other
	 -- statements e.g. IF ((Z+P)/2)= looking like an array
	 -- assignment.
	    + numericassignment + stringassignment ),
   printstatement = lpeg.C(lpeg.P("PRINT")) * space * lpeg.Ct(printlist),
   inputstatement = lpeg.C(lpeg.P("INPUT")) * space *
      (lpeg.Cc("PROMPT") * stringexpr * space * lpeg.P(";") * space)^-1 *
      inputlist,
   readstatement = lpeg.C(lpeg.P("READ")) * space * inputlist,
   ifstatement = lpeg.C(lpeg.P("IF")) * space * expr * space *
      lpeg.P("THEN") * space *
      (lpeg.Ct (lpeg.Cc("GOTO") * lineno) * space + statement),
   dimstatement = lpeg.C(lpeg.P("DIM")) * space * dimlist,
   defstatement = lpeg.C(lpeg.P("DEF")) * space * lpeg.P("FN") * space
      * varname * space *
      lpeg.P("(") * space * dummylist * space * lpeg.P(")")
      * space * lpeg.P("=") * space * expr,
   forstatement =
      lpeg.C(lpeg.P("FOR")) * space * floatlvar * space * lpeg.P("=") * space *
      expr * space * lpeg.P("TO") * space * expr * space *
      ( lpeg.P("STEP") * space * expr * space )^-1,
   onstatement =
      lpeg.C(lpeg.P("ON")) * space * expr * space * lpeg.P("GO") * space *
      (lpeg.P("TO")*lpeg.Cc("GOTO")+lpeg.P("SUB")*lpeg.Cc("GOSUB"))
      * space * (lineno * space * lpeg.P(",") * space)^0 *
      lineno * space,
   numericassignment =
      lpeg.Cc("LETN") * lpeg.P("LET")^-1 * space *
      floatlval * space * lpeg.P("=") * space * expr * space,
   stringassignment =
      lpeg.Cc("LETS") * lpeg.P("LET")^-1 * space *
      stringlval * space * lpeg.P("=") * space * stringexpr * space,
   statementlist = (statement * lpeg.P(":") * space )^0 * statement,
   line = lpeg.Ct(lineno * space * lpeg.Ct(statementlist) * lpeg.Cp()),
   -- lists
   dimitem = lpeg.Ct((stringarr + floatarr) * space *
	 lpeg.P("(") * space * exprlist * space * lpeg.P(")")),
   dimlist = ( dimitem * space * lpeg.P(",") * space)^0 * dimitem,
   printexpr = stringexpr + expr + lpeg.C(lpeg.S(";,")),
   printlist = (printexpr * space )^0,
   inputitem = stringlval + floatlval,
   inputlist = (inputitem * space * lpeg.P(",") * space)^0 * inputitem * space,
   dummylist = lpeg.Ct( (varname*space*lpeg.P(",")*space)^0 * varname),
   -- Element and stringelement are for rvalue array access on
   -- l.h.s. of assignment, distinct from lvalue access in expressions
   element = lpeg.Ct(lpeg.Cc("ELEMENT") * floatarr * space *
			lpeg.P("(") * space * exprlist * space * lpeg.P(")")),
   stringelement = lpeg.Ct(
      lpeg.Cc("STRINGELEMENT") * stringarr * space *
	 lpeg.P("(") * space * exprlist * space * lpeg.P(")")),
   -- Lowest-level groups
   floatlval = element + floatvar,
   stringlval = stringelement + stringvar, 
};


-- Merge in expression grammar, as there are routes in other
-- than "expr" (i.e. exprlist and stringexpr)
for k,v in pairs(exprgrammar) do
   if k ~= 1 then
      linegrammar[k] = v;
   end
end

-- Enable caching in line grammar as well
linegrammar.expr = lpeg.Cmt(any,matchexpr);
local basicline = lpeg.P(linegrammar);

-- Functions for walking and refactoring parser output
local function applystat(v,op)
   op(v);
   if v[1] == "IF" then
      applystat(v[3],op);
   end
end

local function applyprog(prog,op)
   for _,v in ipairs(prog) do
      applystat(v,op);
   end
end

local function ifconnect(v,endlab)
   function op(v)
      if v[1] == "IF" then
	 v[#v+1] = endlab;
      end
   end
   applystat(v,op);
end

local function parse(lines, optimize)
   local prog, data, datatargets = {}, {}, {};
   local nerr = 0;
   
   -- Parse input file
   for count,line in ipairs(lines) do
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
	    local lineno = m[1];
	    prog[#prog+1] = {"TARGET",lineno};
	    local hasif = false;
	    local endlab = "_"..lineno;
	    for k,v in ipairs(m[2]) do
	       --print(">>",k,v[1]); --Confirm first-level commands are captured
	       if v[1] == "DATA" then
		  datatargets[m[1]] = #data+1;
		  for i = 2, #v do
		     if v[i][1] == "FLOATVAL" then
			table.insert(data,tonumber(v[i][2]));
		     else
			table.insert(data,v[i][2]);
		     end
		  end
	       else
		  if v[1] == "IF" then
		     hasif = true;
		  end
		  ifconnect(v,endlab);
		  v.line = lineno;
		  prog[#prog+1] = v;
	       end
	    end
	    if hasif then
	       prog[#prog+1] = {"TARGET",endlab};
	    end
	 end
      end      
   end

   -- Merge adjacent targets and patch over jumps to undefined targets
   local targetuniq, targ, lastt = {}, "", "";
   for i=#prog,1,-1 do
      local v = prog[i];
      if v[1] ~= "TARGET" then
	 targ = "";
      else
	 if lastt == "" then
	    lastt = v[2];
	 end
	 if targ == "" then
	    targ = v[2];
	 end
	 targetuniq[v[2]]=targ;
      end
   end
   local function fixtarget(v, i, targetuniq)
      local target = v[i];
      if targetuniq[target] == nil then
	 print("Warning: Found jump to missing target "..target..
		  " at BASIC line "..v.line);
      end
      while targetuniq[target] == nil do
	 target = string.format("%d",1+target);
	 if target == lastt then
	    break;
	 end
      end
      return targetuniq[target];
   end
   
   local function retarget(v)
      if v[1] == "GOTO" or v[1] == "GOSUB" then
	 v[2] = fixtarget(v, 2, targetuniq);
      elseif v[1] == "ON" then
	 for i = 4,#v do
	    v[i] = fixtarget(v, i, targetuniq);
	 end
      elseif v[1] == "IF" then
	 v[#v] = fixtarget(v, #v, targetuniq);
      end
   end
   applyprog(prog,retarget);
   
   -- Remove unused targets to highlight basic blocks
   local function findusedtargets(prog)
      local usedtargets = {};
      function op(v)
	 if v[1] == "GOTO" or v[1] == "GOSUB" then
	    usedtargets[v[2]] = true;
	 elseif v[1] == "ON" then
	    for i = 4,#v do
	       usedtargets[v[i]] = true;
	    end
	 elseif v[1] == "IF" then
	    usedtargets[v[#v]] = true;
	 end
      end
      applyprog(prog,op);
      return usedtargets;
   end
   
   local usedtargets = findusedtargets(prog);
   local prog1 = {}; 
   for _,v in ipairs(prog) do
      if v[1] ~= "TARGET" or usedtargets[v[2]] then
	 prog1[#prog1+1] = v;
      end
   end
   prog = prog1;
   
   local function apply(prog, op)
      for k,v in ipairs(prog) do
	 local r, v1 = op(v);
	 if r then
	    prog[k] = v1;
	 elseif type(v) == "table" then
	    apply(v, op);
	 end
      end
   end

   -- Ensure all floating variables in program are initialized
   local floatvars = {};
   local function findvars(v)
      if type(v) == "table" and v[1] == "FLOATVAR" then
	 floatvars[v[2]] = true;
      end
      return false;
   end
   apply(prog,findvars);
   local floatkeys = {};
   for k,_ in pairs(floatvars) do
      table.insert(floatkeys,k);
   end
   table.sort(floatkeys);
   local defs = {};
   for _,v in ipairs(floatkeys) do
      local let = {"LETN",{"FLOATVAR",v},{"FLOATVAL",0},line="0"};
      table.insert(defs,let);
   end
   for _,v in ipairs(prog) do
      table.insert(defs,v);
   end
   prog = defs;

   if optimize then
      local function oplit(v)
	 if v[1] == "FLOATVAL" then
	    return true, tonumber(v[2]);
	 elseif v[1] == "STRING" then
	    return true, v[2];
	 end
	 return false;
      end
      apply(prog, oplit);

      -- Not correct yet, would be enabled by apply(prog, opfloatvar)
      -- below
      local function makechunk(v)
	 return "("..v..")";
      end
      -- Need to only apply this to rvalues at present
      local function opfloatvar(v)
	 if type(v)~="table" then
	    return false;
	 elseif v[1] == "FLOATLVAR" or
	    -- Need to be more discriminating about contexts where
	    -- this change isn't applicable
	    v[1] == "LETN" and v[2][1] == "FLOATVAR" or
	    v[1] == "INPUT" or
	    v[1] == "READ" or	    
	 v[1] == "FUNCALL" then
	    return true, v;
	 elseif v[1] == "FLOATVAR" then
	    --print (makechunk(v[2]));
	    return true, { "CHUNK", makechunk(v[2]) };
	 end
	 return false;
      end
      -- Start on compilation, need to distinguish array and variable
      -- access, and probably control via flag
      apply(prog, opfloatvar);
   end
   
   if nerr ~= 0 then
      error("Parser failure");
   end
   return prog, data, datatargets;
end

-- Cut-down grammar just for reading user input
local input = lpeg.P{
   "input";
   input = lpeg.Ct(datalist)
};

m.parse = parse;
m.input = input;

return m;
