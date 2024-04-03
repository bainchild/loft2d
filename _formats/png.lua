-- TODO: make this a pluggable provider
local pngencoder = require('loft._formats.pngencoder')
local pnglua = require("loft._formats.pnglua")
local ImageData
local function convert(format,r,g,b,a)
   r,g,b,a=r or 0,g or 0,b or 0,a or 0
   if format:sub(-1)=="8" then
      return r/255,g/255,b/255,a/255
   elseif format:sub(-2)=="16" or format:sub(-3)=="16f" then
      return r/65535,g/65535,b/65535,a/65535
   elseif format:sub(-2)=="32" or format:sub(-3)=="32f" then
      local max = 2^31
      return r/max,g/max,b/max,a/max
   end
   return r,g,b,a
end
local function unconvert(format,r,g,b,a)
   r,g,b,a=r or 0,g or 0,b or 0,a or 0
   if format:sub(-1)=="8" then
      return math.floor(r*255),math.floor(g*255),math.floor(b*255),math.floor(a*255)
   elseif format:sub(-2)=="16" then
      return math.floor(r*65535),math.floor(g*65535),math.floor(b*65535),math.floor(a*65535)
   elseif format:sub(-3)=="16f" then
      return r*65535,g*65535,b*65535,a*65535
   elseif format:sub(-2)=="32" then
      local max = 2^31
      return math.floor(r*max),math.floor(g*max),math.floor(b*max),math.floor(a*max)
   elseif format:sub(-3)=="32f" then
      local max = 2^31
      return r*max,g*max,b*max,a*max
   end
   return r,g,b,a
end
return {
   into=function(imagedata)
      local width,height = imagedata:getDimensions()
      local enc = pngencoder(width,height,"rgba")
      for y=0,height-1 do
         for x=0,width-1 do
            local r,g,b,a = unconvert("rgba8",imagedata:getPixel(x,y))
            enc:write({math.floor(r),math.floor(g),math.floor(b),math.floor(a)})
         end
      end
      assert(enc.done,"Not done encoding???")
      return table.concat(enc.output,"")
   end;
   from=function(src)
      local n = pnglua(src)
      --n.width,n.height,n.depth
      local format
      if n.colorType==0 then
         -- greyscale
         format="r8"
      elseif n.colorType==2 or n.colorType==3 then
         -- normal rgb, index-based
         format="rgb8"
      elseif n.colorType==4 or n.colorType==6 then
         -- greyscale + alpha, normal rgba
         format="rgba8"
      end
      local px = {}
      for x=n.width,1,-1 do
         px[x] = {}
         for y=n.height,1,-1 do
            local p = n:getPixel(x,y)
            if format=="r8" then
               px[x][y] = p.R
            elseif format=="rgb8" then
               px[x][y] = {p.R,p.G,p.B}
            elseif format=="rgba8" then
               px[x][y] = {p.R,p.G,p.B,p.A or 0}
            end
         end
      end
      if ImageData==nil then ImageData=require("loft._classes.ImageData") end
      return ImageData:_new(format,n.width,n.height,px)
   end;
   isA=function(src)
      return string.sub(src,1,8) == "\137\080\078\071\013\010\026\010"
   end;
}
