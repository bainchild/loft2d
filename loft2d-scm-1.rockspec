package = "loft2d"
version = "scm-1"
source = {
   url = "git://github.com/bainchild/loft2d"
}
description = {
   homepage = "https://github.com/bainchild/loft2d",
   license = "Unlicense"
}
build = {
   type = "builtin",
   modules = {
      loft = "loft.lua",
      ["loft.arg"] = "loft.arg.lua",
      ["loft.boot"] = "loft.boot.lua",
      ["loft.callbacks"] = "loft.callbacks.lua",
      ["loft.timer"] = "loft.timer.lua",
      ["loft.system"] = "loft.system.lua",
      ["loft.thread"] = "loft.thread.lua",
      ["loft.event"] = "loft.event.lua",
      ["loft.window"] = "loft.window.lua",
      ["loft.graphics"] = "loft.graphics.lua",
      ["loft.data"] = "loft.data/init.lua",
      ["loft.data.base64"] = "loft.data/base64.lua",
      ["loft.image"] = "loft.image/init.lua",
      ["loft.filesystem"] = "loft.filesystem/init.lua",
      ["loft.filesystem.vfs"] = "loft.filesystem/vfs.lua",
      ["loft.filesystem.stream"] = "loft.filesystem/stream.lua",
      ["loft._classes.Object"] = "_classes/Object.lua",
      ["loft._classes.Data"] = "_classes/Data.lua",
      ["loft._classes.Drawable"] = "_classes/Drawable.lua",
      ["loft._classes.Texture"] = "_classes/Texture.lua",
      ["loft._classes.Image"] = "_classes/Image.lua",
      ["loft._classes.Canvas"] = "_classes/Canvas.lua",
      ["loft._classes.ByteData"] = "_classes/ByteData.lua",
      ["loft._classes.ImageData"] = "_classes/ImageData.lua",
      ["loft._classes.FileData"] = "_classes/FileData.lua",
      ["loft._formats.png"] = "_formats/png.lua",
      ["loft._formats.pngencoder"] = "_formats/pngencoder.lua",
      ["loft._formats.pnglua"] = "_formats/pnglua.lua",
      ["loft.nogame"] = "loft.nogame.lua"
   }
}
