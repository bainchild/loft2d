local love = require('loft')
function love.nogame()
   function love.draw()
      love.graphics.print("loft no game",50,50)
   end
end
