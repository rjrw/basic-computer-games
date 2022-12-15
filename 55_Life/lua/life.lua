local banner = [[
                                  Life
               Creative Computing  Morristown, New Jersey


Enter your pattern:]];

function readlines(nx)
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

local Board = {};
function Board:new(o)
   o = o or {};
   setmetatable(o, self);
   self.__index = self;
   return o;
end
function Board:nextgeneration()
   self.gen = self.gen+1;
end
function Board:generation()
   return self.gen;
end
function Board:setpopulation(p)
   self.pop = p;
end
function Board:population()
   return self.pop;
end

function readboard(nx,ny)
   local a = {};
   for i = 1, nx do
      a[i] = {};
      for j = 1, ny do
	 a[i][j] = 0;
      end
   end
   local b = readlines(nx);
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
      local bx, ax1x = b[x], a[x1+x];
      for y=1,#bx do
	 if bx[y] ~= " " then
	    ax1x[y1+y]=1;
	    x2 = math.max(x2,x1+x);
	    y2 = math.max(y2,y1+y);
	    p = p+1;
	 end
      end
   end
   return Board:new{a = a, status = 0, nx = nx, ny = ny,
		    gen=0, pop=p,
		    x1 = x1, x2 = x2, y1 = y1, y2 = y2};
end

function Board:print()
   local a = self.a;

   print(string.format("Generation:\t%d\tPopulation:\t%d",
		       self:generation(),self:population()));
   if self.status ~= 0 then
      print("Invalid!");
   end
   local pic = {};
   local rep = string.rep;
   pic[#pic+1] = rep("\n",self.x1);
   for x=self.x1,self.x2 do
      local ax = a[x];
      pic[#pic+1] = rep(" ",self.y1);
      for y=self.y1,self.y2 do
	 if ax[y] == 1 then
	    pic[#pic+1] = "*";
	 else
	    pic[#pic+1] = " ";
	 end
      end
      pic[#pic+1] = "\n";
   end
   pic[#pic+1] = rep("\n",self.nx-self.x2);
   io.write(table.concat(pic));
end

function Board:expand()
   self.x1 = self.x1-1;
   self.x2 = self.x2+1;
   self.y1 = self.y1-1;
   self.y2 = self.y2+1;
   if self.x1 < 2 then
      self.x1 = 2;
      self.status = -1;
   end
   if self.x2 > self.nx-1 then
      self.x2 = self.nx-1;
      self.status = -1;
   end
   if self.y1 < 2 then
      self.y1 = 2;
      self.status = -1;
   end
   if self.y2 > self.ny-1 then
      self.y2 = self.ny-1
      self.status = -1;
   end
end

function Board:evolve()

   local a = self.a
   local Empty, Full, Dying, New = 0,1,2,3
   
   self:expand()
   for x=self.x1,self.x2 do
      local ax = a[x];
      for y=self.y1,self.y2 do
	 local c = 0;
	 for i = x-1, x+1 do
	    local ai = a[i];
	    for j = y-1, y+1 do
	       local aij = ai[j];
	       if aij == Full or aij == Dying then
		  c = c+1;
	       end
	    end
	 end
	 if ax[y] == 1 then
	    if c < 3 or c > 4 then
	       ax[y] = Dying;
	    end
	 else
	    if c == 3 then
	       ax[y] = New;
	    end
	 end
      end
   end
   local x1,x2,y1,y2,p = self.nx,1,self.ny,1,0;
   for x=self.x1,self.x2 do
      local ax = a[x];
      for y=self.y1,self.y2 do
	 if ax[y] == Dying then
	    ax[y] = Empty;
	 elseif ax[y] == New then
	    ax[y] = Full;
	 end
	 if ax[y] == Full then
	    p = p+1;
	    x1 = math.min(x,x1);
	    x2 = math.max(x,x2);
	    y1 = math.min(y,y1);
	    y2 = math.max(y,y2);
	 end
      end
   end
   self.x1, self.x2, self.y1, self.y2 =
      x1, x2, y1, y2;
   self:setpopulation(p);
   self:nextgeneration()
end

print(banner);
local nx, ny = 24, 70;
local a = readboard(nx,ny);
print();
print();
print();
   
for ii=0,10 do
   a:print();
   a:evolve();
end
