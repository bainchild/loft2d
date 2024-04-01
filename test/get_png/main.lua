local nogame = require("loft.nogame")
nogame()
if love.load then love.load() end
love.graphics.clear(love.graphics.getBackgroundColor())
if love.draw then love.draw() end
io.write(love.graphics._getScreen():newImageData():encode("png"):getString())
