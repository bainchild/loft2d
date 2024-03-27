local socket = require("socket")
local lanes = require("lanes")
lanes.configure()
return function()
   local function mainonly(name)
      return function()
         error(name.." is only available in the main thread!")
      end
   end
   -- prevent require loop
   -- cause this will be loaded
   -- by loft.lua
   if love~=nil then
      lanes.register("loft",love)
   else
      lanes.require("loft")
   end
   if love.data~=nil then
      lanes.register("loft.data",love.data)
   else
      lanes.require("loft.data")
   end
   if love.filesystem~=nil then
      lanes.register("loft.filesystem",love.filesystem)
   else
      lanes.require("loft.filesystem")
   end
   if love.thread~=nil then
      lanes.register("loft.thread",love.thread)
   else
      lanes.require("loft.thread")
   end
   lanes.register("loft.graphics",mainonly("loft.graphics"))
   lanes.register("loft.joystick",mainonly("loft.joystick"))
   lanes.register("loft.keyboard",mainonly("loft.keyboard"))
   lanes.register("loft.mouse",mainonly("loft.mouse"))
   lanes.register("loft.touch",mainonly("loft.touch"))
   return {
      time=socket.gettime,
      sleep=socket.sleep
   }
end
