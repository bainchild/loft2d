local pxarray, strpxarray
local Gxs,Gys = 250,250
local function test1()
   pxarray = {xs=Gxs,ys=Gys}
   -- 25x25 image
   -- make space for 25
   pxarray[Gxs]={}
   for x=1,Gxs do
      pxarray[x] = {[Gys]={}}
      for y=1,Gys do
         pxarray[x][y] = {x,y,255}
      end
   end
end
local function test2()
   local char = string.char
   strpxarray = char(Gxs,Gys) -- xsize, ysize
   for x=1,Gxs do
      -- this is faster than small
      -- additions to the main str
      -- ( like 8/10000 cpu-time seconds )
      local row = ""
      for y=1,Gys do
         row=row..char(x,y,255)
      end
      strpxarray=strpxarray..row
   end
end
local function test3()
   local xs,ys = pxarray.xs,pxarray.ys
   for x=1,xs do
      for y=1,ys do
         local v = pxarray[x][y]
         local r,g,b = v[1],v[2],v[3]
         if r~=x or g~=y or b~=255 then error("Not 255, what went wrong?") end
      end
   end
end
local function test4()
   local byte = string.byte
   local xs,ys = byte(strpxarray,1,2)
   local off = 3
   for x=1,xs do
      for y=1,ys do
         local r,g,b = byte(strpxarray,off,off+2)
         if r~=x or g~=y or b~=255 then error("Not 255, what went wrong?") end
         off=off+3
      end
   end
end
local function test5()
   -- TODO: is unpack faster?
   -- will also apply to test3
   local v = pxarray[1][1]
   return v[1],v[2],v[3]
end
local function test6()
   return string.byte(strpxarray,3,6)
end
for _,inf in next, {
   {"pxarray_create",test1};
   {"strpxa_create",test2};
   {"pxarray_read",test3};
   {"strpxa_read",test4};
   {"pxarray_single",test5};
   {"strpxa_single",test6};
} do
   ---@diagnostic disable-next-line: cast-local-type
   local i,v = inf[1],inf[2]
   local start = os.clock()
   v()
   local en = os.clock()
   print(("%s: %.8fs"):format(i.."\t",en-start))
end
