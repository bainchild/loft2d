-- I think including a half-baked permission system
-- isn't worth
local VFS = {}
VFS.debug = false
VFS.Files = {
   Name = "root",
   Type = "Directory",
   -- Permissions={R=6,W=6};
   Content = {},
   Lock = false,
}
-- VFS.CurrentUserPermissions = 6;
VFS.CurrentDirectory = VFS.Files
VFS.CDirPath = "/"
local stream = require("loft.filesystem.stream")
local function find(a, b)
   for i, v in next, a do
      if rawequal(v, b) then
         return i
      end
   end
end
local function split(a, b, c)
   local m = {}
   for mat in (a .. (c or b)):gmatch("(.-)" .. b) do
      m[#m + 1] = mat
   end
   return m
end
local backup_handler = nil
local sync = nil
local function traverseTree(path, followSymLinks, SymLinksFollowed)
   SymLinksFollowed = SymLinksFollowed or {}
   local splitted = split(path, "/")
   --print("tt split path",split)
   local to_remove = {}
   for i, v in next, splitted do
      if v:gsub("%s", "") == "" or v == "." then
         to_remove[#to_remove + 1] = i
      end
   end
   local removed = 0
   for _, v in next, to_remove do
      table.remove(splitted, v - removed)
   end
   --print("tt AFTER split path",split)
   if #splitted == 0 then
      return true, VFS.CurrentDirectory, VFS.CurrentDirectory
   end
   local last, lasts = nil, {}
   local current = VFS.CurrentDirectory
   for i = 1, #splitted do
      last = current
      if splitted[i] == ".." then
         if last == nil then
            current = VFS.CurrentDirectory
         else
            current = last
            last = table.remove(lasts)
         end
      end
      lasts[#lasts + 1] = last
      -- print('currently in "'..tostring((current or {Name='??'}).Name)..'" <'..tostring((current or {Type='??'}).Type)..">")
      if current.Type == "SymLink" then
         if followSymLinks and find(SymLinksFollowed, current) == nil then
            SymLinksFollowed[#SymLinksFollowed + 1] = current
            local s, r = traverseTree(current.Content, followSymLinks, SymLinksFollowed)
            if s then
               current = r
               table.remove(SymLinksFollowed, #SymLinksFollowed)
            else
               break
            end
         else
            break
         end
      elseif current.Type == "Directory" then
         current = current.Content
         local set = false
         for _, v in next, current do
            -- print('SEARCH',v.Name,'==',splitted[i])
            if v.Name == splitted[i] then
               -- print('FOUND!!!! :',v)
               current = v
               set = true
               break
            end
         end
         if not set then
            current = nil
         end
      end
      if current == nil then
         break
      elseif current == last or current.Type == "File" then
         break
      end
   end
   if current == nil and backup_handler ~= nil then
      return backup_handler(path, followSymLinks, SymLinksFollowed)
   end
   return current ~= nil, current, last
end
-- local function check(perm,Name)
-- 	local success,file,parent = traverseTree(VFS.CDirPath..Name,true)
-- 	if success and file then
-- 		local v = (file.Permissions and VFS.CurrentUserPermissions<=(file.Permissions[perm] or -10000) and not file.Lock) or (file.Permissions==nil)
-- 		if v then
-- 			return true
-- 		else
-- 			return false, "Insufficient permissions to "..(perm=="W" and "write to" or "read").." file "..tostring(Name)
-- 		end
-- 	else
-- 		if perm=="R" then
-- 			return false, "Couldn't reach file "..Name..", are you sure it exists?"
-- 		else
-- 			local v = (parent.Permissions and VFS.CurrentUserPermissions<=(parent.Permissions[perm] or -10000)) or (parent.Permissions==nil)
-- 			if v then
-- 				return true
-- 			else
-- 				return false, "Insufficient permissions to write to file "..tostring(Name)
-- 			end
-- 		end
-- 	end
-- end

-- local _fileDeprecationWarning = true
local function newFile(options, c, inside)
   if inside == nil then
      inside = VFS.CurrentDirectory
   end
   if type(options) == "string" and type(c) == "string" then
      -- if _fileDeprecationWarning then
      -- 	print("newFile(): overload (Name,content) is deprecated and will be removed in a future version")
      -- 	_fileDeprecationWarning=false;
      -- end
      options = {
         Name = options,
         Type = "File",
         Content = c,
         DiskContent = c,
         -- Permissions={R=6,W=6};
         Lock = false,
      }
   end
   -- assert(check("W",options.Name))
   for i, v in next, inside.Content do
      if v.Name == options.Name and v.Type == "File" then
         table.remove(inside.Content, i)
      end
   end
   table.insert(inside.Content, options)
end
-- local _foldDeprecationWarning = true
local function newFolder(options, inside)
   if inside == nil then
      inside = VFS.CurrentDirectory
   end
   if type(options) == "string" then
      -- if _foldDeprecationWarning then
      -- 	print("newFolder(): overload (dirname) is deprecated and will be removed in a future version")
      -- 	_foldDeprecationWarning=false;
      -- end
      options = {
         Name = options,
         Type = "Directory",
         -- Permissions={R=6,W=6};
         Content = {},
         Lock = false,
      }
   end
   -- assert(check("W",options.Name))
   for i, v in next, inside.Content do
      if v.Name == options.Name and v.Type == "Folder" then
         table.remove(inside.Content, i).Deleted = true
      end
   end
   local content = inside.Content
   content[#content + 1] = options
end
newFolder({
   Name = "tmp",
   Type = "Directory",
   Content = {},
   Lock = false,
})
VFS.set_sync = function(f, update)
   sync = f
   if update then
      VFS.Files = f()
      local s = VFS.chdir(VFS.CDirPath)
      if not s then
         VFS.chdir("/")
      end
   end
end
VFS.set_backup = function(back)
   backup_handler = back
end
VFS.sync = function(d)
   -- just assume d is a file or folder
   if sync ~= nil then
      sync(VFS.Files, d or VFS.Files)
   end
end
VFS.chdir = function(path)
   -- print("chdir",path)
   if path == "." then
      return path
   end
   -- print("chdir++2",traverseTree(VFS.CDirPath..path,true))
   local suc, r = traverseTree(path, true)
   if suc and r.Type == "Directory" then
      VFS.CDirPath = path
      VFS.CurrentDirectory = r
      return VFS.CDirPath
   end
   return false
end
VFS.newfolder = newFolder
VFS.newfile = newFile
VFS.writefile = function(name, c)
   if name:sub(-1) == "/" then
      return false, "not a path to a file"
   end
   local s, fold = traverseTree(name)
   if s then
      if fold.Type == "Directory" then
         fold.DiskContent = c
         return true
      else
         return false, "name is occupied"
      end
   end
   s, fold = nil, nil
   local spli = split(name, "/")
   name = table.concat(spli, "/", 1, #spli - 1)
   s, fold = traverseTree(name)
   if s then
      return false, "no parent directory"
   end
   VFS.newfile({
      Name = name,
      Type = "File",
      Content = c,
      DiskContent = c,
      Lock = false,
   }, nil, fold)
   return true
end
VFS.mkdir = function(name)
   local s = traverseTree(name)
   if s then
      return false, "folder already exists"
   end
   if name:sub(-1) == "/" then
      name = name:sub(1, -2)
   end
   local spli = split(name, "/")
   name = table.concat(spli, "/", 1, #spli - 1)
   local fold
   s, fold = traverseTree(name)
   if s then
      return false, "no parent directory"
   end
   VFS.newfolder({
      Name = name,
      Type = "Directory",
      Content = {},
      Lock = false,
   }, fold)
   return true
end
VFS.traverse = traverseTree
VFS.get_stream = function(name, _)
   -- local suc,err = check(purpose=="r" and "R" or "W",name)
   -- if not suc then return suc, err end
   local s, file = traverseTree(name)
   --print(Name,s,file)
   -- print(require("inspect")(file))
   if not s then
      return s, "Couldn't find file " .. tostring(name) .. " are you sure it exists?"
   end
   local str = stream.factory.new(file.Content)
   file.Lock = true
   rawset(str, "_flushed", function()
      if sync ~= nil then
         sync(VFS.Files, file)
      end
   end)
   rawset(str, "_modified", function(self)
      if not file.Deleted then
         file.Content = rawget(self, "src")
      end
   end)
   rawset(str, "_closed", function()
      file.Lock = false
   end)
   str:seek("set", 0)
   return str
end
VFS.readfile = function(Name)
   -- assert(check("R",Name))
   local s, file = traverseTree(Name)
   --print(Name,s,file)
   assert(s, "Couldn't find file " .. tostring(Name) .. " are you sure it exists?")
   return (type(file.Content) == "string" and file.Content or file.Content())
end
VFS.isfile = function(Name)
   -- if not (check("R",Name)) then return false end
   local s, file = traverseTree(Name)
   return s and file.type == "File" -- and (File(file))
end
VFS.isfolder = function(Name)
   -- if not (check("R",Name)) then return false end
   local s, fold = traverseTree(Name)
   return s and fold.type == "Directory" -- and (Folder(fold))
end
VFS.get = function(Name)
   local s, fold = traverseTree(Name)
   return s and fold
end
VFS.rm = function(Name)
   -- assert(check("W",Name))
   local s, file, p = traverseTree(Name)
   assert(s, "Couldn't find file " .. tostring(Name) .. " are you sure it exists?")
   ---@diagnostic disable-next-line: param-type-mismatch, need-check-nil
   table.remove(p, find(p.Content, file)).Deleted = true
   return true
end
return function(state, backup_handl, sync_handl)
   if backup_handl ~= nil then
      backup_handler = backup_handl
   end
   if sync_handl ~= nil then
      sync = sync_handl
      if state ~= nil and type(state) == "table" then
         sync(state, state)
      else
         state = sync()
      end
   end
   if state == nil or type(state) ~= "table" then
      state = VFS.Files
   else
      VFS.Files = state
      VFS.CurrentDirectory = state
   end
   return VFS, state
end
