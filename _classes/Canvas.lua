-- literally a paintable texture
local Canvas = require("loft._classes.Texture"):_inherit({_classname="Canvas"})
-- generateMipmaps
-- getMSAA
-- getMipmapMode
-- newImageData
local love
function Canvas:renderTo(index,func)
   if func==nil then func=index;index=nil end
   if love==nil then love=require("loft") end
   if love.graphics==nil then return end
   local prevcanvas = love.graphics.getCanvas()
   love.graphics.setCanvas(self)
   func()
   love.graphics.setCanvas(prevcanvas)
end
return Canvas
