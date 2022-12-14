#!/usr/bin/env lua

-- $Id: test.lua $

--require"strict"    -- just to be pedantic

parser = require"basicparser";

local function usage()
   print("Usage: basic.lua [opts] <file>.bas");
end

local function readfile(filename)
   local file = assert(io.open(filename));
   local lines = {}
   for line in file:lines() do
      lines[#lines+1] = line;
   end
   file:close();
   return lines;
end

local function deepwrite(file,dat,level)
   local indent = string.rep(" ",level);
   if type(dat) == "table" then
      file:write("{\n");
      for k, v in pairs(dat) do
	 if type(k) == "string" then
	    file:write(indent.."[\""..k.."\"]=");
	 else
	    file:write(indent.."["..k.."]=");
	 end
	 deepwrite(file,v,level+1);
	 file:write(",\n");
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

local narg = 1;
while narg < #arg do
   if arg[narg] == "-d" then
      dump = true;
      exec = false;
   elseif arg[narg] == "-O" then
      optimize = true;
   elseif arg[narg] == "-v" then
      verbose = true;
   else
      break;
   end
   narg = narg+1;
end
if #arg ~= narg then
   usage();
   os.exit(1);
end
local filename = arg[narg];
local baspat = ".bas$";
if not string.find(filename, baspat) then
   usage();
   os.exit(1);
end

local lines = readfile(filename);
local prog, data, datatargets = parser.parse(lines, optimize);

if dump then
   -- Save
   local outfile = string.gsub(filename,baspat,".lua");
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
