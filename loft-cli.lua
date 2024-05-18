#!/usr/bin/env luajit
local loft_ = require("loft")
if (...) == "--version" then
   require("loft")
   print(loft_.getVersion())
   return
elseif (...) == "--help" then
   require("loft.boot")
   loft_.boot("loft")
   return
end
if pcall(require, "signal") then
   local function quit()
      if loft_.event and loft_.event.quit then
         loft_.event.quit()
      end
   end
   local signal = require("signal")
   signal.signal("SIGINT", quit)
   signal.signal("SIGQUIT", quit)
   signal.signal("SIGIOT", quit) -- abrt as well
end
local path = "loft"
pcall(function()
   path = assert(io.popen("basename "..debug.getinfo(3, "S").source:sub(2),"r")):read("*a"):gsub("\n","")
end)
local flags = require("loft._flags")
---@diagnostic disable-next-line: lowercase-global
if flags.expose_lib then loft = loft_ end
if flags.replace_love then
   package.preload["love"] = function() return require("loft") end
---@diagnostic disable-next-line: lowercase-global
   if flags.expose_lib then love = loft_ end
end
local cli,cli_disable
if loft_._provider.input == nil or loft_._provider.display==nil then
   require("loft.callbacks") -- now cached, will not happen again
   local colors = require("loft._ansicolors")
   local write = io.write
   local function writec(s)
      write(colors(s))
   end
   ---@diagnostic disable-next-line: unused-local
   local function lpad(a,b,c)
      return b:rep(c-#a)..a
   end
   local function rpad(a,b,c)
      return a..(b:rep(c-#a))
   end
   local function split(a,b,c)
      local m = {}
      for mat in (a..(c or b)):gmatch("(.-)"..b) do
         m[#m+1]=mat
      end
      return m
   end
   local aliases = {
      ["c"]="continue",
      ["q"]="quit",
      ["e"]="exit",
      ["s"]="screenshot",
      ["l"]="load",
      ["?"]="help"
   }
   local desc = {
      ["continue"] = "Returns control to love.run",
      ["quit"] = "Queues a quit event",
      ["exit"] = "Exits using os.exit",
      ["screenshot"] = "Takes a screenshot using filename from the first arg or image.png",
      ["load"] = "Evaluates code."
   }
   local am_quitting = false
   function cli()
      local default_cmd
      while true do
         writec("%{magenta}loft%{reset}> ")
         local cmd = io.read("l")
         if cmd==nil then os.exit(0) end
         cmd=split(cmd," ")
         local typ
         if #cmd==0 and default_cmd then
            typ = default_cmd
         else
            typ = table.remove(cmd,1)
         end
         if aliases[typ] then
            typ=aliases[typ]
         end
         for i,v in next, cmd do print(i,v) end
         if typ=="continue" then if am_quitting then cli_disable=true end return end
         if typ=="quit" then
            loft_.event.quit()
            default_cmd = "continue"
            am_quitting = true
         elseif typ=="screenshot" then
            local data = loft_.graphics._getScreen():newImageData():encode("png"):getString()
            local s,r = io.open(cmd[1] or "image.png","w")
            if not s then
               write(colors("%{red}Error opening file:%{reset} ")..tostring(r))
            else
               s:write(data)
               local s2,r2 = io.popen("realpath "..(cmd[1] or "image.png"),"r")
               if s2 then
                  write("Wrote screenshot to "..s2:read("*a"))
               else
                  write("Error finding directory for displaying information: "..tostring(r2))
               end
               s:close()
            end
            if cmd[2] then os.execute("xdg-open "..(cmd[1] or "image.png")) end
         elseif typ=="load" then
            if cmd[1]~=nil then
               local f,r = (load or loadstring)(cmd[1],"@cli")
               if not f then
                  write(colors("%{red}Error:%{reset} ")..tostring(r))
               else
                  f()
               end
            end
         elseif typ=="exit" then
            os.exit(cmd[1] and tonumber(cmd[1]) or 0)
         elseif typ=="help" then
            local first = cmd[1]
            if first then
               local alias = aliases[first]
               local targ = desc[first] or (alias and desc[alias] or nil)
               if targ==nil then
                  print("No such command "..first)
               else
                  print(rpad((aliases[first] or first)," ",12)..": "..targ)
               end
            else
               for i,v in next, desc do
                  print(rpad(i," ",12)..": "..v)
               end
            end
         end
         if typ~="quit" and typ~="help" then
            default_cmd=typ
         end
      end
   end
   function love.run()
      if love.load then
         love.load(love.parsedGameArguments, love.rawGameArguments)
      end
      if love.timer then
         love.timer.step()
      end
      return function()
         cli()
         if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
               if name == "quit" then
                  if not love.quit or not love.quit() then
                     return a or 0, b
                  end
               end
               love.handlers[name](a, b, c, d, e, f)
            end
         end
         local dt = love.timer and love.timer.step() or 0
         if love.update then
            love.update(dt)
         end
         if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())
            if love.draw then
               love.draw()
            end
            love.graphics.present()
         end
         if love.timer then
            love.timer.sleep(0.001)
         end
      end
   end
end
local thread = coroutine.create(require("loft.boot"))
assert(coroutine.resume(thread, path, ...))
while coroutine.status(thread) ~= "dead" do
   local s, a = coroutine.resume(thread)
   if s and a ~= nil then
      -- if flags.write_screenshot_on_quit then
      --    print(loft_.graphics._getScreen():newImageData():encode("png"):getString())
      -- end
      if cli and not cli_disable then
         print("About to exit, final actions?")
         cli()
      else
         os.exit((type(a)=="number" and a) or 0)
      end
   end
   if not s then
      print("error in run callback!", a)
   end
end
