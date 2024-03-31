local love = require('loft')
function love.nogame()
   local last;
   function love.load()
      last=0
   end
   function love.update(dt)
      if love.timer.getTime()-last>2 then
         print("NOGAME: FPS = "..(1/dt))
         last=love.timer.getTime()
      end
   end
   function love.draw()
      local width,height = love.graphics.getDimensions()
      love.graphics.print("loft no game",math.floor(width/2),math.floor(height/2))
   end
end
return love.nogame
