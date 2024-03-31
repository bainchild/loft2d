---@diagnostic disable: unused-local
local love = require('loft')
local FileData = require('loft._classes.FileData')
local vfs = require("loft.filesystem.vfs")()
love.filesystem = {_vfs=vfs}
local identity="loft"
local execname="loft"
local fused=false
--[[
setSource
remove
getRealDirectory
read
write
getSize
load
mount
lines
getSource
unmount
newFile
getUserDirectory
getAppdataDirectory
getSaveDirectory
getSourceBaseDirectory
createDirectory
append
getDirectoryItems
setSymlinksEnabled
areSymlinksEnabled
getRequirePath
setRequirePath
getCRequirePath
setCRequirePath
exists
isDirectory
isFile
isSymlink
getLastModified
]]
function love.filesystem.getRealDirectory(path)
   -- get absolute path, get rid of path var from the end of it.
   return nil
end
function love.filesystem.getWorkingDirectory()
   return "/"
end
function love.filesystem.getExecutablePath()
   -- absolute path of executable
   return "./"..execname -- sure
end
function love.filesystem.getInfo(path,mattype) -- place holding
   return nil
end
function love.filesystem.newFileData(contents,name)
   if type(contents)=="table" and rawget(contents,"_isAobject") and contents:typeOf("Data") then
      contents=contents:getString()
   elseif name==nil then
      name=contents
      local s,r = pcall(vfs.readfile,name)
      if not s then
         return nil, r
      end
      contents=r
   end
   local new = {
      _string=contents;
      _size=#contents;
      _fullname=name;
   }
   for i,v in next, FileData do
      new[i]=v
   end
   return new
end
--
function love.filesystem._setAndroidSaveExternal(bool) end
function love.filesystem.init(appname)
   execname=appname
end
function love.filesystem.isFused()
   return fused
end
function love.filesystem.setFused(tf)
   fused=tf
end
function love.filesystem.setIdentity(name)
   identity=name
end
function love.filesystem.getIdentity()
   return identity
end
return love.filesystem
