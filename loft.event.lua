local love = require("loft")
local unpack = (unpack or table.unpack)
local timer = require("loft.timer")
love.event = { _que = {} }
function love.event.clear()
   love.event._que = {}
end
function love.event.poll()
   local q = love.event._que
   return function()
      if #q == 0 then
         return nil
      end
      return unpack(table.remove(q, 1))
   end
end
function love.event._fpoll()
   local q = {}
   for i, v in next, love.event._que do
      q[i] = v
   end
   local i = 0
   return function()
      i = i + 1
      if q[i] == nil then
         return nil
      end
      return unpack(q[i])
   end
end
function love.event.pump()
   -- this is basically the love C-side update function.
   -- I think.
   for _, v in next, love._providers do
      if type(v) == "table" and v.loft_step ~= nil then
         v.loft_step()
      end
   end
   if love._step then
      love._step()
   end
   timer.sleep(1 / 1000)
end
function love.event.push(n, ...)
   love.event._que[#love.event._que + 1] = { n, ... }
end
function love.event.quit(exitstat)
   love.event._que[#love.event._que + 1] = { "quit", exitstat or 0 }
end
function love.event.wait()
   if #love.event._que > 0 then
      return unpack(table.remove(love.event._que, 1))
   end
   repeat
      timer.sleep(1 / 1000)
   until #love.event._que > 0
   return unpack(table.remove(love.event._que, 1))
end
return love.event
