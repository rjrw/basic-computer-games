local m = {};

local lpeg = require"lpeg";

local any = lpeg.P(1);
local space = lpeg.S" \t"^0;
local digit = lpeg.R("09");
local stringval =
   lpeg.Ct(lpeg.Cc("STRING")*lpeg.P("\"") * lpeg.C((any-lpeg.P("\""))^0) * lpeg.P("\""));
local float = lpeg.P( lpeg.P("-")^0 * (digit^0 * lpeg.P(".") * digit^1 + digit^1 * lpeg.P(".")^-1) *(lpeg.P("E")*lpeg.S("+-")^-1*digit^1)^-1);
local floatval = lpeg.Ct(lpeg.Cc("FLOATVAL")*lpeg.C(float));
local varname = lpeg.R("AZ")^1 * lpeg.R("09")^0;
local floatvar = lpeg.Ct(lpeg.Cc("FLOATVAR")*lpeg.C(varname));
local stringvar = lpeg.Ct(lpeg.Cc("STRINGVAR")*lpeg.C(varname) * lpeg.P("$"));
local anyvar = lpeg.P { stringvar + floatvar };
local lineno = lpeg.C(digit^1);
local gotostatement = lpeg.P {
   lpeg.Cc("GOTO") * lpeg.P("GO") * space * lpeg.P("TO") * space * lineno * space
};
local dataliteral = lpeg.P {
   floatval + stringval
      + lpeg.Ct(lpeg.Cc("STRING")*lpeg.C((any-lpeg.S(", \t"))^0))
};
local datalist = lpeg.P {
   space * ( dataliteral * space * lpeg.P(",") * space ) ^0 *
      dataliteral * space
};
local input = lpeg.P{
   "input";
   input = lpeg.Ct(datalist)
};
local datastatement = lpeg.P {
   lpeg.C(lpeg.P("DATA")) * datalist
};
local gosubstatement = lpeg.P {
   lpeg.Cc("GOSUB") * lpeg.P("GO") * space * lpeg.P("SUB") * space * lineno * space
};
local nextlist = lpeg.P {
   ( floatvar * space * lpeg.P"," * space)^0 * floatvar * space
};
local nextstatement = lpeg.P {
   lpeg.C(lpeg.P("NEXT")) * space * nextlist * space +
   lpeg.C(lpeg.P("NEXT"))
};
local endstatement = lpeg.P {
   lpeg.C(lpeg.P("END")) * space
};
local stopstatement = lpeg.P {
   lpeg.Cc"END" * lpeg.P("STOP") * space
};
local remstatement = lpeg.P {
   lpeg.C(lpeg.P("REM")) * lpeg.C(any^0)
};
local returnstatement = lpeg.P {
   lpeg.C(lpeg.P("RETURN")) * space
};
local randomizestatement = lpeg.P {
   lpeg.C(lpeg.P("RANDOMIZE")) * space
};
local restorestatement = lpeg.P {
   lpeg.C(lpeg.P("RESTORE")) * space * (lineno * space)^-1
};
local stringexpr = lpeg.V"stringexpr";
local concat = lpeg.V"concat";
local stringassignment = lpeg.V"stringassignment";
local printexpr = lpeg.V"printexpr";
local printlist = lpeg.V"printlist";
local printstatement = lpeg.V"printstatement";
local inputstatement = lpeg.V"inputstatement";
local readstatement = lpeg.V"readstatement";
local inputlist = lpeg.V"inputlist";
local inputitem = lpeg.V"inputitem";

local comparisonop = lpeg.P {
   lpeg.C(lpeg.P("=") + lpeg.P("<>") + lpeg.P("<=") + lpeg.P(">=") + lpeg.P("<") + lpeg.P(">"))
};
local Sum = lpeg.V"Sum";
local Product = lpeg.V"Product"
local Power = lpeg.V"Power"
local Unary = lpeg.V"Unary";
local Value = lpeg.V"Value";
local Or = lpeg.V"Or";
local And = lpeg.V"And";
local Not = lpeg.V"Not";
local Statement = lpeg.V"Statement";
local ifstatement = lpeg.V"ifstatement";
local ifstart = lpeg.V"ifstart";
local expr = lpeg.V"expr";
local rawexpr = lpeg.V"rawexpr";
local numericassignment = lpeg.V"numericassignment";
local dimstatement = lpeg.V"dimstatement";
local dimlist = lpeg.V"dimlist";
local dimdef = lpeg.V"dimdef";
local forstatement = lpeg.V"forstatement"
local onstatement = lpeg.V"onstatement"
local defstatement = lpeg.V"defstatement";
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
local statement = lpeg.V"statement";
local statementlist = lpeg.V"statementlist";
local linegrammar = {
   "line";
   statement =
      lpeg.Ct(
	 gotostatement + gosubstatement + forstatement + nextstatement
	    + endstatement + stopstatement + printstatement 
	    + returnstatement + dimstatement
	    + inputstatement + endstatement + ifstatement + remstatement
	    + onstatement + datastatement + randomizestatement + restorestatement
	    + readstatement + defstatement
	 -- Assignments need to come late to avoid clashes with other statements
	 -- e.g. IF ((Z+P)/2)= looking like an array assignment.
	    + numericassignment + stringassignment ),
   printstatement = lpeg.C(lpeg.P("PRINT")) * space * lpeg.Ct(printlist),
   inputstatement = lpeg.C(lpeg.P("INPUT")) * space *
      (lpeg.Cc("PROMPT") * stringexpr * space * lpeg.P(";") * space)^-1 * inputlist,
   readstatement = lpeg.C(lpeg.P("READ")) * space * inputlist,
   ifstatement = lpeg.C(lpeg.P("IF")) * space * expr * space *
      lpeg.P("THEN") * space * (lpeg.Ct (lpeg.Cc("GOTO") * lineno) * space + statement),
   dimstatement = lpeg.C(lpeg.P("DIM")) * space * dimlist,
   defstatement = lpeg.C(lpeg.P("DEF")) * space * lpeg.P("FN") * space
      * lpeg.C(varname) * space * lpeg.P("(") * space * dummylist * space * lpeg.P(")")
      * space * lpeg.P("=") * space * expr,
   forstatement =
      lpeg.C(lpeg.P("FOR")) * space * floatvar * space * lpeg.P("=") * space * expr
      * space * lpeg.P("TO") * space * expr * space *
      ( lpeg.P("STEP") * space * expr * space )^-1,
   onstatement =
      lpeg.C(lpeg.P("ON")) * space * expr * space * lpeg.P("GO") * space * lpeg.P("TO") * space *
      (lineno * space * lpeg.P(",") * space)^0 * lineno * space,
   numericassignment =
      lpeg.Cc("LETN") * lpeg.P("LET")^-1 * space *
      floatlval * space * lpeg.P("=") * space * expr * space,
   stringassignment =
      lpeg.Cc("LETS") * lpeg.P("LET")^-1 * space *
      stringlval * space * lpeg.P("=") * space * stringexpr * space,
   -- Argument lists
   exprlist = lpeg.Ct(( expr * space * lpeg.P(",") * space)^0 * expr),
   dimdef = lpeg.Ct(anyvar * space * lpeg.P("(") * space * exprlist * space * lpeg.P(")")),
   dimlist = ( dimdef * space * lpeg.P(",") * space)^0 * dimdef,
   printexpr = stringexpr + expr + lpeg.C(lpeg.S(";,"))*space,
   printlist = (printexpr * space )^0,
   inputitem = stringlval + floatlval,
   inputlist = (inputitem * space * lpeg.P(",") * space)^0 * inputitem * space,
   dummylist = lpeg.Ct( (lpeg.C(varname)*space*lpeg.P(",")*space)^0*lpeg.C(varname)),
   -- Expression hierarchy
   expr = rawexpr,
   rawexpr = Or,
   Or = lpeg.Ct(lpeg.Cc("OR") * (And * space * lpeg.P("OR") * space)^1 * And)
      + And,
   And = lpeg.Ct(lpeg.Cc("AND") * (Not * space * lpeg.P("AND") * space)^1 * Not) + Not,
   Not = lpeg.Ct(lpeg.C("NOT") * space * comparison) + comparison,
   comparison = lpeg.Ct(
      lpeg.Cc("COMPARE") *
	 ( stringexpr * space * comparisonop * space * stringexpr
	      + ( Sum * space * comparisonop * space)^1 * Sum + Sum) ),
   Sum =
      lpeg.Ct(lpeg.Cc("SUM") * ( Product * space * lpeg.C(lpeg.S("+-")) * space)^1 * Product) * space
      + Product * space,
   Product = lpeg.Ct(lpeg.Cc("PRODUCT") * ( Power * space * lpeg.C(lpeg.S("*/")) * space)^1 * Power) * space
      + Power * space,
   Power = lpeg.Ct(lpeg.Cc("POWER") * ( Unary * space * lpeg.S("^") * space)^1 * Unary) * space
      + Unary * space,
   -- TODO: address ambiguity about the handling of -1 -- is it "-" "1" or "-1"?
   Unary = lpeg.Ct(lpeg.Cc("UNARY") * lpeg.C(lpeg.S("+-")) * Value) + Value,
   Value = floatval + floatrval + lpeg.P("(") * space * expr * space * lpeg.P(")"),
   -- String expression hierarchy
   stringexpr = concat,
   concat = lpeg.Ct(lpeg.Cc("CONCAT") *
		    (stringrval * space * lpeg.P("+") * space)^0 * stringrval),
   -- Lowest-level groups
   floatlval = element + floatvar,
   floatrval = funcall + index + floatvar,
   stringlval = stringelement + stringvar,
   stringelement = lpeg.Ct(lpeg.Cc("STRINGELEMENT") * stringvar * space *
			   lpeg.P("(") * space * exprlist * space * lpeg.P(")")),
   stringrval = stringval + stringindex + stringlval,
  -- Array access/function/builtin call
   arg = stringexpr + expr,
   arglist = lpeg.Ct(( arg * space * lpeg.P(",") * space)^0 * arg),
   element = lpeg.Ct(lpeg.Cc("ELEMENT") * floatvar * space * lpeg.P("(") * space * exprlist * space * lpeg.P(")")),
   funcall = lpeg.Ct(lpeg.Cc("FUNCALL") *
		     lpeg.P("FN") * space *
		     floatvar * space * lpeg.P("(") * space * arglist * space * lpeg.P(")")),
   index = lpeg.Ct(lpeg.Cc("INDEX") *
	       --lpeg.Cmt(lpeg.P"",function (s,p,c) print("Matching INDEX at",p); return true; end) *
		  floatvar * space * lpeg.P("(") * space * arglist * space * lpeg.P(")")),
   stringindex = lpeg.Ct(lpeg.Cc("STRINGINDEX") * stringvar * space * lpeg.P("(") * space * arglist * space * lpeg.P(")")),
   statementlist = (statement * lpeg.P(":") * space )^0 * statement,
   line = lpeg.Ct(lineno * space * lpeg.Ct(statementlist) * lpeg.Cp()),
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
linegrammar.expr = lpeg.Cmt(any,matchexpr);
local exprgrammar = {};
for k,v in pairs(linegrammar) do
   exprgrammar[k] = v;
end
exprgrammar[1] = "exprtagged";
exprgrammar.exprtagged = lpeg.Ct(rawexpr) * lpeg.Cp();
basicexpr = lpeg.P(exprgrammar);
local basicline = lpeg.P(linegrammar);

function parse(lines)
   local prog, targets, data, datatargets = {}, {}, {}, {};
   local nerr = 0;
   -- Read and parse input file
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
   end
   if nerr ~= 0 then
      error("Parser failure");
   end
   return prog, data, datatargets, targets;
end

m.parse = parse;
m.input = input;

return m;
