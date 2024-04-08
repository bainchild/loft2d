local function read_until(s, char, ignore, can_eof)
   local str, c = "", ""
   repeat
      local pc = c
      if ignore == nil or not c:match(ignore) then
         str = str .. c
      end
      c = s:read(1)
      if c == nil then
         if can_eof then
            break
         end
         error(
            "Unexpected EOF @ " .. s:seek("cur") .. " " .. char .. ": " .. tostring(pc) .. " so far: " .. tostring(str)
         )
      end
   until c:match(char)
   return str, c
end
return function(s)
   local cur = s:seek("cur")
   local ending = s:seek("end")
   s:seek("set", cur)
   local cmd, lastchar = read_until(s, "[\n ]", "%s")
   if lastchar == "\n" then
      return { type = cmd }
   end
   local infos = { type = cmd }
   while true do
      local name, last2 = read_until(s, "=", "%s", true)
      if last2 == nil then
         break
      end
      local value, last = read_until(s, '[ \n"]', "%s", true)
      if last == '"' then
         if #value == 0 then
            value, last = read_until(s, '"')
         else
            local v2, l2 = read_until(s, "[ \n]", "%s")
            value = value .. last .. v2
            last = l2
         end
      elseif tonumber(value) ~= nil then
         ---@diagnostic disable-next-line: cast-local-type
         value = tonumber(value)
      end
      ---@diagnostic disable-next-line: assign-type-mismatch
      infos[name] = value
      if last == "\n" or s:seek("cur") >= ending then
         break
      end
   end
   return infos
end
