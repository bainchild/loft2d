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
      love.graphics.print("loft no game",50,50)
   end
end
return love.nogame
