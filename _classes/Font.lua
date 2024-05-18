local utf8 = utf8 or require("utf8")
local Font = require("loft._classes.Data"):_inherit({ _classname = "Font" })
local GlyphData = require("loft._classes.GlyphData")
local ImageData = require("loft._classes.ImageData")
local log = require("loft._logging"):clone("Font")
local function change_img(imgdata)
   local w, h = imgdata:getDimensions()
   local px = rawget(imgdata, "_pixels")
   local npx = {}
   for x = w, 1, -1 do
      npx[x] = {}
      for y = h, 1, -1 do
         local v = px[x][y]
         npx[x][y] = { 255, 255, 255, v }
      end
   end
   return ImageData:_new("rgba8", w, h, npx)
end
function Font:setFilter(f)
   rawset(self, "_filter", f)
end
function Font:getFilter()
   return rawget(self, "_filter")
end
function Font:getBaseline()
   return rawget(self,"_baseline")
end
function Font:getLineHeight()
   return rawget(self,"_lineheight")
end
function Font:getWidth(str)
   local glyphs = rawget(self, "_glyphs")
   local xp = 0
   local function doit(codepoint)
      local glyph = glyphs[codepoint]
      if glyph ~= nil then
         xp = xp + glyph:getWidth()
      end
   end
   if utf8.codes then
      for codepoint in utf8.codes(str) do
         doit(codepoint)
      end
   elseif utf8.next then
      for _, codepoint in utf8.next, str do
         doit(codepoint)
      end
   end
   return xp
end
function Font:_newBMTable(bmt, size)
   -- bmt = { fnt = {[type] = {{cmd}}, pageid = base64_encoded_file }
   local n = {
      _size = size,
   }
   -- TODO: info.padding, info.spacing
   -- maybe, if it matters..
   -- TODO: this one really matters, the common alphaChnl,rChnl,gChnl,bChnl and char.chnl
   -- are NOT handled, and should be.
   if bmt.fnt.info ~= nil then
      n._face = bmt.fnt.info[1].face
      n._ogsize = bmt.fnt.info[1].size
      if size == nil then
         n._size = n._ogsize
      end
   end
   if bmt.fnt.common == nil then
      error("bad table")
   end
   local com = bmt.fnt.common[1]
   n._lineheight = com.lineHeight
   n._baseline = com.base
   local pages = {}
   for i = 0, com.pages - 1 do
      pages[i] = change_img(
         ImageData:_decode(love.data.decode("string", "base64", assert(bmt[i], "bad font table: no page " .. i)))
      )
   end
   local glyphs = {}
   n._glyphs = glyphs
   n._pages = pages
   if bmt.fnt.char then
      for _, v in next, bmt.fnt.char do
         -- print(v.id, "=", v.x, v.y, v.width, v.height)
         local imgd =
            assert(pages[v.page], "No page " .. v.page .. " for char " .. v.id):_window(v.x, v.y, v.width, v.height)
         glyphs[v.id] = GlyphData:_new(v.id, v.xoffset, v.yoffset, v.xadvance, v.width, v.height, imgd)
      end
   end
   local kerns = {}
   n._kerns = kerns
   if bmt.fnt.kerning then
      for _, v in next, bmt.fnt.kerning do
         if kerns[v.first] == nil then
            kerns[v.first] = {}
         end
         kerns[v.first][v.second] = v.amount
      end
   end
   for i, v in next, Font do
      n[i] = v
   end
   return n
end
function Font:_getScalingFactor()
   if rawget(self, "_ogsize") == nil then
      return 1
   end
   -- print("YEAH",rawget(self,"_size"), rawget(self,"_ogsize"), rawget(self,"_size")/rawget(self,"_ogsize"))
   return rawget(self, "_size") / rawget(self, "_ogsize")
end
function Font:_arrange(txt, wrap, align)
   local locs = {}
   local lineheight = rawget(self, "_lineheight")
   local base = rawget(self, "_baseline")
   local glyphs = rawget(self, "_glyphs")
   local kerns = rawget(self, "_kerns")
   -- V this joke is now deprecated because it's yp not yo
   -- yo waddup
   local xp, yp = 0, 0 --rawget(self, "_baseline")
   local prevcode
   local firs = true
   -- log.dbg("arrange","arranging string %q",txt)
   local function doit(codepoint)
      -- log.dbg("arrange","codepoint: %d",codepoint)
      if (wrap and xp >= wrap) or codepoint == 10 then
         xp = 0
         yp = yp + lineheight
         if codepoint == 10 then
            return
         end
      end
      local glyph = glyphs[codepoint]
      if glyph == nil then
         log.dbg("arrange", "unavailable glyph %s", codepoint)
         glyph = glyphs[63]
      end
      if glyph ~= nil then
         locs[#locs + 1] = {
            glyph = glyph,
            x = xp + rawget(glyph, "_xoffset"),
            y = yp - base + rawget(glyph, "_yoffset"),
         }
         xp = xp + glyph:getAdvance()
         if prevcode and kerns[prevcode] and kerns[prevcode][codepoint] then
            xp = xp + kerns[prevcode][codepoint]
         end
         prevcode = codepoint
      end
      firs = false
   end
   if utf8.codes then
      for codepoint in utf8.codes(txt) do
         doit(codepoint)
      end
   elseif utf8.next then
      for _, codepoint in utf8.next, txt do
         doit(codepoint)
      end
   end
   return locs
end
return Font
