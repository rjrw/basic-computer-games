print [[
                                  Life
               Creative Computing  Morristown, New Jersey


Enter your pattern:]];
local x1,y1,x2,y2=1,1,24,70;
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
for x=1,c-1 do
   if string.len(b[x]) > l then
      l = string.len(b[x]);
   end
end
x1 = math.ceil(11-c/2)
y1 = math.ceil(33-l/2)
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
print(string.format("Generation:\t%d\tPopulation:\t%d",g,p));
if i9 ~= 0 then
   print("Invalid!");
end
local x3,y3,x4,y4=24,70,1,1
p=0;
g=g+1;
for x=1,x1-1 do
   print()
end
for x=x1,x2 do
   line = "";
   for y=1,y2 do
      if a[x][y] == 2 then
	 a[x][y] = 0;
      elseif a[x][y] == 3 then
	 a[x][y] = 1;
      end
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
for x=x2+1,24 do
   print()
end
	 
return;

--[[
299 X1=X3: X2=X4: Y1=Y3: Y2=Y4
301 IF X1<3 THEN X1=3:I9=-1
303 IF X2>22 THEN X2=22:I9=-1
305 IF Y1<3 THEN Y1=3:I9=-1
307 IF Y2>68 THEN Y2=68:I9=-1
309 P=0
500 FOR X=X1-1 TO X2+1
510 FOR Y=Y1-1 TO Y2+1
520 C=0
530 FOR I=X-1 TO X+1
540 FOR J=Y-1 TO Y+1
550 IF A(I,J)=1 OR A(I,J)=2 THEN C=C+1
560 NEXT J
570 NEXT I
580 IF A(X,Y)=0 THEN 610
590 IF C<3 OR C>4 THEN A(X,Y)=2: GOTO 600
595 P=P+1
600 GOTO 620
610 IF C=3 THEN A(X,Y)=3:P=P+1
620 NEXT Y
630 NEXT X
635 X1=X1-1:Y1=Y1-1:X2=X2+1:Y2=Y2+1
640 GOTO 210
650 END
--]]
