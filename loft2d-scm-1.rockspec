package = "loft2d"
version = "scm-1"
source = {
   url = "https://github.com/bainchild/loft2d.git"
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
      ["loft.nogame"] = "loft.nogame.lua"
   }
}
