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
local thread = coroutine.create(require("loft.boot"))
assert(coroutine.resume(thread,"loft",...))
while coroutine.status(thread)~="dead" do
   local s,a,b = coroutine.resume(thread)
   if not s then print("EXIT",a,b); break end
end
