local Rasterizer = require("loft._classes.Object"):_inherit({ _classname = "Rasterizer" })
function Rasterizer:getAdvance()
   return rawget(self, "_advance")
end

function Rasterizer:getAscent()
   return rawget(self, "_ascent")
end

function Rasterizer:getDescent()
   return rawget(self, "_descent")
end

function Rasterizer:getGlyphCount()
   return #rawget(self, "_glyphs")
end

function Rasterizer:getGlyphData(glyph)
   if rawget(self, "_type") == "image" then
      return nil
   end
   if type(glyph) ~= "number" then
      glyph = utf8.codepoint(glyph) --rawget(self, "_glyphmap")[glyph]
   end
   return rawget(self, "_glyphs")[glyph]
end

function Rasterizer:getHeight()
   return rawget(self, "_height")
end
function Rasterizer:getLineHeight()
   return rawget(self, "_lineheight")
end
-- ^ ?, maybe height of 1 line, compared to
-- height of the glyphs?
function Rasterizer:hasGlyphs(...)
   local glyphs = rawget(self, "_glyphs")
   -- local gm = rawget(self, "_glyphmap")
   for _, glyph in next, { ... } do
      if type(glyph) ~= "number" then
         glyph = utf8.codepoint(glyph)--gm[glyph]
      end
      if glyph == nil or glyphs[glyph] == nil then
         return false
      end
   end
   return true
end
return Rasterizer
