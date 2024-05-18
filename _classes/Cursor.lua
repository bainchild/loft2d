local Cursor = require("loft._classes.Object"):_inherit({ _classname = "Cursor" })
function Cursor.new(type)
   local n = {}
   for i,v in next, Cursor do
      n[i]=v
   end
   n._type = type
   return n
end
return Cursor
