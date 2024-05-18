local Cursor = require("loft._classes.Cursor")
local input = require("loft._input")
local love = require("loft")
local mouse = {}
local visible = true
-- getCursor
-- getPosition
-- getRelativeMode
-- getSystemCursor
-- getX
-- getY
-- isCursorSupported
-- isDown
-- isGrabbed
function mouse.isVisible()
   return visible
end
-- newCursor
function mouse.setCursor(curs)
   -- dummy function created to make an example work
end
-- setGrabbed
-- setPosition
-- setRelativeMode
function mouse.setVisible(tf)
   visible=tf
end
-- setX
-- setY
love.mouse = mouse
return love.mouse
