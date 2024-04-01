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
function Texture:_default(type,format)
   if type==nil then type="2d" end
   if format==nil or format=="normal" then format="rgba8" end
   local n
   if type=="2d" then
      n = {
         _width=1,
         _height=1,
         _dpiscale=1,
         _pxformat=format,
         _type=type,
         _pxarray={}
      }
      if format=="r8" or format=="r16" or format=="r16f" or format=="r32f" then
         n._pxarray[1]={0}
      elseif format=="rg8" or format=="rg16" or format=="rg16f" or format=="rg32f" then
         n._pxarray[1]={{0,0}}
      elseif format=="rgba8" or format=="srgba8" or format=="rgba18" or format=="rgba16f" or format=="rgba32f" then
         n._pxarray[1]={{0,0,0}}
      else
         return nil
      end
   else
      return nil
   end
   for i,v in next, self do
      n[i]=v
   end
   return n
end
return Texture
