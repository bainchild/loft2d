local love = require('loft')
function love.load()
   love.graphics.setColor(1,1,1,1)
   love.graphics.setBackgroundColor(0,0,0,1)
   love.graphics.setPointSize(45)
end
function love.draw()
   love.graphics.print("hey ya!!",50,50)
   io.write(love.graphics._getScreen():newImageData():encode("png"):getString())
   os.exit(0)
end
