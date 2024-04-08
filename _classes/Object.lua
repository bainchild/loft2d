local Object = {
   _inherits = {},
   _classname = "Object",
   _isAobject = true,
}
function Object:release()
   for i in next, self do
      self[i] = nil
   end
   setmetatable(self, nil)
end
function Object:type()
   return rawget(self, "_classname")
end
function Object:typeOf(name)
   for _, v in next, rawget(self, "_inherits") do
      if v == name then
         return true
      end
   end
   return name == rawget(self, "_classname")
end
function Object:_default() end
function Object:_securitize()
   ---@type table
   local new = {}
   for i, v in next, self do
      if type(v) == "table" and rawget(v, "_isAobject") then
         new[i] = v:_securitize()
      else
         new[i] = v
      end
   end
   local meta = {}
   if getmetatable(self) then
      for i, v in next, getmetatable(self) do
         if i == "__metatable" then
            meta = getmetatable(self)
            break
         end
         meta[i] = v
      end
      if meta.__metatable == nil then
         meta.__metatable = "locked"
      end
      setmetatable(new, meta)
   end
   rawset(new, "_inherit", nil)
   return new
end
function Object:_inherit(other)
   for i, v in next, self do
      -- if string and begins with _, then discard
      if type(i) ~= "string" or i:sub(1, 1) ~= "_" then
         other[i] = v
      end
   end
   if other._inherits ~= nil then
      for _, v in next, rawget(self, "_inherits") do
         print("inehrting..", v)
         other._inherits[#other._inherits + 1] = v
      end
   else
      ---@diagnostic disable-next-line: deprecated
      other._inherits = { (unpack or table.unpack)(rawget(self, "_inherits")) }
   end
   other._inherits[#other._inherits + 1] = rawget(self, "_classname")
   other._inherit = self._inherit
   if other._default == nil then
      other._default = self._default
   end
   if other._securitize == nil then
      other._securitize = self._securitize
   end
   other._isAobject = true
   return other
end
return Object
