#!/usr/bin/env luajit
if (...)=="--version" then
   require("loft")
   print(love.getVersion())
   return
elseif (...)=="--help" then
   require("loft.boot")
   love.boot("loft")
   return
end
if (pcall(require,"signal")) then
   love=require("loft")
   local function quit()
      if love.event and love.event.quit then
         love.event.quit()
      end
   end
   local signal = require("signal")
   signal.signal("SIGINT",quit)
   signal.signal("SIGQUIT",quit)
   signal.signal("SIGIOT",quit) -- abrt as well
end
local thread = coroutine.create(require("loft.boot"))
assert(coroutine.resume(thread,"loft",...))
while coroutine.status(thread)~="dead" do
   local s,a = coroutine.resume(thread)
   if s and a~=nil then os.exit(a or 0); end
   if not s then print("error in run callback!",a) end
end
