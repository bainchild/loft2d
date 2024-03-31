local love = require('loft')
love.graphics = {}
function love.graphics.isActive()
   return false
end
function love.graphics.isCreated()
   return true
end
function love.graphics.reset() end
function love.graphics.setFont() end
function love.graphics.newFont() end
function love.graphics.setColor() end
function love.graphics.origin() end
return love.graphics
