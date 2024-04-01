-- literally a paintable texture
local love = require('loft')
local Canvas = require("loft._classes.Texture"):_inherit({_classname="Canvas"})
local ImageData = require("loft._classes.ImageData")
function Canvas:generateMipmaps()end
function Canvas:getMSAA()
   return 0
end
function Canvas:getMipmapMode()
   return "none"
end
function Canvas:newImageData(...)
   -- TODO: dpiscale!!
   if select("#",...) == 0 then
      return ImageData:_new(rawget(self,"_pxformat"),rawget(self,"_width"),rawget(self,"_height"),rawget(self,"_pxarray"))
   end
   error("newImageData overloads")
end
function Canvas:renderTo(index,func)
   if func==nil then func=index;index=nil end
   if love.graphics==nil then return end
   local prevcanvas = love.graphics.getCanvas()
   love.graphics.setCanvas(self)
   func()
   love.graphics.setCanvas(prevcanvas)
end
function Canvas:_new(width,height,dpi,format,px,fill_pixel)
   if dpi==nil then dpi=1 end
   if format==nil then format="rgba8" end
   if px==nil then
      px = {}
      if fill_pixel==nil then
         if format=="r8" or format=="r16" or format=="r16f" or format=="r32f" then
            for x=width,1,-1 do
               px[x]={}
               for y=height,1,-1 do
                  px[x][y] = 0
               end
            end
         elseif format=="rg8" or format=="rg16" or format=="rg16f" or format=="rg32f" then
            for x=width,1,-1 do
               px[x]={}
               for y=height,1,-1 do
                  px[x][y] = {0,0}
               end
            end
         elseif format=="rgba8" or format=="srgba8" or format=="rgba18" or format=="rgba16f" or format=="rgba32f" then
            for x=width,1,-1 do
               px[x]={}
               for y=height,1,-1 do
                  px[x][y] = {0,0,0}
               end
            end
         else
            return nil
         end
      else
         for x=width,1,-1 do
            px[x] = {}
            for y=height,1,-1 do
               px[x][y] = fill_pixel
            end
         end
      end
   end
   local n = {
      _width=width,
      _height=height,
      _dpiscale=dpi,
      _pxformat=format,
      _pxarray=px
   }
   for i,v in next, self do n[i]=v end
   return n
end
function Canvas:_clone_nc(fill)
   return self:_new(rawget(self,"_width"),rawget(self,"_height"),rawget(self,"_dpiscale"),rawget(self,"_format"),nil,fill)
end
return Canvas
