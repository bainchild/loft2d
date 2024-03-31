---@diagnostic disable: undefined-global
return {
   check=function()
      return task~=nil and (time~=nil or tick~=nil)
   end,
   get=function()
      return {
         time=time or tick;
         sleep=task.wait;
      }
   end
}
