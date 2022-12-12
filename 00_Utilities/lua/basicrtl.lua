local m = {};

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

m.builtins =
   { ABS = abs, ASC = string.byte, ATN = math.atan, COS = math.cos,
     EXP = math.exp, INT = math.floor, LEN=len, LOG = math.log, SGN = sgn,
     SIN = math.sin, SPC = spc, SQR = math.sqrt,
     TAN = math.tan, VAL=tonumber };
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
   
return m;
