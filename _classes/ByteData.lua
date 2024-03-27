local Data = require('loft._classes.Data')
local ByteData = Data:_inherit({_classname="ByteData"})
function ByteData.new(str)
   return ByteData:_inherit({
      _classname="ByteData",
      _string=str or "",
      _size=(str and #str) or 0,
   })
end
return ByteData
