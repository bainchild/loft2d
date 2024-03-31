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
      ["loft.data"] = "loft.data.lua",
      ["loft.thread"] = "loft.thread.lua",
      ["loft.event"] = "loft.event.lua",
      ["loft.filesystem"] = "loft.filesystem/init.lua",
      ["loft.filesystem.vfs"] = "loft.filesystem/vfs.lua",
      ["loft.filesystem.stream"] = "loft.filesystem/stream.lua",
      ["loft.window"] = "graphics_subsys/loft.window.lua",
      ["loft.graphics"] = "graphics_subsys/loft.graphics.lua",
      ["loft._classes.Object"] = "_classes/Object.lua",
      ["loft._classes.Data"] = "_classes/Data.lua",
      ["loft._classes.ByteData"] = "_classes/ByteData.lua",
      ["loft._classes.Canvas"] = "_classes/Canvas.lua",
      ["loft._classes.Drawable"] = "_classes/Drawable.lua",
      ["loft._classes.FileData"] = "_classes/FileData.lua",
      ["loft._classes.Texture"] = "_classes/Texture.lua",
      ["loft.nogame"] = "loft.nogame.lua"
   }
}
