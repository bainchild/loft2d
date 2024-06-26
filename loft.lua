---@diagnostic disable: unused-local
local flags = require('loft._flags')
local log = require('loft._logging')
log.env = flags.env or 'prod'
log.debug = flags.debug or false
log.quiet = flags.quiet or false
---@diagnostic disable-next-line: lowercase-global
love = {
   _version = "11.5",
   _loft_version = "scm",
   _loft_version_code = "Flying Beagle",
   _provider = {},
   _providers = {},
}
if package and package.loaded then
   package.loaded["loft"] = love
end
function love._switch_to_provider(type, name)
   love._provider[type] = love._providers[type][name]()
end
-- for i,v in next, {
--    ["thread"] = {"lanes_sock","luau"}
-- } do
--    love._providers[i] = {}
--    for _,v2 in next, v do
--       love._providers[i][v2] = require("loft-"..i.."-"..v2)
--    end
-- end
love._providers.thread = {
   lanes_sock = require("loft-thread-lanes_sock"),
   luau = require("loft-thread-luau"),
}
-- displaying stuff will be the MOST
-- resource-intensive part, so it deserves
-- to be sorted
-- local display_priority = {
--    ["unknown"] = -math.huge;
--    ["PixelArray"] = 1;
--    ["PrimitiveExport"] = 2;
-- }
-- local satisfactory_display_priority = 2
for i, v in next, love._providers do
   if love._provider[i] == nil then
      for i2, v2 in next, v do
         log.dbg("loft","init","%s: %s %s",i2,v2.check==nil,v2.check~=nil and v2.check())
         if v2.check == nil or v2.check() then
            love._provider[i] = v2.get()
            log.note("loft","init","Using %s provider %s",i,i2)
            -- print("LOFT: Using "..i2.." as a "..i.." provider")
            break
         end
      end
   elseif i=="input" then
      local pro = love._provider[i]
      if pro==nil then pro={}; love._provider[i]=pro end
      for i2, v2 in next, v do
         log.dbg("loft","init","%s: %s %s",i2,v2.check==nil,v2.check~=nil and v2.check())
         if v2.check == nil or v2.check() then
            pro[#pro+1] = v2.get()
            log.note("loft","init","Using %s provider %s",i,i2)
            -- print("LOFT: Using "..i2.." as a "..i.." provider")
         end
      end
      -- elseif i=="display" and display_priority[love._provider.display.renderingInteface or "unknown"] < satisfactory_display_priority then
      --    local existing_priority = display_priority[love._provider.display.renderingInterface or "unknown"]
      --    for i2,v2 in next, v do
      --       if (v2.check==nil or v2.check()) and display_priority[v2.get().renderingInterface or "unknown"]>existing_priority then
      --          love._provider[i]=v2.get()
      --          print("LOFT: Using "..i2.." as a "..i.." provider")
      --          break
      --       end
      --    end
   end
end
--
local deprecation = false
function love.getVersion()
   return love._version
end
function love.isVersionCompatible(ver, minor, revision)
   return true
end -- TODO: check versions
function love.hasDeprecationOutput()
   return deprecation
end
function love.setDeprecationOutput(bool)
   deprecation = bool
end -- placeholed...
return love
