#!/usr/bin/env lua

-- Renumber: the ultimate Basic refactoring tool, with vintage BBC
-- Basic diagnostic output.

-- Usage: renumber.lua <number> <file>.bas > <newfile>.bas

-- Renumbers basic lines in <file.bas> increments of <number>,
-- re-targeting IF, GOTO, GOSUB, ON GOTO, ON GOSUB and RESTORE
-- statements.

-- BUGS: Parsing is limited, so it can be confused by content in
-- strings and comments which looks like a jump statement

local function readfile(filename)
   local file = assert(io.open(filename));
   local lines = {}
   for line in file:lines() do
      lines[#lines+1] = line;
   end
   file:close();
   return lines;
end

if #arg ~= 2 then
   print("Usage: "..arg[0].." <number> <file>.bas");
   os.exit(1);
end
local step = tonumber(arg[1]);
if step <= 0 then
   print("Silly");
   os.exit(q);
end
local prog = readfile(arg[2]);
local newlines = {};
for k,v in ipairs(prog) do
   local linenum = assert(v:match("^%s*(%d+)"));
   newlines[linenum] = k*step;
end
local newprog = {};

function convertargs(v1,m)
   local v,s = v1,"";   
   while true do
      local w,n;
      local f,l = v:find(m);
      if f == nil then
	 break;
      end
      s = s..v:sub(1,l);
      v = v:sub(l+1);
      while true do
	 f,l = v:find("^%d+");
	 local n = newlines[v:sub(f,l)];
	 assert(n,"Jump to missing target at\n"..v1.."\n");
	 s = s..n;
	 v = v:sub(l+1);
	 f,l = v:find("^%s*,%s*");
	 if not f then
	    break;
	 end
	 s = s..v:sub(1,l);
	 v = v:sub(l+1);
      end
   end
   s = s..v;
   return s;
end

function convertnumber(w,n1)
   local n = newlines[n1];
   assert(n,"Jump to missing target "..n1);
   return w..n;
end

local width = math.ceil(math.log(step*#prog,10));
-- Ensure renumbered lines are aligned
local format = "%"..width.."d ";
for k,v in ipairs(prog) do
   v = v:gsub("^%s*(%d+)%s*",
	      function (n)
		 return string.format(format,newlines[n]);
	      end,
	      1);
   v = v:gsub("(THEN%s*)(%d+)",convertnumber);
   v = v:gsub("(RESTORE%s*)(%d+)",convertnumber);
   v = convertargs(v,"GO%s*TO%s*");
   v = convertargs(v,"GO%s*SUB%s*");
   print(v);
end
	     
