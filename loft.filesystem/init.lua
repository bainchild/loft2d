---@diagnostic disable: unused-local
local love = require('loft')
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
newFileData
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
