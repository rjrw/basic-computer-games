print("\n                         Sine Wave")
print("           Creative Computing Morriston, New Jersy")
print("\n\n\n\n")

-- Original BASIC version by David Ahl
-- Ported to lua by BeeverFeever(github), 2022

-- Factory which takes list of words, and generates a function which
-- emits them in turn.
function rotator(words)
   assert(#words>0);
   local w, pos = {}, 0;
   -- Capture a copy of the input table, so that the list can't be
   -- externally modified
   for _,v in ipairs(words) do
      w[#w+1] = v;
   end
   return function ()
      pos = pos+1;
      if pos > #w then
	 pos = 1;
      end
      return w[pos];
   end
end

local message = rotator{"Creative", "Computing"};

for t = 0, 40, 0.25 do
    local gap = math.floor(26 + 25 * math.sin(t))
    -- string.rep used to add the gap at the front of the printed out words
    print(string.rep(" ", math.floor(gap)) .. message());
end
