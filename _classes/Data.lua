local Object = require("loft._classes.Object")
local Data = {_classname="Data"}
Object:_inherit(Data)
function Data:getPointer()
   return nil
end
function Data:getFFIPointer()
   return nil
end
function Data:clone()
   return self.new(rawget(self,"_string"))
end
function Data:getSize()
   return rawget(self,"_size")
end
function Data:getString()
   return rawget(self,"_string")
end
return Data
