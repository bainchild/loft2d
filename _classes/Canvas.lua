-- literally a paintable texture
local Canvas = require("loft._classes.Texture"):_inherit({ _classname = "Canvas" })
local ImageData = require("loft._classes.ImageData")
local love = require("loft")
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
function Canvas:generateMipmaps() end
function Canvas:getMSAA()
   return 0
end
function Canvas:getMipmapMode()
   return "none"
end
function Canvas:newImageData(...)
   -- TODO: dpiscale!!
   if select("#", ...) == 0 then
      return ImageData:_new(
         rawget(self, "_pxformat"),
         rawget(self, "_width"),
         rawget(self, "_height"),
         rawget(self, "_pxarray")
      )
   end
   error("TODO: newImageData overloads")
end
function Canvas:renderTo(index, func)
   if func == nil then
      func = index
      index = nil
   end
   if love.graphics == nil then
      return
   end
   local prevcanvas = love.graphics.getCanvas()
   love.graphics.setCanvas(self)
   func()
   love.graphics.setCanvas(prevcanvas)
end
function Canvas:_new(width, height, dpi, format, px, fill_pixel)
   if dpi == nil then
      dpi = 1
   end
   if format == nil then
      format = "rgba8"
   end
   if px == nil then
      px = {}
      if fill_pixel == nil then
         if format == "r8" or format == "r16" or format == "r16f" or format == "r32f" then
            for x = width, 1, -1 do
               px[x] = {}
               for y = height, 1, -1 do
                  px[x][y] = 0
               end
            end
         elseif format == "rg8" or format == "rg16" or format == "rg16f" or format == "rg32f" then
            for x = width, 1, -1 do
               px[x] = {}
               for y = height, 1, -1 do
                  px[x][y] = { 0, 0 }
               end
            end
         elseif
            format == "rgba8"
            or format == "srgba8"
            or format == "rgba18"
            or format == "rgba16f"
            or format == "rgba32f"
         then
            for x = width, 1, -1 do
               px[x] = {}
               for y = height, 1, -1 do
                  px[x][y] = { 0, 0, 0, 0 }
               end
            end
         else
            return nil
         end
      else
         for x = width, 1, -1 do
            px[x] = {}
            for y = height, 1, -1 do
               px[x][y] = fill_pixel
            end
         end
      end
   end
   local n = {
      _width = width,
      _height = height,
      _dpiscale = dpi,
      _pxformat = format,
      _pxarray = px,
   }
   for i, v in next, self do
      n[i] = v
   end
   return n
end
function Canvas:_getpxarray(form)
   -- TODO: dpiscale
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
function Canvas:_clone_nc(fill)
   return Canvas:_new(
      rawget(self, "_width"),
      rawget(self, "_height"),
      rawget(self, "_dpiscale"),
      rawget(self, "_format"),
      nil,
      fill
   )
end
return Canvas
