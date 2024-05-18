local filesystem
local File = require("loft._classes.Object"):_inherit({ _classname = "File" });
function File:close()
   self._mode = "c"
   self._stream = nil
end
-- flush
-- getBuffer
-- getFilename
-- getMode
-- getSize
-- isEOF
-- isOpen
-- lines
function File:open(mode)
   if filesystem == nil then filesystem = require("loft.filesystem") end
   self._mode = mode
   local s,r = filesystem._vfs.get_stream(self._filename,mode)
   if s then
      self._stream = s
      return true
   else
      return false, r
   end
   return false, "Unimplemented ("..mode..")"
end
function File:read(bytes)
   assert(self._stream~=nil,"File isn't open!")
   return self._stream:read((bytes or "*a"))
end
-- seek
-- setBuffer
-- tell
-- write
---
function File.new(name,mode) -- rw append closed (rwac)
   local n = {}
   for i,v in next, File do
      if type(i)=="string" and i:sub(1,1)~="_" and i~="new" then
         n[i] = v
      end
   end
   n._filename = name;
   if mode then
      local s,r = n:open(mode)
      if not s then return nil, r end
   end
   return n
end
return File
