local love = require('loft')
local ByteData = require('loft._classes.ByteData')
love.data = {}
love.data.newByteData = ByteData.new
function love.data.newDataView(data,offset,size)
  return data.new(data:getString():sub(offset,offset+size))
end
return love.data
