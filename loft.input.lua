local love = require("loft")
local input = { que = {}, provs = {} }
love._input = input
local q = input.que
function input.mousemoved(x, y)
   q[#q + 1] = { "mouse", "moved", x, y }
end
function input.mousescroll(vscroll, hscroll)
   q[#q + 1] = { "mouse", "scroll", vscroll, hscroll }
end
function input.mousebutton(x, y, button, down)
   q[#q + 1] = { "mouse", "button", x, y, button, down }
end
function input.key(scancode, code, down)
   q[#q + 1] = { "keyboard", scancode, code, down }
end
function input.joystickadded(id)
   q[#q + 1] = { "joystick", "add", id }
end
function input.joystickremoved(id)
   q[#q + 1] = { "joystick", "remove", id }
end
function input.joystickbutton(id, code, down)
   q[#q + 1] = { "joystick", "button", id, code, down }
end
function input.joystickaxis(id, code, offset)
   q[#q + 1] = { "joystick", "axis", id, code, offset }
end
function input.touchpressed(id, x, y, pressure)
   q[#q + 1] = { "touch", "press", id, x, y, pressure }
end
function input.touchreleased(id, x, y)
   q[#q + 1] = { "touch", "release", id, x, y }
end
local state = {}
input.state = state
local green = {}
if love._provider.input then
   for i, v in next, love._provider.input do
      if v.check and v.check() and v.setup then
         v.setup(input)
         green[i] = true
      end
   end
end
local prevmx,prevmy = 0,0
function input.update()
   if love._provider.input then
      for i, v in next, love._provider.input do
         if green[i] == nil and v.check ~= nil and v.check() then
            green[i] = true
         end
         if green[i] and v.input_update then
            v.input_update()
         end
      end
   end
   if #q == 0 then
      return
   end
   local ev = table.remove(q, 1)
   if love._provider.input then
      for i, v in next, love._provider.input do
         if green[i] and v.event then
            v.event(ev)
         end
      end
   end
   ---@diagnostic disable: empty-block
   if ev[1] == "mouse" then
      if ev[2] == "moved" then
         -- x,y
         love.event.push("mousemoved",ev[3],ev[4],ev[3]-prevmx,ev[4]-prevmy,false)
         prevmx,prevmy = ev[3],ev[4]
      elseif ev[2] == "scroll" then
         -- vs,hs
         love.event.push("wheelmoved",ev[3],ev[4])
      elseif ev[2] == "button" then
         -- x,y,btn,down
         if ev[6] then
            love.event.push("mousepressed",ev[3],ev[4],ev[5],false,1)
         else
            love.event.push("mousereleased",ev[3],ev[4],ev[5],false,1)
         end
      end
   elseif ev[1] == "keyboard" then
      -- scancode, code, down/up
      if ev[4] then
         love.event.push("keyreleased",ev[3],ev[2],ev[4])
      else
         love.event.push("keypressed",ev[3],ev[2],ev[4])
      end
   elseif ev[1] == "joystick" then
      if ev[2] == "add" then
         -- id
      elseif ev[2] == "remove" then
         -- id
      elseif ev[2] == "button" then
         -- id, code, down
      elseif ev[2] == "axis" then
         -- id, code, offset
      end
   elseif ev[1] == "touch" then
      if ev[2] == "press" then
         -- id,x,y,pressure
      elseif ev[2] == "released" then
         -- id,x,y
      end
   end
end
if love._steps then
   love._steps[#love._steps+1] = input.update
else
   love._steps = {input.update}
end
return input
