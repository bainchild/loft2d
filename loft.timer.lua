local love = require("loft")
-- local clk = function() return _clk()*2.5 end
love.timer = {}
local prov = love._provider
local clk = os.clock -- works on "CPU time", will be off by a significant amount
if prov.thread and prov.thread.time then
   clk = prov.thread.time
end
local _start = clk()
function love.timer.getTime()
   return clk() - _start
end
function love.timer.sleep(s)
   if s == nil then
      s = 1 / 30
   end
   if prov.thread and prov.thread.sleep then
      prov.thread.sleep(s)
      return
   end
   -- I mean I guess...
   -- bit destructive
   local start = clk()
   repeat
   until clk() - start >= s
end
local last_frame = clk()
local delta = 0
local avg, avgc = 0, 0
local average_delta = 0
function love.timer.step()
   delta = clk() - last_frame
   avg = avg + delta
   avgc = avgc + 1
   if avg >= 1 then
      average_delta = avg / avgc
      avg, avgc = 0, 0
   end
   last_frame = clk()
   return delta
end
function love.timer.getDelta()
   return delta
end
function love.timer.getFPS()
   return 1 / delta
end
function love.timer.getAverageDelta()
   return average_delta
end
return love.timer
