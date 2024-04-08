local file = assert(io.open(assert((...), "Pass a .fnt file"), "r"))
local base64 = require('base64')
local bmfont = require("bmfont")
local nding = file:seek("end")
file:seek("set", 0)
local function popen(cmd)
   print("> " .. cmd)
   local fh = io.popen(cmd, "r")
   if fh == nil then
      return false, "Failed to execute command"
   end
   return fh:read("*a")
end
local pages = {}
local cmds = {}
while file:seek("cur") < nding do
   local cmd = bmfont(file)
   local typ = cmd.type
   if cmds[typ] == nil then
      cmds[typ] = {}
   end
   cmd.type = nil
   cmds[typ][#cmds[typ] + 1] = cmd
   if typ == "page" then
      pages[cmd.id] = base64.encode(io.open(cmd.file,"rb"):read("*a"))
   end
end
pages.fnt = cmds
local function indent(a, b, c)
   return (a:gsub("\n", "\n" .. (b:rep(c))))
end
local function serialize(a)
   if type(a) == "number" or type(a) == "nil" or type(a) == "boolean" then
      return tostring(a)
   end
   if type(a) == "string" then
      return "'" .. a .. "'"
   end
   if type(a) == "table" then
      local str = ""
      str = str .. "{\n"
      local last
      for i, v in next, a do
         if type(i) == "number" and ((last == nil and i == 1) or (last ~= nil and i == last + 1)) then
            last = i
            str = str .. "   " .. indent(serialize(v), " ", 3) .. ";\n"
         else
            str = str .. "   [" .. serialize(i) .. "]=" .. indent(serialize(v), " ", 3) .. ";\n"
         end
      end
      str = str .. "}"
      return str
   end
end
local function split(a, b, c)
   local ma = {}
   for mat in (a .. (c or b)):gmatch("(.-)" .. b) do
      ma[#ma + 1] = mat
   end
   return ma
end
local s = "return " .. serialize(pages)
local filename = split((...), "%.", ".")
filename = table.concat(filename, ".", 1, #filename - 1) .. ".lua"
print("writing to " .. filename)
local file2 = assert(io.open(filename, "wb"), "can't open " .. filename .. " for writing")
file2:write(s)
file2:close()
