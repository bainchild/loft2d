-- local love = require('loft')
local Image = require("loft._classes.Texture"):_inherit({_classname="Image"})
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
-- _pxformat, _width, _height, _pxarray, 
function Image:isCompressed()
   return rawget(self,"_isCompressed")
end
function Image:isFormatLinear()
   return rawget(self,"_isLinear")
end
-- removed: slice, mipmap, reloadmipmaps
function Image:replacePixels(data,_,_,x,y,_)
   
end
function Image:_new(type_,imgdata,settings)
   local n = {
      _width=imgdata:getWidth(),
      _height=imgdata:getHeight(),
      _format=imgdata:getFormat(),
      _pxarray=rawget(imgdata,"_pixels"),
      _type=type_,
      _isCompressed=imgdata:typeOf("CompressedImageData"),
      _isLinear=(settings and rawget(settings,"linear"))
   }
   for i,v in next, self do
      n[i]=v
   end
   return n
end
function Image:_getpxarray(form)
   local format = rawget(self,"_format")
   local px = rawget(self,"_pxarray")
   local w,h = rawget(self,"_width"),rawget(self,"_height")
   local n = {}
   if form==nil then
      for x=w,1,-1 do
         n[x]={}
         for y=h,1,-1 do
            local p = px[x][y]
            -- divides to make it 0-1 range
            if type(p)=="table" then
               ---@diagnostic disable-next-line: deprecated
               n[x][y] = {convert(format,(unpack or table.unpack)(p))}
            else
               n[x][y] = convert(format,p)
            end
         end
      end
   elseif form==format then
      for x=w,1,-1 do
         n[x]={}
         for y=h,1,-1 do
            n[x][y] = px[x][y]
         end
      end
   else
      for x=w,1,-1 do
         n[x]={}
         for y=h,1,-1 do
            local p = px[x][y]
            if type(p)=="table" then
               ---@diagnostic disable-next-line: deprecated
               n[x][y] = {unconvert(form,convert(format,(unpack or table.unpack)(p)))}
            else
               n[x][y] = unconvert(form,convert(format,p))
            end
         end
      end
   end
   return w,h,n
end
return Image
