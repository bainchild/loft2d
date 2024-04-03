local love = require('loft')
local ImageData = require('loft._classes.ImageData')
love.image = {}
function love.image.newImageData(width,height,format,rawdata)
   if type(width)=="number" then
      error("TODO: rawdata parameter to newImageData")
   elseif type(width)=="string" then
      width=assert(love.filesystem.read(width))
      return ImageData:_decode(width:getString())
   elseif type(width)=="table" and width:typeOf("Data") then
      return ImageData:_decode(width:getString())
   end
   error("Bad overload?")
end
return love.image
