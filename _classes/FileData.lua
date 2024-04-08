local FileData = require("loft._classes.Data"):_inherit({ _classname = "FileData" })
local function split(a, b)
   local n = {}
   for mat in a:gmatch("(.-)" .. b) do
      n[#n + 1] = mat
   end
   return n
end
function FileData:getExtension()
   local spp = split(rawget(self, "_fullname"), "%.")
   return spp[#spp]
end
function FileData:getFilename()
   local spp = split(rawget(self, "_fullname"), "%.")
   return table.concat(spp, ".", 1, #spp - 1)
end
function FileData:_new(str, name)
   local n = {
      _string = str,
      _size = #str,
      _fullname = name or "file.bin",
   }
   for i, v in next, self do
      n[i] = v
   end
   return n
end
return FileData
