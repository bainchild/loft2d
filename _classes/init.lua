local classes = {}
-- todo: somehow make this friendly to dependency packers
-- remove dependency on next?
for _,v in next, {
   "Object",
   "Data",
   "ByteData"
} do
   classes[v]=require("loft._classes."..v)
end
return classes
