local love = require("loft")
local filesystem = require("loft.filesystem")._vfs
love.thread = {}
function love.thread.newThread(codd)
   local newcod = "" -- who's fish?
   if #codd > 1024 or codd:find("\n") then
      -- code
      newcod=codd
   elseif type(codd)=="table" and codd:typeOf(codd) then
      newcod=codd:getString()
   else
      -- filename.
      newcod=filesystem.readfile(codd)
   end
   if love._provider.thread==nil then
      error("No thread provider.")
   end
   return love._provider.thread.new(newcod)
end
return love.thread
