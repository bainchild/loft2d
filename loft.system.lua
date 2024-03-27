local love = require("loft")
love.system = {}
function love.system.getPowerInfo()
   if love._provider.system and love._provider.system.battery then
      local bat = love._provider.system.battery
      return bat.state, bat.percent, bat.estimatedTime
   end
   return "unknown", nil, nil
end
function love.system.getOS()
   return love._os
end
function love.system.getProcessorCount()
   return love._provider.thread.getOptimalThreadCount()
end
function love.system.hasBackgroundMusic()
   return false
end
function love.system.openURL(url)
   if love._provider.system and love._provider.system.openURL then
      return love._provider.system.openURL(url)
   end
   return false
end
function love.system.getClipboard()
   if love._provider.system and love._provider.system.getClipboard then
      return love._provider.system.getClipboard()
   end
   return ""
end
function love.system.setClipboard(text)
   if love._provider.system and love._provider.system.setClipboard then
      love._provider.system.setClipboard(text)
   end
end
function love.system.vibrate(seconds)end
return love.system
