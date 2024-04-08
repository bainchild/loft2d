local Texture = require("loft._classes.Drawable"):_inherit({ _classname = "Texture" })
local function convert(format, r, g, b, a)
   r, g, b, a = r or 0, g or 0, b or 0, a or 0
   if format:sub(-1) == "8" then
      return r / 255, g / 255, b / 255, a / 255
   elseif format:sub(-2) == "16" or format:sub(-3) == "16f" then
      return r / 65535, g / 65535, b / 65535, a / 65535
   elseif format:sub(-2) == "32" or format:sub(-3) == "32f" then
      local max = 2 ^ 31
      return r / max, g / max, b / max, a / max
   end
   return r, g, b, a
end
local function unconvert(format, r, g, b, a)
   r, g, b, a = r or 0, g or 0, b or 0, a or 0
   if format:sub(-1) == "8" then
      return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255), math.floor(a * 255)
   elseif format:sub(-2) == "16" then
      return math.floor(r * 65535), math.floor(g * 65535), math.floor(b * 65535), math.floor(a * 65535)
   elseif format:sub(-3) == "16f" then
      return r * 65535, g * 65535, b * 65535, a * 65535
   elseif format:sub(-2) == "32" then
      local max = 2 ^ 31
      return math.floor(r * max), math.floor(g * max), math.floor(b * max), math.floor(a * max)
   elseif format:sub(-3) == "32f" then
      local max = 2 ^ 31
      return r * max, g * max, b * max, a * max
   end
   return r, g, b, a
end
function Texture:getDPIScale()
   return rawget(self, "_dpiscale")
end
function Texture:getDepth()
   if rawget(self, "_type") ~= "volume" then
      return 1
   end
   return rawget(self, "_depth")
end
function Texture:getDepthSampleMode()
   return rawget(self, "_depthsamplemode")
end
function Texture:getDimensions()
   return rawget(self, "_width"), rawget(self, "_height")
end
function Texture:getFilter()
   return rawget(self, "_filter")
end
function Texture:getFormat()
   return rawget(self, "_pxformat")
end
function Texture:getHeight()
   return rawget(self, "_height")
end
-- todo:
-- getLayerCount
-- getMipmapCount
-- getMipmapFilter
function Texture:getPixelDimensions()
   return math.floor(rawget(self, "_width") * rawget(self, "_dpiscale")),
      math.floor(rawget(self, "_height") * rawget(self, "_dpiscale"))
end
function Texture:getPixelHeight()
   return math.floor(rawget(self, "_height") * rawget(self, "_dpiscale"))
end
function Texture:getPixelWidth()
   return math.floor(rawget(self, "_width") * rawget(self, "_dpiscale"))
end
-- getTextureType
function Texture:getWidth()
   return rawget(self, "_width")
end
-- getWrap
-- isReadable
-- setDepthSampleMode
-- setFilter
-- setMipmapFilter
-- setWrap
function Texture:_default(type, format)
   if type == nil then
      type = "2d"
   end
   if format == nil or format == "normal" then
      format = "rgba8"
   end
   local n
   if type == "2d" then
      n = {
         _width = 1,
         _height = 1,
         _dpiscale = 1,
         _pxformat = format,
         _type = type,
         _pxarray = {},
      }
      if format == "r8" or format == "r16" or format == "r16f" or format == "r32f" then
         n._pxarray[1] = { 0 }
      elseif format == "rg8" or format == "rg16" or format == "rg16f" or format == "rg32f" then
         n._pxarray[1] = { { 0, 0 } }
      elseif
         format == "rgba8"
         or format == "srgba8"
         or format == "rgba18"
         or format == "rgba16f"
         or format == "rgba32f"
      then
         n._pxarray[1] = { { 0, 0, 0 } }
      else
         return nil
      end
   else
      return nil
   end
   for i, v in next, self do
      n[i] = v
   end
   return n
end
function Texture:_getpxarray(form)
   local format = rawget(self, "_format")
   local px = rawget(self, "_pxarray")
   local w, h = rawget(self, "_width"), rawget(self, "_height")
   local n = {}
   if form == nil then
      for x = w, 1, -1 do
         n[x] = {}
         for y = h, 1, -1 do
            local p = px[x][y]
            -- divides to make it 0-1 range
            if type(p) == "table" then
               ---@diagnostic disable-next-line: deprecated
               n[x][y] = { convert(format, (unpack or table.unpack)(p)) }
            else
               n[x][y] = convert(format, p)
            end
         end
      end
   elseif form == format then
      for x = w, 1, -1 do
         n[x] = {}
         for y = h, 1, -1 do
            n[x][y] = px[x][y]
         end
      end
   else
      for x = w, 1, -1 do
         n[x] = {}
         for y = h, 1, -1 do
            local p = px[x][y]
            if type(p) == "table" then
               ---@diagnostic disable-next-line: deprecated
               n[x][y] = { unconvert(form, convert(format, (unpack or table.unpack)(p))) }
            else
               n[x][y] = unconvert(form, convert(format, p))
            end
         end
      end
   end
   return w, h, n
end
return Texture
