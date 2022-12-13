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
local prog, data, datatargets, targets = parser.parse(lines);

if mode == 2 then
   local rtl = require"basicrtl";
   rtl.run(prog, targets, data, datatargets);
else
   -- Save
   local outfile = string.gsub(filename,baspat,".lua");
   local file = assert(io.open(outfile,"w"));
   file:write("local rtl = require\"basicrtl\";\n");
   file:write("local prog = ");
   deepwrite(file,prog,0);
   file:write(";\nlocal targets = ");
   deepwrite(file,targets,0);
   file:write(";\nlocal data = ");
   deepwrite(file,data,0);
   file:write(";\nlocal datatargets = ");
   deepwrite(file,datatargets,0);
   file:write(";\nrtl.run(prog, targets, data, datatargets);\n");
   file:close();
end
