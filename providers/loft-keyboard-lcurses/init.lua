local lc,scr
local mod = {}
return {
   check=function()
      return (pcall(require,"lcurses"))
   end;
   get=function()
      if mod then return mod end
      local lc = lc or require('curses')
      if lc.scr==nil then lc.scr = lc.initscr() end
      scr = lc.scr
      scr:timeout(-1)
      scr:keypad(true)
      mod = {}
      local evs = {}
      function mod.loft_step()
         
      end
      return mod
   end
}
