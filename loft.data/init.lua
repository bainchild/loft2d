local ByteData = require("loft._classes.ByteData")
local love = require("loft")
love.data = {}
love.data.newByteData = ByteData.new
local b64 = require("loft.data.base64")
function love.data.decode(container, encoding, src)
   if type(src) == "table" and rawget(src, "_isAobject") then
      src = src:getString()
   end
   local res
   if encoding == "base64" then
      res = b64.decode(src)
   elseif encoding == "hex" then
      res = (string.gsub(src, "(%x%x)", function(a)
         return string.char(tonumber(a, 8))
      end))
   else
      error("Unknown encoding '" .. tostring(encoding) .. "'")
   end
   if container == "data" then
      return ByteData.new(res)
   elseif container == "string" then
      return res
   end
   return nil
end
function love.data.encode(container, encoding, src, _)
   if type(src) == "table" and rawget(src, "_isAobject") then
      src = src:getString()
   end
   local res = ""
   if encoding == "base64" then
      res = b64.encode(src)
   elseif encoding == "hex" then
      res = (string.gsub(src, ".", function(a)
         return string.format("%02x", string.byte(a))
      end))
   else
      error("Unknown encoding '" .. tostring(encoding) .. "'")
   end
   if container == "data" then
      return ByteData.new(res)
   elseif container == "string" then
      return res
   end
   return nil
end
function love.data.newDataView(data, offset, size)
   return data.new(data:getString():sub(offset, offset + size))
end
return love.data
