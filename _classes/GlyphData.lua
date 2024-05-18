local GlyphData = require("loft._classes.Data"):_inherit({ _classname = "GlyphData" })
local Image = require("loft._classes.Image")
-- advance = where next glyph should be placed
-- position = where the current is placed
-- bearing = difference between full BB's width and pixel BB's width
-- bounding box (this ctx) = full BB
-- dimensions = pixel BB

-- "x height" = lowercase top-of-letter line up height
-- "cap height" = capital top-of-letter line up height
-- ascender = above cap height
-- descender = below baseline
function GlyphData:getAdvance()
   return rawget(self, "_advance")
end
function GlyphData:getBearing()
   error("no idea")
end
function GlyphData:getBoundingBox()
   return rawget(self, "_x"), rawget(self, "_y"), rawget(self, "_width"), rawget(self, "_height")
end
function GlyphData:getFormat()
   return rawget(self, "_format")
end
function GlyphData:getGlyph()
   return rawget(self, "_id")
end
function GlyphData:getGlyphString()
   return utf8.char(rawget(self, "_id"))
end
function GlyphData:getHeight()
   return rawget(self, "_height")
end
function GlyphData:getWidth()
   return rawget(self, "_width")
end
function GlyphData:_getImageData()
   return rawget(self, "_imagedata")
end
function GlyphData:_getImage()
   return rawget(self, "_image")
end
function GlyphData:_new(id, xoff, yoff, adv, w, h, imgd, img)
   if img == nil and imgd ~= nil then
      img = Image:_new("2d", imgd)
   end
   local n = {
      _id = id,
      _xoffset = xoff,
      _yoffset = yoff,
      _advance = adv,
      _width = w,
      _height = h,
      _imagedata = imgd,
      _image = img,
   }
   for i, v in next, self do
      n[i] = v
   end
   return n
end
return GlyphData
