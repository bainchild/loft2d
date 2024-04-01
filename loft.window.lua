---@diagnostic disable: unused-local
local love = require("loft")
require("loft.graphics")
local prov = love._provider
love.window = {}
local defmode = {
  width=prov.display and prov.display.width or 800,
  height=prov.display and prov.display.height or 600,
  flags={
    fullscreen=true,
    fullscreentype="exclusive", -- desktop
    vsync=1,
    msaa=0,
    resizable=false,
    borderless=true,
    centered=true,
    display=1,
    highdpi=false,
    refreshrate=0,
    x=nil,
    y=nil
  }
}
defmode.flags.minwidth = defmode.width
defmode.flags.minheight = defmode.height
local mode = defmode
local use_dpi_scale = true
local dpi_scale = 1
love.window._mode = mode
if love.graphics then love.graphics._newScreen(mode.width,mode.height,dpi_scale) end
local function round(a)
   if a%1==0 then return a end
   if a%1>=.5 then return a-(a%1)+1 end
   return a-(a%1)
end
function love.window._conditionalFromPixels(num)
   if use_dpi_scale then return round(num/dpi_scale) end
   return num
end
function love.window._conditionalToPixels(num)
   if use_dpi_scale then return round(num*dpi_scale) end
   return num
end
local cfp = love.window._conditionalFromPixels
function love.window.getMode()
   if mode==nil then return nil,nil,nil end
   return mode.width,mode.height,mode.flags
end
function love.window.close()
   mode.width,mode.height,mode.flags = nil,nil,nil
   if prov.display and prov.display.closed then prov.display.closed() end
end
local function merge(a,b)
   local n = {}
   for i,v in next, a do n[i]=v end
   for i,v in next, b do n[i]=v end
   return n
end
local function clone(a)
   local n = {}
   for i,v in next, a do n[i]=v end
   return n
end
function love.window.setMode(width,height,flags)
   if width==mode.width and height==mode.height and mode.flags~=nil then
      local bad = false
      local cur = mode.flags
      for i,v in next, flags do
         if i~="stencil" and i~="depth" and i~="usedpiscale" and cur[i]~=v then
            print("mismatching value:",i,cur[i],v)
            bad=true
         end
      end
      if not bad then return true end
   end
   if prov.display and prov.display.DPIEnabled then
      dpi_scale = prov.display.DPIScale
   end
   if prov.display and (prov.display.sizeCompatible==nil or prov.display.sizeCompatible(width,height)) then
      mode.width=(width==0 and defmode.width) or width or (mode and mode.width) or defmode.width
      mode.height=(height==0 and defmode.height) or height or (mode and mode.height) or defmode.height
      mode.flags=merge(mode.flags or defmode.flags,flags)
      if flags then
         -- flags.stencil
         -- flags.depth
         if flags.usedpiscale~=nil then
            use_dpi_scale=flags.usedpiscale
         end
      end
      if prov.display.changeSize then
         prov.display.changeSize(mode.width,mode.height)
      end
      if prov.display.changeFlags then
         prov.display.changeFlags(mode.flags)
      end
      if love.graphics then love.graphics._newScreen(mode.width,mode.height,dpi_scale) end
      return true
   end
   return false
end
function love.window.setPosition(x,y,display)
   if display==nil then display=1 end
   if (display>(prov.display.DisplayCount or 1) or display<1) then error("Invalid display id: "..display) end
   if prov.display and mode.flags then
      local newflags = clone(mode.flags)
      newflags.x = x
      newflags.y = y
      newflags.display = display
      if prov.display.changeFlags and not prov.display.changeFlags(newflags) then
         return false
      end
      mode.flags=newflags
   end
end
function love.window.getDPIScale()
   return dpi_scale
end
function love.window.getDesktopDimensions(idx)
   if idx==nil then idx=1 end
   if prov.display and prov.display.getDisplaySize then
      if idx>(prov.display.DisplayCount or 1) or idx<1 then return 0,0 end
      return prov.display.getDisplaySize(idx)
   end
   if idx>1 or idx<1 then return 0,0 end
   return 800,600
end
function love.window.getDisplayCount()
   if prov.display and prov.display.DisplayCount then
      return prov.display.DisplayCount
   end
   return 1
end
function love.window.getDisplayName(idx)
   if idx==nil then idx=1 end
   if prov.display and prov.display.getDisplayName then
      if idx>(prov.display.DisplayCount or 1) or idx<1 then error("Invalid display index: "..idx) end
      return prov.display.getDisplayName(idx)
   end
   if idx>1 or idx<1 then error("Invalid display index: "..idx) end
   return "Display"
end
function love.window.getDisplayOrientation(idx)
   if idx==nil then idx=1 end
   if prov.display and prov.display.getDisplayOrientation then
      if idx>(prov.display.DisplayCount or 1) or idx<1 then error("Invalid display index: "..idx) end
      return prov.display.getDisplayOrientation(idx)
   end
   if idx>1 or idx<1 then error("Invalid display index: "..idx) end
   return "landscape"
end
function love.window.getFullscreen()
   if mode.flags==nil then return nil,nil end
   return mode.flags.fullscreen, mode.flags.fullscreentype
end
local prevmode
function love.window.setFullscreen(full,type)
   if mode.flags then
      local newmode = {flags=clone(mode.flags)}
      if full then
         local set = false
         if type == "exclusive" or type==nil then
            local compats = love.window.getFullscreenModes(mode.flags.display)
            for _,v in next, compats do
               if v.width==mode.width and v.height==mode.height then
                  set=true
                  break
               end
            end
         elseif type == "desktop" then
            local x,y = prov.display.getDisplaySize(mode.flags.display)
            if mode.width~=x or mode.height~=y then
               set=true
            end
         end
         if set then
            prevmode={mode.width,mode.height,mode.flags}
            local x,y = prov.display.getDisplaySize(mode.flags.display)
            newmode.width,newmode.height = x,y
         end
      elseif prevmode then
         newmode.width,newmode.height,newmode.flags = prevmode[1],prevmode[2],prevmode[3]
      end
      newmode.flags.fullscreen = full
      if type then mode.flags.fullscreentype = type end
      if prov.display and prov.display.changeFlags then
         if not prov.display.changeFlags(newmode) then
            return false
         end
      end
      mode.width,mode.height,mode.flags = newmode.width,newmode.height,newmode.flags
      return true
   end
end
function love.window.getFullscreenModes(idx)
   if idx==nil then idx=1 end
   if prov.display and prov.display.getCompatibleResolutions then
      if idx>(prov.display.DisplayCount or 1) or idx<1 then error("Invalid display index: "..idx) end
      return prov.display.getCompatibleResolutions(idx)
   end
   if idx>1 or idx<1 then error("Invalid display index: "..idx) end
   return {{width=800,height=600}}
end
-- TODO: geticon, seticon
function love.window.getIcon()
   return nil
end
function love.window.setIcon(img)
   return false
end
function love.window.getPosition()
   if mode.flags==nil then return 0,0,1 end
   return mode.flags.x,mode.flags.y,mode.flags.display
end
function love.window.getSafeArea()
   local x,y,w,h = 0,0,mode.width or 800,mode.height or 600
   if prov.display and prov.display.getSafeArea then
      x,y,w,h = prov.display.getSafeArea(1)
   end
   if use_dpi_scale then
      local fpx=love.window.fromPixels
      return fpx(x),fpx(y),fpx(w),fpx(h)
   end
   return x,y,w,h
end
local title = "LOFT2d"
function love.window.getTitle()
   return title
end
function love.window.setTitle(txt)
   if prov.display and prov.display.setWindowTitle then
      prov.display.setWindowTitle(txt)
   end
   title=txt
end
function love.window.hasFocus()
   if prov.display then
      return prov.display.KeyboardFocus
   end
   return true
end
function love.window.hasMouseFocus()
   if prov.display then
      return prov.display.MouseFocus
   end
   return true
end
function love.window.isDisplaySleepEnabled()
   return false
end
function love.window.setDisplaySleepEnabled(enable) end
function love.window.isMaximized()
   if mode.width and mode.height and prov.display and prov.display.getDisplaySize then
      local x,y = prov.display.getDisplaySize(1)
      if mode.width==x and mode.height==y and (mode.flags==nil or (mode.flags.x==0 and mode.flags.y==0)) then
         return true
      end
   end
   return false
end
function love.window.isMinimized()
   if prov.display and prov.display.isMinimized() then
      return prov.display.isMinimized()
   end
   return false
end
function love.window.isOpen()
   return not love.window.isMinimized()
end
love.window.isVisible = love.window.isOpen
function love.window.maximize()
   prevmode={mode.width,mode.height,mode.flags}
   if prov.display and prov.display.maximize then
      prov.display.maximize()
   end
end
function love.window.minimize()
   prevmode={mode.width,mode.height,mode.flags}
   if prov.display and prov.display.minimize then
      prov.display.minimize()
   end
end
function love.window.restore()
   if prevmode then
      mode.width,mode.height,mode.flags=prevmode[1],prevmode[2],prevmode[3]
      prevmode=nil
      if prov.display then
         if prov.display.changeSize then
            prov.display.changeSize(mode.width,mode.height)
         end
         if prov.display.changeFlags then
            prov.display.changeFlags(mode.flags)
         end
      end
   end
end
function love.window.requestAttention(continuous)
   if prov.display and prov.display.requestAttention then
      prov.display.requestAttention()
   end
end
function love.window.setVSync(sync)
   if mode.flags then
      mode.flags.vsync = sync
   end
end
function love.window.showMessageBox(titleo,msg,buttons,type,attach)
   if prov.display and prov.display.messageBox then
      if type(buttons)=="string" or type(buttons)=="nil" and type==nil and attach==nil then
         return prov.display.messageBox(titleo,msg,buttons or "info",type or type==nil)
      elseif type(buttons)=="table" then
         return prov.display.messageBox(titleo,msg,buttons,type or "info",attach or attach==nil)
      end
   end
   return false
end
function love.window.fromPixels(val)
   return round(val/dpi_scale)
end
function love.window.toPixels(val)
   return round(val*dpi_scale)
end
return love.window
