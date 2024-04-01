-- TODO: make this a pluggable provider
local pngencoder = require('loft._encode.pngencoder')
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
return function(imagedata)
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
end
