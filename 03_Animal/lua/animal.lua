function banner()
   io.write(string.rep(" ",32),
	    "ANIMAL\n");
   io.write(string.rep(" ",15),
	    "CREATIVE COMPUTING  MORRISTOWN, NEW JERSEY\n");
   io.write("\n\n\n");
   io.write("Play 'Guess the Animal'\n\n");
   io.write("Think of an animal and the computer will try to guess it.\n\n");
end

local a = {
   ":qDoes it swim:y2:n3:", ":aFish",":aBird"
};

local function list(a)
   io.write("\n\nThe animals I already know are\n");
   local x=0;
   for _,v in ipairs(a) do
      local animal = v:match("^:a(.*)");
      if animal then
	 io.write(animal);
	 x = x+1;
	 if x == 4 then
	    x = 0;
	    io.write("\n");
	 else
	    io.write(string.rep(" ",15-#animal));
	 end
      end
   end
   io.write(x == 0 and "\n" or "\n\n");
end

local function prompt(a)
   repeat
      io.write("Are you thinking of an animal? ");
      local s = io.read():lower();
      if s == "list" then
	 list(a);
      end
   until s:sub(1,1) == "y";
end

local function nextquestion(a,k)
   local q = a[k];
   local c = "";
   repeat
      local f = assert(q:match("([^:]+)",3));
      io.write (f,"? ");
      c = io.read():lower():sub(1,1);
   until c == "y" or c == "n";
   local x = assert(q:match(":"..c.."(%d+)",3));
   return tonumber(x);
end

local function selectanimal(a)
   local k = 1;
   repeat
      k = nextquestion(a,k);
      if a[k] == nil then os.exit(); end;
   until a[k]:sub(1,2) ~= ":q";

   return k;
end

local function distinguishanimal(found)
   io.write("The animal you were thinking of was a ? ");
   local animal = io.read();
   io.write("Please type in a question that would distinguish a ",
	    animal," from a ",found,"? ");
   local query = io.read();
   local answer = "";
   repeat
      io.write("For a ",animal," the answer would be? ");
      answer = io.read():sub(1,1):lower();
   until answer == "y" or answer == "n";
   return animal, query, answer;
end

local function addanimal(a,k,animal,query,answer)
   local other = answer == "y" and "n" or "y";
   local z1 = #a+1;
   a[z1] = a[k];
   a[z1+1] = ":a"..animal;
   a[k] = ":q"..query..":"..
      answer..tostring(z1+1)..":"..other..tostring(z1)..":";
end

-- Main control section
while true do
   prompt(a);

   local k = selectanimal(a);
   local found = a[k]:sub(3);
   io.write("Is it a ",found,"? ");
   local s = io.read():sub(1,1):lower();
   if s == "y" then
      print("Why not try another animal?");
   else
      local animal, query, answer = distinguishanimal(found);
      addanimal(a,k,animal,query,answer);
   end
end
