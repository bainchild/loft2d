local love = require("loft")
-- local Canvas = require('loft._classes.Canvas')
function love.nogame()
   -- local last;
   local logo, logo_data
   local start
   local past_warning, warning_transition, warning_skippable, waiting_on_screenshot = false, false, false, false
   local warning_screenshot, warning_screenshotdata
   local warning_base_time
   function love.load()
      -- last=0
      love.graphics.setBackgroundColor(226 / 255, 226 / 255, 195 / 255, 1)
      love.graphics.setPointSize(45)
      logo_data = love.image.newImageData(love.data.decode(
         "data",
         "base64",
         "\
      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\
      8ig680PH/v8AzNLk9rAFkgAAAABJRU5ErkJggg==\
      "
      ))
      logo = love.graphics.newImage(logo_data)
      start = love.timer.getTime()
   end
   local function set_transition()
      if past_warning or warning_transition or waiting_on_screenshot then
         return
      end
      if warning_skippable then
         waiting_on_screenshot = true
         love.graphics.captureScreenshot(function(img)
            warning_transition = true
            warning_screenshotdata = img
            warning_screenshot = love.graphics.newImage(img)
            warning_base_time = love.timer.getTime()
            love.graphics.setBackgroundColor(1, 1, 1, 1)
         end)
      end
   end
   local function clamp(a, b, c)
      if a < b then
         return b
      end
      if a > c then
         return c
      end
      return a
   end
   function love.update()
      if not past_warning then
         local time = love.timer.getTime()
         local space = time - start
         if space > 2 and not warning_skippable then
            warning_skippable = true
            warning_base_time = love.timer.getTime()
         elseif warning_transition and time - warning_base_time > 3.25 then
            past_warning = true
            warning_screenshot:release()
            warning_screenshotdata:release()
            waiting_on_screenshot = false
         elseif space > 60 and not warning_transition then
            set_transition()
         end
      end
   end
   local scale_w, scale_h = 1, 1
   function love.draw()
      -- love.graphics.rotate(math.pi/8)
      local width, height = 800, 600 --love.graphics.getDimensions()
      -- local r,g,b = love.graphics.getBackgroundColor()
      -- love.graphics.setColor(1-r,1-g,1-b,1)
      -- love.graphics.line(0,0,width,height)
      -- love.graphics.line(0,height,width,0)
      -- -- red, yellow, blue, green
      -- love.graphics.setColor(1,0,0,1)
      -- love.graphics.points(width/4,height/2)
      -- love.graphics.setColor(1,1,0,1)
      -- love.graphics.points(width*3/4,height/2)
      -- love.graphics.setColor(0,0,1,1)
      -- love.graphics.points(width/2,height/4)
      -- love.graphics.setColor(0,1,0,1)
      -- love.graphics.points(width/2,height*3/4)
      -- -- there is now tint!!!!
      -- love.graphics.setColor(1,1,1,1)
      love.graphics.scale(scale_w, scale_h)
      if not past_warning then
         if warning_transition then
            love.graphics.setColor(1, 1, 1, clamp(1 - ((love.timer.getTime() - warning_base_time) / 0.38), 0, 1))
            love.graphics.draw(
               warning_screenshot,
               (width / 2) - (warning_screenshotdata:getWidth() / 2),
               (height / 2) - (warning_screenshotdata:getHeight() / 2)
            )
         else
            local font = love.graphics.getFont()
            font:setFilter("nearest")
            love.graphics.setColor(2 / 255, 2 / 255, 2 / 255, 1)
            local st = "WARNING - OPEN SOURCE"
            love.graphics.print(st, (width / 2 - font:getWidth(st) * 4.5 / 2), height / 11.3, 0, 4.5)
            love.graphics.setColor(28 / 255, 28 / 255, 28 / 255, 1)
            st = "     BEFORE USING, CONSULT\n"
               .. "THE LOVE2D SOURCE AND WIKI\n"
               .. " FOR IMPORTANT INFORMATION\n"
               .. "      ABOUT THIS SOFTWARE"
            love.graphics.print(st, (width / 2 - font:getWidth(st) * 3.5 / 2), height / 4, 0, 3.5)
            st = "TO GET A COPY OF THIS SOFTWARE, GO ONLINE AT"
            love.graphics.print(st, (width / 2 - font:getWidth(st) * 2.4 / 2), height * 0.68, 0, 2.4)
            love.graphics.setColor(73 / 255, 176 / 255, 1, 1)
            st = "github.com/bainchild/loft2d"
            love.graphics.print(st, (width / 2 - font:getWidth(st) * 2.7 / 2), height * 0.75, 0, 2.7)
            if warning_skippable then
               -- oscillating grey, from 85 to 170 (/255)
               love.graphics.setColor(
                  0.1,
                  0.1,
                  0.1,
                  (waiting_on_screenshot and 1)
                     or (math.sin((love.timer.getTime() - warning_base_time + 2) / 2 * math.pi) + 1) / 2
               )
               local getos = (love.system and love.system.getOS)
               if getos and (getos() == "Android" or getos() == "iOS") then
                  st = "Touch the Touch Screen to continue."
               else
                  st = "Click anywhere or press a button to continue."
               end
               love.graphics.print(st, (width / 2 - font:getWidth(st) * 2.5 / 2), height * 0.86, 0, 2.5)
            end
         end
      else
         love.graphics.setColor(255 / 255, 255 / 255, 255 / 255, 1)
         love.graphics.draw(logo, (width / 2) - (logo_data:getWidth() / 2), (height / 2) - (logo_data:getHeight() / 2))
      end
      love.graphics.origin()
      io.write(love.graphics._getScreen():newImageData():encode("png"):getString())
      os.exit(0)
   end
   love.keypressed = set_transition
   love.textinput = set_transition
   love.mousepressed = set_transition
   love.gamepadpressed = set_transition
   love.joystickhat = set_transition
   love.joystickpressed = set_transition
   love.touchpressed = set_transition
   function love.resize(w, h)
      scale_w = w / 800
      scale_h = h / 600
   end
   function love.quit()
      -- io.write(imgdata:encode("png"):getString())
   end
   function love.conf(n)
      n.title = "LOFT2d"
         .. (love._loft_version and " v" .. love._loft_version .. " (" .. love._loft_version_code .. ")" or "")
      -- n.window.resizable = true
   end
end
return love.nogame
