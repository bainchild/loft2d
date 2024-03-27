---@diagnostic disable: unused-local
---@diagnostic disable-next-line: lowercase-global
love = {
  _version="11.5",
  _provider={},
  _providers={}
}
if package and package.loaded then
   package.loaded["loft"] = love
end
function love._switch_to_provider(type,name)
   love._provider[type] = love._providers[type][name]()
end
for i,v in next, {
   ["thread"] = {"lanes_sock"}
} do
   love._providers[i] = {}
   for _,v2 in next, v do
      love._providers[i][v2] = require("loft-"..i.."-"..v2)
   end
end
for i,v in next, love._providers do
   if love._provider[i]==nil then
      for i2,v2 in next, v do
         love._provider[i]=v2()
         print("LOFT: Using "..i2.." as a "..i.." provider")
         break
      end
   end
end
--
local deprecation = false
function love.getVersion() return love._version end
function love.isVersionCompatible(ver,minor,revision) return true end -- TODO: check versions
function love.hasDeprecationOutput() return deprecation end
function love.setDeprecationOutput(bool) deprecation=bool end -- placeholed...
return love
