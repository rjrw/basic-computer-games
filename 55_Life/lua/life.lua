local banner = [[
                                  Life
               Creative Computing  Morristown, New Jersey


Enter your pattern:]];

function readboard(nx)
   local b = {};
   for i = 1,nx do
      local s = string.lower(io.read("*l"));
      if s == "done" then
	 break;
      end
      if string.sub(s,1,1) == "." then
	    s = " "..string.sub(s,2);
      end
      b[i] = s;
   end
   return b;
end

function fillboard(nx,ny)
   local a = {};
   for i = 1, nx do
      a[i] = {};
      for j = 1, ny do
	 a[i][j] = 0;
      end
   end
   local b = readboard(nx);
   local c = #b;
   local l = 0;
   for x = 1,c do
      l = math.max(l,#b[x]);
   end

   local x1 = math.ceil(nx/2-1-c/2)
   local y1 = math.ceil(ny/2-2-l/2)
   local x2, y2 = 1, 1
   local p = 0;
   for x=1,c do
      for y=1,#b[x] do
	 if b[x][y] ~= " " then
	    a[x1+x][y1+y]=1;
	    x2 = math.max(x2,x1+x);
	    y2 = math.max(y2,y1+x);
	    p = p+1;
	 end
      end
   end
   return {a = a, i9 = 0, nx = nx, ny = ny, p = p,
	   x1 = x1, x2 = x2, y1 = y1, y2 = y2};
end

function printboard(board, g)
   local a = board.a;

   print(string.format("Generation:\t%d\tPopulation:\t%d",g,board.p));
   if board.i9 ~= 0 then
      print("Invalid!");
   end
   for x=1,board.x1-1 do
      print()
   end
   for x=board.x1,board.x2 do
      line = "";
      for y=1,board.y1-1 do
	 line = line.." ";
      end
      for y=board.y1,board.y2 do
	 if a[x][y] == 1 then
	    line = line.."*";
	 else
	    line = line.." ";
	 end
      end
      print(line);
   end
   for x=board.x2+1,board.nx do
      print()
   end
end


print(banner);
local nx, ny = 24, 70;
local a = fillboard(nx,ny);
print();
print();
print();
local g = 0;
   
for ii=0,10 do

   printboard(a, g);
   g=g+1;

   local x3,y3,x4,y4=a.nx,a.ny,1,1
   for x=a.x1,a.x2 do
      for y=a.y1,a.y2 do
	 if a.a[x][y] == 1 then
	    x3 = math.min(x,x3);
	    x4 = math.max(x,x4);
	    y3 = math.min(y,y3);
	    y4 = math.max(y,y4);
	 end
      end
   end
   a.x1 = x3-1;
   a.x2 = x4+1;
   a.y1 = y3-1;
   a.y2 = y4+1;
   if a.x1 < 2 then
      a.x1 = 2;
      a.i9 = -1;
   end
   if a.x2 > a.nx-1 then
      a.x2 = a.nx-1;
      a.i9 = -1;
   end
   if a.y1 < 2 then
      a.y1 = 2;
      a.i9 = -1;
   end
   if a.y2 > a.ny-1 then
      a.y2 = a.ny-1
      a.i9 = -1;
   end

   for x=a.x1,a.x2 do
      for y=a.y1,a.y2 do
	 c = 0;
	 for i = x-1, x+1 do
	    for j = y-1, y+1 do
	       if a.a[i][j] == 1 or a.a[i][j] == 2 then
		  c = c+1;
	       end
	    end
	 end
	 if a.a[x][y] == 1 then
	    if c < 3 or c > 4 then
	       a.a[x][y] = 2; -- Dying
	    end
	 else
	    if c == 3 then
	       a.a[x][y] = 3; -- New
	    end
	 end
      end
   end
   a.p = 0;
   for x=a.x1,a.x2 do
      for y=a.y1,a.y2 do
	 if a.a[x][y] == 2 then
	    a.a[x][y] = 0;
	 elseif a.a[x][y] == 3 then
	    a.a[x][y] = 1;
	 end
	 if a.a[x][y] == 1 then
	    a.p = a.p+1;
	 end
      end
   end
end
