local Texture = require('loft._classes.Data'):_inherit({_classname="Texture"})
function Texture:getDPIScale()
   return rawget(self,"_dpiscale")
end
function Texture:getDepth()
   if rawget(self,"_type")~="volume" then return 1 end
   return rawget(self,"_depth")
end
function Texture:getDepthSampleMode()
   return rawget(self,"_depthsamplemode")
end
function Texture:getDimensions()
   return rawget(self,"_width"),rawget(self,"_height")
end
function Texture:getFilter()
   return rawget(self,"_filter")
end
function Texture:getFormat()
   return rawget(self,"_pxformat")
end
function Texture:getHeight()
   return rawget(self,"_height")
end
-- todo:
-- getLayerCount
-- getMipmapCount
-- getMipmapFilter
function Texture:getPixelDimensions()
   return math.floor(rawget(self,"_width")*rawget(self,"_dpiscale")),
          math.floor(rawget(self,"_height")*rawget(self,"_dpiscale"))
end
function Texture:getPixelHeight()
   return math.floor(rawget(self,"_height")*rawget(self,"_dpiscale"))
end
function Texture:getPixelWidth()
   return math.floor(rawget(self,"_width")*rawget(self,"_dpiscale"))
end
-- getTextureType
function Texture:getWidth()
   return rawget(self,"_width")
end
-- getWrap
-- isReadable
-- setDepthSampleMode
-- setFilter
-- setMipmapFilter
-- setWrap
function Texture:_default()
   local n = {
      _width=1,
      _height=1,
      _dpiscale=1,
   }
   for i,v in next, self do
      n[i]=v
   end
   return n
end
return Texture
