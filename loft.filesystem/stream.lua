local function typecast(var, type_)
   local vartype = type(var)
   if vartype == type_ then
      return true, var
   end
   if vartype == "string" then
      if type_ == "number" then
         local new = tonumber(var)
         if new then
            return true, new
         else
            return false, nil
         end
      end
   elseif vartype == "number" then
      if type_ == "string" then
         return true, tostring(var)
      end
   end
   return false, nil
end
-- local function typecheck(var,pos,name,typ)
--    if type(typ)=="string" then
--       if type(var)~=typ then
--          error("bad argument #"..pos.." to '"..name.."' ("..typ.." expected, got "..(var==nil and "no value" or type(var))..")")
--       end
--    elseif type(typ)=="table" then
--       local mat = false
--       for _,v in next,typ do
--          if type(var)==v then mat=true;break end
--       end
--       if not mat then
--          error("bad argument #"..pos.." to '"..name.."' ("..typ[1].." expected, got "..(var==nil and "no value" or type(var))..")")
--       end
--    end
-- end
local function typecheckv(name, types, ...)
   local can_cast = types.implicit_casting
   local nargs, args = select("#", ...), { ... }
   local ret = {}
   for i, v in next, types do
      if type(i) == "number" then
         local val = args[i]
         local type_ = type(val)
         local is_none = i > nargs and val == nil
         local required = not v.optional
         if v.custom then
            local success, reason = v[1](val, type_, is_none, (can_cast and typecast) or nil)
            if required and success == nil then
               error(
                  "bad argument #" .. i .. " to '" .. name .. "'" .. (reason ~= nil and " (" .. reason .. ")" or ""),
                  3
               )
            end
            if success ~= nil then
               val = success
            end
         else
            local matched, bad_typecast = false, false
            if not is_none then
               for ti, b in next, v do
                  --print('awlcast',typecast(val,b))
                  if type(ti) == "number" and (type_ == b or can_cast) then
                     if can_cast then
                        local s, r = typecast(val, b)
                        --print('cast',s,r)
                        val = r
                        if not s then
                           bad_typecast = true
                           break
                        end
                     end
                     matched = true
                     break
                  end
               end
            end
            --print(matched,required,bad_typecast)
            if not matched then
               if required or bad_typecast then
                  error(
                     "bad argument #"
                        .. i
                        .. " to '"
                        .. name
                        .. "' ("
                        .. v[1]
                        .. " expected, got "
                        .. (is_none and "no value" or type_)
                        .. ")",
                     3
                  )
               elseif v.default and is_none then
                  val = v.default
               end
            end
         end
         ret[i] = val
      end
   end
   ---@diagnostic disable-next-line: deprecated
   return unpack(ret)
end

local stream = {}
local function raw_is_stream(a)
   return type(a) == "table" and getmetatable(a) == stream
end
local function is_stream(a, t, is_none)
   if raw_is_stream(a) then
      return a
   else
      return nil, "expected *FILE, got " .. (is_none and "no value" or t)
   end
end
function stream.read(...)
   local self, b = typecheckv("read", {
      { is_stream, custom = true },
      { "string", "number", optional = true, default = 1 },
   }, ...)
   if b == "*a" then
      if rawget(self, "ptr") >= #rawget(self, "src") then
         return ""
      else
         local content = rawget(self, "src"):sub(rawget(self, "ptr"))
         rawset(self, "ptr", #rawget(self, "src"))
         return content
      end
   elseif b == "*l" then
      local n, c = "", ""
      ---@diagnostic disable-next-line: cast-local-type
      repeat
         n = n .. c
         c = self:read(1)
      until c == nil or c == "\n"
      return n
   elseif b == "*n" then
      error("read('*n') isn't supported!")
   elseif type(b) ~= "number" then
      -- b=tonumber(b)
      -- if b==nil then
      error("bad argument #2 to 'read' (invalid option)")
      -- end
   end
   if rawget(self, "ptr") > #self.src then
      return nil
   end
   rawset(self, "ptr", rawget(self, "ptr") + b)
   return rawget(self, "src"):sub(rawget(self, "ptr") - b + 1, rawget(self, "ptr"))
end
function stream.write(...)
   local self, b = typecheckv("write", {
      implicit_casting = true,
      { is_stream, custom = true },
      { "string" },
   }, ...)
   local src, ptr = rawget(self, "src"), rawget(self, "ptr")
   rawset(self, "src", src:sub(1, ptr) .. b .. src:sub(ptr + #b + 1))
   rawset(self, "ptr", ptr + #b)
   if rawget(self, "_modified") ~= nil then
      rawget(self, "_modified")(self)
   end
   return true
end
function stream.seek(...)
   local self, b, c = typecheckv("seek", {
      implicit_casting = true,
      { is_stream, custom = true },
      { "string", optional = true, default = "cur" },
      { "number", optional = true, default = 0 },
   }, ...)
   if b == "set" then
      rawset(self, "ptr", c)
   elseif b == "cur" then
      rawset(self, "ptr", rawget(self, "ptr") + c)
   elseif b == "end" then
      rawset(self, "ptr", #rawget(self, "src") + c)
   else
      error("bad argument #2 to 'seek' (invalid option " .. ("'" .. b .. "'") .. ")", 3)
   end
   if rawget(self, "ptr") > #rawget(self, "src") then
      rawset(self, "ptr", #rawget(self, "ptr"))
   end
   return rawget(self, "ptr")
end
function stream.close(...)
   local self = typecheckv("close", {
      { is_stream, custom = true },
   }, ...)
   rawset(self, "closed", true)
   if rawget(self, "_closed") then
      rawget(self, "_closed")(self)
   end
   for i in next, self do
      rawset(self, i, nil)
   end
   setmetatable(self, nil)
end
function stream.lines(...)
   local self = typecheckv("lines", {
      { is_stream, custom = true },
   }, ...)
   local file = self
   return function()
      return file:read("*l")
   end
end
function stream.setvbuf(...)
   local _ = typecheckv("setvbuf", { -- self
      { is_stream, custom = true },
   }, ...)
   error("'setvbuf' is unimplemented", 2)
end
function stream.flush(...)
   local self = typecheckv("flush", {
      { is_stream, custom = true },
   }, ...)
   if rawget(self, "_flushed") ~= nil then
      rawget(self, "_flushed")(self)
   end
end
stream.__index = stream
-- TODO: how would I make "getmetatable(file)==getmetatable(file).__index" work
-- while also doing this? V

-- function stream.__index(...)
--    local self,i = typecheckv('__index',{
--       {is_stream,custom=true};
--       {required=false};
--    },...)
--    if rawequal(i,"src") or rawequal(i,"ptr") then
--       return nil
--    end
--    return rawget(stream,i)
-- end

-- TODO: rawtostring(?)
-- function stream.__tostring(...)
--    local self = typecheckv('__index',{
--       implicit_casting=false;
--       {is_stream,custom=true};
--    },...)
--    return 'file ('..(string.match(tostring(self),"0x%x+") or string.format('%x',math.random(1,800)+0x600002))..')'
-- end

-- stream.__metatable = "locked"
-- stream.Destroy = stream.close
local Stream = {}
function Stream.new(content)
   return setmetatable({ src = content or "", ptr = (content and #content) or 0 }, stream)
end
return { factory = Stream, meta = stream, is = raw_is_stream }
