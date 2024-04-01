local love = require('loft')
function love.nogame()
   -- local last;
   function love.load()
      -- last=0
      love.graphics.setBackgroundColor(0,0,0,1)
      love.graphics.setPointSize(45)
   end
   -- function love.update(dt)
   --    if love.timer.getTime()-last>2 then
   --       print("NOGAME: FPS = "..(1/dt))
   --       last=love.timer.getTime()
   --    end
   -- end
   function love.draw()
      local width,height = love.graphics.getDimensions()
      love.graphics.line(0,0,width,height)
      love.graphics.line(0,height,width,0)
      -- red, yellow, blue, green
      love.graphics.setColor(1,0,0,1)
      love.graphics.points(width/4,height/2)
      love.graphics.setColor(1,1,0,1)
      love.graphics.points(width*3/4,height/2)
      love.graphics.setColor(0,0,1,1)
      love.graphics.points(width/2,height/4)
      love.graphics.setColor(0,1,0,1)
      love.graphics.points(width/2,height*3/4)
   end
   -- function love.quit()
   --    io.write(love.graphics._getScreen():newImageData():encode("png"):getString())
   -- end
end
return love.nogame
