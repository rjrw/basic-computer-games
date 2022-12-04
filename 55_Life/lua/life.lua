print [[
                                  Life
               Creative Computing  Morristown, New Jersey


Enter your pattern:]];
local nx,ny = 24, 70;
local x1,y1,x2,y2=1,1,nx,ny;
local a, b = {}, {};
for i = 1, x2 do
   a[i] = {};
   a[i][y2] = 0;
end
local c=0;
for i = 1,x2 do
   b[i] = string.lower(io.read("*l"));
   if b[i] == "done" then
      b[i] = "";
      break;
   end
   if string.sub(b[i],1,1) == "." then
      b[i] = " "..string.sub(b[i],2);
   end
   c=i;
end
local l=0;
for x=1,c do
   if string.len(b[x]) > l then
      l = string.len(b[x]);
   end
end
x1 = math.ceil(nx/2-1-c/2)
y1 = math.ceil(ny/2-2-l/2)
local p = 0;
for x=1,c do
   for y=1,string.len(b[x]) do
      if string.sub(b[x],y,y) ~= " " then
	 a[x1+x][y1+y]=1;
	 p = p+1;
      end
   end
end
print();
print();
print();
local g, i9 = 0, 0;
for ii=0,10 do
   print(string.format("Generation:\t%d\tPopulation:\t%d",g,p));
   if i9 ~= 0 then
      print("Invalid!");
   end
   local x3,y3,x4,y4=nx,ny,1,1
   g=g+1;
   for x=1,x1-1 do
      print()
   end
   for x=x1,x2 do
      line = "";
      for y=1,y1-1 do
	 line = line.." ";
      end
      for y=y1,y2 do
	 if a[x][y] == 1 then
	    line = line.."*";
	    x3 = math.min(x,x3);
	    x4 = math.max(x,x4);
	    y3 = math.min(y,y3);
	    y4 = math.max(y,y4);
	 else
	    line = line.." ";
	 end
      end
      print(line);
   end
   for x=x2+1,nx do
      print()
   end
   x1 = x3-1;
   x2 = x4+1;
   y1 = y3-1;
   y2 = y4+1;
   if x1 < 2 then
      x1 = 2;
      i9 = -1;
   end
   if x2 > nx-1 then
      x2 = nx-1;
      i9 = -1;
   end
   if y1 < 2 then
      y1 = 2;
      i9 = -1;
   end
   if y2 > ny-1 then
      y2 = ny-1
      i9 = -1;
   end
   for x=x1,x2 do
      for y=y1,y2 do
	 c = 0;
	 for i = x-1, x+1 do
	    for j = y-1, y+1 do
	       if a[i][j] == 1 or a[i][j] == 2 then
		  c = c+1;
	       end
	    end
	 end
	 if a[x][y] == 1 then
	    if c < 3 or c > 4 then
	       a[x][y] = 2; -- Dying
	    end
	 else
	    if c == 3 then
	       a[x][y] = 3; -- New
	    end
	 end
      end
   end
   p = 0;
   for x=x1,x2 do
      for y=y1,y2 do
	 if a[x][y] == 2 then
	    a[x][y] = 0;
	 elseif a[x][y] == 3 then
	    a[x][y] = 1;
	 end
	 if a[x][y] == 1 then
	    p = p+1;
	 end
      end
   end
end
