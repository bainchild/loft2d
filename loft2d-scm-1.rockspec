package = "loft2d"
version = "scm-1"
source = {
   url = "git://github.com/bainchild/loft2d"
}
description = {
   homepage = "https://github.com/bainchild/loft2d",
   license = "Unlicense"
}
dependencies = {
   "utf8 >= 1.2-0",
--   "lua_signal >= 1.2.0-1"
}
build = {
   type = "builtin",
   modules = {
      loft = "loft.lua",
      ["loft._logging"] = "logging.lua",
      ["loft._ansicolors"] = "ansicolors.lua",
      ["loft._input"] = "loft.input.lua",
      ["loft._flags"] = "flags.lua",
      ["loft.arg"] = "loft.arg.lua",
      ["loft.boot"] = "loft.boot.lua",
      ["loft.callbacks"] = "loft.callbacks.lua",
      ["loft.timer"] = "loft.timer.lua",
      ["loft.system"] = "loft.system.lua",
      ["loft.thread"] = "loft.thread.lua",
      ["loft.event"] = "loft.event.lua",
      ["loft.mouse"] = "loft.mouse.lua",
      ["loft.window"] = "loft.window.lua",
      ["loft.graphics"] = "loft.graphics.lua",
      ["loft.data"] = "loft.data/init.lua",
      ["loft.data.base64"] = "loft.data/base64.lua",
      ["loft.image"] = "loft.image/init.lua",
      ["loft.font"] = "loft.font/init.lua",
      ["loft._formats.png"] = "loft.image/png.lua",
      ["loft._formats.pngencoder"] = "loft.image/pngencoder.lua",
      ["loft._formats.pnglua"] = "loft.image/pnglua.lua",
      ["loft.filesystem"] = "loft.filesystem/init.lua",
      ["loft.filesystem.vfs"] = "loft.filesystem/vfs.lua",
      ["loft.filesystem.rfs"] = "loft.filesystem/rfs.lua",
      ["loft.filesystem.stream"] = "loft.filesystem/stream.lua",
      ["loft._classes.Object"] = "_classes/Object.lua",
      ["loft._classes.Cursor"] = "_classes/Cursor.lua",
      ["loft._classes.Data"] = "_classes/Data.lua",
      ["loft._classes.Drawable"] = "_classes/Drawable.lua",
      ["loft._classes.Font"] = "_classes/Font.lua",
      ["loft._classes.File"] = "_classes/File.lua",
      ["loft._classes.GlyphData"] = "_classes/GlyphData.lua",
      ["loft._classes.Texture"] = "_classes/Texture.lua",
      ["loft._classes.Image"] = "_classes/Image.lua",
      ["loft._classes.Canvas"] = "_classes/Canvas.lua",
      ["loft._classes.ByteData"] = "_classes/ByteData.lua",
      ["loft._classes.ImageData"] = "_classes/ImageData.lua",
      ["loft._classes.FileData"] = "_classes/FileData.lua",
      ["loft.nogame"] = "loft.nogame.lua",

      ["loft._font.Default"] = "fonts/BitstreamVeraSans.lua",
      ["loft._font.DefaultBold"] = "fonts/BitstreamVeraSansBold.lua",
      ["loft._font.DefaultItalic"] = "fonts/BitstreamVeraSansItalic.lua",
      ["loft._font.DefaultBoldItalic"] = "fonts/BitstreamVeraSansBoldItalic.lua",
            
      ["loft._font.BitstreamVeraSansMono"] = "fonts/BitstreamVeraSansMono.lua",
      ["loft._font.BitstreamVeraSansMonoBold"] = "fonts/BitstreamVeraSansMonoBold.lua",
      ["loft._font.BitstreamVeraSansMonoItalic"] = "fonts/BitstreamVeraSansMonoItalic.lua",
      ["loft._font.BitstreamVeraSansMonoBoldItalic"] = "fonts/BitstreamVeraSansMonoBoldItalic.lua",
   },
   install = {
      bin = {
         ["loft"] = "loft-cli.lua"
      }
   }
}
