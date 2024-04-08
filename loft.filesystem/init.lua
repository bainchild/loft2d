---@diagnostic disable: unused-local
local FileData = require("loft._classes.FileData")
local love = require("loft")
local log = require('loft._logging')
local vfs = require("loft.filesystem.vfs")()
love.filesystem = { _vfs = vfs }
local identity = "loft"
local execname = "loft"
local fused = false
local source = nil
local function split(a, b, c)
   local m = {}
   for mat in (a .. (c or b)):gmatch("(.-)" .. b) do
      m[#m + 1] = mat
   end
   return m
end
function love.filesystem.append(name, data, size)
   if type(data) == "table" and rawget(data, "_isAobject") and data:typeOf("Data") then
      data = data:getString()
   end
   if size then
      data = data:sub(1, size)
   end
   name = love.arg.normalslashes(name)
   return vfs.writefile(name, data)
end
function love.filesystem.areSymlinksEnabled()
   return true
end
function love.filesystem.createDirectory(name)
   name = love.arg.normalslashes(name)
   local s = split(name, "/")
   local prevp = ""
   for _, v in next, s do
      prevp = prevp .. "/"
      local np = prevp .. v
      if vfs.get(np) ~= nil then
         if not vfs.isFolder(np) then
            return false, "name in path occupied"
         end
      else
         local suc, r = vfs.mkdir(prevp)
         if not suc then
            return suc, r
         end
      end
      prevp = prevp .. v
   end
   return true
end
function love.filesystem.exists(file)
   file = love.arg.normalslashes(file)
   return vfs.get(file) ~= nil
end
function love.filesystem.getAppdataDirectory()
   return love.filesystem.getUserDirectory()
end
function love.filesystem.getCRequirePath()
   return ""
end
function love.filesystem.getDirectoryItems(dir)
   dir = love.arg.normalslashes(dir)
   local s, fold = vfs.get(dir)
   local files = {}
   for i, v in next, fold.Content do
      files[#files + 1] = v.Name
   end
   return files
end
function love.filesystem.getIdentity()
   return identity
end
function love.filesystem.getInfo(path, filetype, info) -- place holding
   path = love.path.normalslashes(path)
   local got = vfs.get(path)
   if got then
      local type = (got.Type == "File" or got.Type == "Directory" or got.Type == "SymLink" and got.Type:lower())
         or "other"
      local size = (got.Type == "File" and #got.DiskContent) or nil
      local modtime = got.ModifiedTime
      if filetype ~= nil and type ~= filetype then
         return nil
      end
      if info then
         info.type = type
         info.size = size
         info.modtime = modtime
         return info
      else
         return {
            type = type,
            size = size,
            modtime = modtime,
         }
      end
   else
      return nil
   end
end
function love.filesystem.getLastModified(path)
   path = love.path.normalslashes(path)
   local got = vfs.get(path)
   if got ~= nil then
      return got.ModifiedTime
   else
      return false, "file does not exist"
   end
end
function love.filesystem.getRealDirectory(path)
   -- get absolute path, get rid of path var from the end of it.
   if not love.path.abs(path) then
      path = vfs.CDirPath .. path
   end
   if path:sub(-1) ~= "/" then
      local spli = split(path, "/")
      path = table.concat(spli, "/", 1, #spli - 1)
   end
   path = love.path.normalslashes(path)
   path = love.path.endslash(path)
   return path
end
function love.filesystem.getRequirePath()
   return ""
end
-- getSaveDirectory
function love.filesystem.getSize(path)
   path = love.path.normalslashes(path)
   local got = vfs.get(path)
   if got ~= nil then
      return got.Size
   else
      return false, "file does not exist"
   end
end
function love.filesystem.getSource()
   return source
end
-- getSourceBaseDirectory
-- getUserDirectory
function love.filesystem.getWorkingDirectory()
   return vfs.CDirPath
end
function love.filesystem.init(appname)
   execname = appname
end
-- isDirectory
-- isFile
function love.filesystem.isFused()
   return fused
end
-- isSymlink
-- lines
-- load
-- mount
-- newFile
function love.filesystem.newFileData(contents, name)
   if type(contents) == "table" and rawget(contents, "_isAobject") and contents:typeOf("Data") then
      contents = contents:getString()
   elseif name == nil then
      name = contents
      local s, r = pcall(vfs.readfile, name)
      if not s then
         return nil, r
      end
      contents = r
   end
   local new = {
      _string = contents,
      _size = #contents,
      _fullname = name,
   }
   for i, v in next, FileData do
      new[i] = v
   end
   return new
end
-- read
-- remove
-- setCRequirePath
function love.filesystem.setIdentity(name)
   identity = name
end
-- setRequirePath
function love.filesystem.setSource(src)
   log.note("loft.filesystem","setSource","%s",src)
   error("this is needed for nogame")
   source = src
end
-- setSymlinksEnabled
-- unmount
-- write

---- internal, not on wiki
function love.filesystem.getExecutablePath()
   -- absolute path of executable
   return "/" .. execname -- sure
end
function love.filesystem.setFused(tf)
   fused = tf
end
function love.filesystem._setAndroidSaveExternal(bool) end
source = love.filesystem.getWorkingDirectory()
return love.filesystem
