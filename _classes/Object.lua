local Object = {
   _inherits={},
   _classname="Object"
}
function Object:release()
   for i in next, self do self[i]=nil end
   setmetatable(self,nil)
end
function Object:type()
   return rawget(self,"_classname")
end
function Object:typeOf(name)
   for _,v in next, rawget(self,"_inherits") do
      if v==name then
         return true
      end
   end
   return name==rawget(self,"_classname")
end
function Object:_inherit(other)
   for i,v in next, self do
      if type(i)~="string" or i:sub(1,1)~="_" then
         other[i]=v
      end
   end
   if other._inherits~=nil then
      other._inherits[#other._inherits+1] = rawget(self,"_classname")
   else
      other._inherits = {rawget(self,"_classname")}
   end
   other._inherit = self._inherit
   return other
end
return Object
