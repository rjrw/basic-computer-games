#!/usr/bin/env lua

-- check for use of undefined globals
-- local _ENV = require 'std.strict' (_G)

parser = require"basicparser";

local function readfile(filename)
   local file = assert(io.open(filename));
   local lines = {}
   for line in file:lines() do
      lines[#lines+1] = line;
   end
   file:close();
   return lines;
end

-- Write out all of nested structure, EXCEPT fields with key "__cache"
local function deepwrite(file,dat,level)
   local indent = string.rep(" ",level);
   if type(dat) == "table" then
      file:write("{\n");
      for k, v in pairs(dat) do
	 if k ~= "__cache" then
	    if type(k) == "string" then
	       file:write(indent.."[\""..k.."\"]=");
	    else
	       file:write(indent.."["..k.."]=");
	    end
	    deepwrite(file,v,level+1);
	    file:write(",\n");
	 end
      end
      file:write(indent.."}");
   elseif type(dat) == "string" then
      local enc = string.gsub(dat,"\"","\\\"");
      file:write("\""..enc.."\"");
   else
      file:write(dat);
   end      
end

local exec = true;
local dump, optimize, verbose = false, false, false;
local outfile = nil;
local usage;

local opts = {
   ["-d"] = {
      function(par)
	 dump = true; exec = false;
	 outfile = par;
      end,
      "[file]",
      "Dump (optimized) parser output as standalone Lua script" },
   ["-O"] = { function() optimize = true end,
      "",
     "Run optimization phase on parser output before execution/dump" },
   ["-v"] = { function() verbose = true end,
     "","Enable verbose diagnostics"},
   ["--help"] = { function() usage(); end, "", "Print this help" },
};

usage = function ()
   io.write("Usage: basic.lua [opts] <file>.bas\nOptions:\n");
   local keys = {};
   local ltab = 0;
   for k,v in pairs(opts) do
      keys[#keys+1] = k;
      local l = #k+#v[2];
      ltab = ltab > l and ltab or l;
   end
   table.sort(keys, function (a,b) return a:lower() < b:lower() end);
   for _,k in ipairs(keys) do
      local a = k..opts[k][2];
      io.write(string.format("  %s%s%s\n",
			     a,string.rep(" ",ltab-#a+2),opts[k][3]));
   end
end

local narg = 1;
while narg <= #arg do
   local argn = arg[narg];
   if argn:sub(1,1) ~= "-" then
      break;
   end
   local opt;
   local par = "";
   if #argn == 1 then
      usage();
      os.exit();
   elseif argn:sub(2,2) == "-" then
      -- Long argument
      opt = opts[argn];
   else
      -- Short argument, possibly with option
      opt = opts[argn:sub(1,2)];
      par = argn:sub(3);
   end
   if not opt then
      break;
   end
   opt[1](par);
   narg = narg+1;
end
if #arg ~= narg then
   usage();
   os.exit(1);
end

local filename = arg[narg];
local baspat = ".bas$";
if not string.find(filename, baspat) then
   print("Error: Filename should have '.bas' extension");
   os.exit(1);
end
outfile = outfile ~= "" and outfile or filename:gsub(baspat,".lua");

local lines = readfile(filename);
local prog, data, datatargets = parser.parse(lines, optimize, verbose);

if dump then
   -- Save
   print("Saving compiled output to "..outfile);
   local file = assert(io.open(outfile,"w"));
   file:write("local rtl = require\"basicrtl\";\n");
   file:write("local data = ");
   deepwrite(file,data,0);
   file:write(";\nlocal datatargets = ");
   deepwrite(file,datatargets,0);
   file:write(";\nlocal prog = ");
   deepwrite(file,prog,0);
   file:write(";\nrtl.run(prog, data, datatargets);\n");
   file:close();
end

if exec then
   local rtl = require"basicrtl";
   rtl.run(prog, data, datatargets);
end
