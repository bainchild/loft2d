---@diagnostic disable: unused-local
local pxarray, dpxarray, strpxarray
local average_count = 500
local Gxs, Gys = 250, 250
local clock = os.clock
local clone, alloc
if table.clone then
   print("Using luau table.clone")
   clone = table.clone
else
   clone = function(tab)
      local n = {}
      for i = 1, #tab do
         n[i] = tab[i]
      end
      return n
   end
end
if table.create then
   alloc = table.create
   print("Using luau table.create")
end
local insert = table.insert
local function test1()
   pxarray = { xs = Gxs, ys = Gys }
   pxarray[Gxs] = {}
   if alloc then
      for x = 1, Gxs do
         local a = alloc(Gys)
         pxarray[x] = a
         for y = 1, Gys do
            a[y] = { x, y, 255 }
         end
      end
   else
      for x = 1, Gxs do
         local a = { [Gys] = {} }
         pxarray[x] = a
         for y = 1, Gys do
            a[y] = { x, y, 255 }
         end
      end
   end
end
local function test2()
   dpxarray = { xs = Gxs, ys = Gys }
   local Gys3 = 3 * Gys
   local px
   if alloc then
      px = alloc(Gxs * Gys3)
   else
      px = {}
   end
   dpxarray.px = px
   px[Gxs * Gys3] = 255 -- last element of last pixel
   for x = 0, Gxs - 1 do
      local off = x * Gys3 + 1
      for y = 0, Gys - 1 do
         local idx = off + y * 3
         px[idx] = x + 1
         px[idx + 1] = y + 1
         px[idx + 2] = 255
      end
   end
end
local function test3()
   local char = string.char
   strpxarray = char(Gxs, Gys) -- xsize, ysize
   for x = 1, Gxs do
      -- this is faster than small
      -- additions to the main str
      -- ( like 8/10000 cpu-time seconds )
      local row = ""
      for y = 1, Gys do
         row = row .. char(x, y, 255)
      end
      strpxarray = strpxarray .. row
   end
end
local function test4()
   local xs, ys = pxarray.xs, pxarray.ys
   for x = 1, xs do
      for y = 1, ys do
         local v = pxarray[x][y]
         local r, g, b = v[1], v[2], v[3]
         if r ~= x or g ~= y or b ~= 255 then
            error("Not 255, what went wrong?")
         end
      end
   end
end
local function test5()
   local xs, ys = dpxarray.xs, dpxarray.ys
   local ys3 = 3 * ys
   local px = dpxarray.px
   for x = 1, xs do
      local off = (x - 1) * ys3 + 1
      for y = 1, ys do
         local idx = off + (y - 1) * 3
         local r, g, b = unpack(px, idx, idx + 2)
         if r ~= x or g ~= y or b ~= 255 then
            error("Not 255, what went wrong?")
         end
      end
   end
end
local function test6()
   local byte = string.byte
   local xs, ys = byte(strpxarray, 1, 2)
   local off = 3
   for x = 1, xs do
      for y = 1, ys do
         local r, g, b = byte(strpxarray, off, off + 2)
         if r ~= x or g ~= y or b ~= 255 then
            error("Not 255, what went wrong?")
         end
         off = off + 3
      end
   end
end
local npxarray, ndpxarray, nstrpxarray
local function test7()
   npxarray = {}
   local ys = pxarray.ys
   for x = 1, pxarray.xs do
      npxarray[x] = {}
      local row = pxarray[x]
      for y = 1, ys do
         npxarray[x][y] = clone(row[y])
      end
   end
end
local function test8()
   ndpxarray = {
      xs = dpxarray.xs,
      ys = dpxarray.ys,
      px = clone(dpxarray.px), -- this is the bonus!!! (?)
   }
end
local function test9()
   nstrpxarray = strpxarray -- possibly free
end
local sum1, sum2 = 0, 0
for idx, inf in
   next,
   {
      { "pxarray_create", test1 },
      { "dpxarray_create", test2 },
      { "strpxa_create", test3 },

      { "pxarray_read", test4 },
      { "dpxarray_read", test5 },
      { "strpxa_read", test6 },

      { "pxarray_clone", test7 },
      { "dpxarray_clone", test8 },
      { "strpxa_clone", test9 },
   }
do
   ---@diagnostic disable-next-line: cast-local-type
   local i, v = inf[1], inf[2]
   local avgc = 0
   for _ = 1, average_count do
      local start = clock()
      v()
      local en = clock()
      avgc = avgc + (en - start)
   end
   print(("%s: %.8fs"):format(i .. "\t", avgc / average_count))
   sum1 = sum1 + avgc / average_count
   sum2 = sum2 + avgc / average_count
   if idx % 3 == 0 then
      print(("--- %.8fs"):format(sum1))
      sum1 = 0
   end
end

print(("SUM: %.8fs"):format(sum2))
-- findings:
-- strpxarray creation is bad (6ish times slower than pxarray)
-- dpxarray creation is good (by at least 1 zero)
