local samples = 5000
local n2 = {}
for i = 1, 500000 do
   n2[i] = i
end
local function abc()
   local n = {}
   for i, v in n2 do
      n[i] = v
   end
   return n
end
local clk = os.clock
local avg = 0
for _ = 1, samples do
   local start = clk()
   table.clone(n2)
   avg = avg + (clk() - start)
end
-- print(avg/samples*1000000,"micros")
print(avg / samples)
