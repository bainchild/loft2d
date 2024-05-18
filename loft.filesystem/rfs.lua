local log = require("loft._logging"):clone("rfs")
local lfs = require("lfs")
local vfs = require("loft.filesystem.vfs")()
vfs.CDirPath = "./"
local love = love or require("loft")
local rfs = setmetatable({},{__index=vfs})
-- get(path) -> file
-- isFolder(path) -> is folder?
-- mkdir(path) -> new directory just dropped
-- readfile(path) -> contents
local execute = function(a)
   log.dbg("execute","%s",a)
   return os.execute(a)
end
local popen = function(a)
   log.dbg("popen","%s",a)
   local f = assert(io.popen(a,"r"))
   local c = f:read("*a")
   f:close()
   return c
end
local function split(a,b,c)
   local ma = {}
   for mat in (a..(c or b)):gmatch("(.-)"..b) do
      ma[#ma+1]=mat
   end
   return ma
end
local function procpath(a)
   if a:sub(1,1)=="/" then return (love and love.filesystem and (table.concat(split(love.filesystem.getExecutablePath(),"/"),"/",1,-2)):gsub("[\n]","") or "~/")..a:sub(2) end
   return a
end
local function getpath(heirarchy)
   local s = ""
   for _,v in next, heirarchy do
      s=v.Name.."/"..s
   end
   s="./"..s
   return procpath(s)
end
local cache = {}
rfs.get_stream = function(path,mode)
   local npath = procpath(path)
   local info = lfs.attributes(npath)
   if info then
      if info.mode=="directory" then
         return nil, npath.." is not a file!"
      end
   else
      --return nil, "Non-existant file "..npath
      return vfs.get_stream(path,info)
   end
   local s,r = io.open(npath,mode or "a")
   if s then
      s:seek("set",0)
      return s
   end
   return false, r
end
rfs.get = function(path)
   local npath = procpath(path)
   local mode = lfs.attributes(npath)
   if mode then mode=mode.mode end
   if mode=="directory" then
      if cache[npath]==nil then
         local ls = {}
         for v in lfs.dir(npath) do --split(assert(io.popen("ls -1 "..npath,"r")):read("*a"),"\n") do
            if v~="." and v~=".." then
               local file = lfs.attributes(npath.."/"..v).mode == "file"
               ls[#ls+1] = {
                  Name = v,
                  Type = file and "Directory" or "File",
                  Content = file and "" or {},
                  DiskContent = file and "" or nil,
                  Lock = false
               }
            end
         end
         cache[npath] = {
            Name = popen("basename "..npath),
            Type = "Directory",
            Content = ls,
            Lock = false
         }
      end
   elseif mode=="file" then
      if cache[npath]==nil then
         local content = assert(io.open(assert(lfs.currentdir()).."/"..npath,"rb")):read("*a")
         cache[npath] = {
            Name = popen("basename "..npath),
            Type = "File",
            Content = content,
            DiskContent = content,
            Lock = false
         }
      end
   else
      return vfs.get(path)
   end
   return cache[npath]
end
rfs.chdir = function(path)
   local npath = procpath(path)
   local s = lfs.chdir(path)
   log.dbg("chdir","%s : %s",npath, s)
   if not s then return nil,"Couldn't change directory" end
   return vfs.chdir(path)
end
rfs.newfolder = function(options, inside)
   log.dbg("newfolder","%s",options)
   if inside==nil then inside = vfs.CurrentDirectory end
   execute("mkdir "..getpath({type(options)=="table" and options.Name or options,inside}))
   return vfs.newfolder(options, inside)
end
rfs.isFolder = function(path)
   local npath = procpath(path)
   log.dbg("isFolder","%s",npath)
   local attr = lfs.attributes(path)
   return (attr and attr.mode=="directory") or vfs.isFolder(path)
end
rfs.readfile = function(path)
   local npath = procpath(path)
   npath = assert(lfs.currentdir()).."/"..npath
   log.dbg("readfile","%s",npath)
   local s,r = io.open(npath,"rb")
   if s then
      return s:read("*a")
   else
      return vfs.readfile(path)
   end
end
return function()
   return rfs
end
