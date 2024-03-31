local FileData = require("loft._classes.Data"):_inherit({_classname="FileData"})
local function split(a,b)
   local n = {}
   for mat in a:gmatch("(.-)"..b) do
      n[#n+1]=mat
   end
   return n
end
function FileData:getExtension()
   local spp = split(rawget(self,"_fullname"),"%.")
   return spp[#spp]
end
function FileData:getFilename()
   local spp = split(rawget(self,"_fullname"),"%.")
   return table.concat(spp,".",1,#spp-1)
end
return FileData
