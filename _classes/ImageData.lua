local FileData = require("loft._classes.FileData")
local ImageData = require("loft._classes.Data"):_inherit({ _classname = "ImageData" })
-- this is just texture but again
-- , and without dpi
-- ImageData:encode()
-- ImageData:paste()
local encoders = {
   ["png"] = require("loft._formats.png"),
}
function ImageData:encode(form, name)
   return FileData:_new(encoders[form].into(self), name or ("file." .. form))
end
function ImageData:_decode(src, form)
   if form == nil then
      for _, v in next, encoders do
         if v.isA and v.isA(src) then
            return v.from(src)
         end
      end
   else
      return encoders[form].from(src)
   end
end
function ImageData:getDimensions()
   return rawget(self, "_width"), rawget(self, "_height")
end
function ImageData:getFormat()
   return rawget(self, "_format")
end
function ImageData:getWidth()
   return rawget(self, "_width")
end
function ImageData:getHeight()
   return rawget(self, "_height")
end
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
function ImageData:getPixel(x, y)
   x, y = math.floor(x) + 1, math.floor(y) + 1
   return convert(rawget(self, "_format"), (unpack or table.unpack)(rawget(self, "_pixels")[x][y]))
end
local love
function ImageData:mapPixel(func, x, y, width, height)
   if x == nil then
      x = 1
   else
      x = x + 1
   end
   if y == nil then
      y = 1
   else
      y = y + 1
   end
   if width == nil then
      width = rawget(self, "_width")
   end
   if height == nil then
      height = rawget(self, "_height")
   end
   if rawget(self, "_mutable") == false then
      if love == nil then
         love = require("loft")
      end
      if love.timer and love.timer.sleep then
         repeat
            love.timer.sleep(1 / 1000)
         until rawget(self, "_mutable")
      else
         error("Locked imagedata! (unable to sleep until unlocked)")
      end
   end
   rawset(self, "_mutable", false)
   local px = rawget(self, "_pixels")
   local s, r = pcall(function()
      ---@diagnostic disable-next-line: redefined-local
      for x = x, width do
         ---@diagnostic disable-next-line: redefined-local
         for y = y, height do
            local r, g, b, a = convert(rawget(self, "_format"), (unpack or table.unpack)(px[x][y]))
            px[x][y] = { unconvert(rawget(self, "_format"), func(x, y, r, g, b, a)) }
         end
      end
   end)
   rawset(self, "_mutable", true)
   assert(s, r)
end
function ImageData:setPixel(x, y, r, g, b, a)
   x,y=x+1,y+1
   if rawget(self, "_mutable") == false then
      if love.timer and love.timer.sleep then
         repeat
            love.timer.sleep(1 / 1000)
         until rawget(self, "_mutable")
      else
         error("Locked imagedata! (unable to sleep until unlocked)")
      end
   end
   if x>rawget(self,"_width") or y>rawget(self,"_height") or x<1 or y<1 then
      error("out of bounds imagedata write")
   end
   rawget(self, "_pixels")[x][y] = { unconvert(rawget(self, "_format"), r, g, b, a) }
end
function ImageData:_window(x, y, xs, ys)
   local opx = rawget(self, "_pixels")
   local px = {}
   local n = {}
   for i, v in next, self do
      n[i] = v
   end
   n._mutable = true
   n._pixels = px
   n._width = xs
   n._height = ys
   for nx = xs, 1, -1 do
      px[nx] = {}
      for ny = ys, 1, -1 do
         -- print(nx,ny,'->',nx+x,ny+y,' = ',opx[nx+x][ny+y])
         px[nx][ny] = opx[nx + x][ny + y]
      end
   end
   return n
end
function ImageData:_default(format)
   local n = {
      _mutable = true,
      _format = format,
      _pixels = { { { 0, 0, 0, 0 } } },
      _width = 1,
      _height = 1,
   }
   for i, v in next, self do
      n[i] = v
   end
   return n
end
function ImageData:_new(format, x, y, px)
   local n = {
      _mutable = true,
      _format = format,
      _pixels = px,
      _width = x,
      _height = y,
   }
   for i, v in next, self do
      n[i] = v
   end
   return n
end
return ImageData
