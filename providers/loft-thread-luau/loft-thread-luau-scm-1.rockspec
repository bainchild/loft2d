package = "loft-thread-luau"
version = "scm-1"
source = {
   url = "git+https://github.com/bainchild/loft2d.git"
}
description = {
   summary = "Luau thread backend for LOFT2d",
   homepage = "https://github.com/bainchild/loft2d",
   license = "Unlicense"
}
build = {
   type = "builtin",
   modules = {
      ["loft-thread-luau"] = "init.lua"
   }
}
