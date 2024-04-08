package = "loft-keyboard-lcurses"
version = "scm-1"
source = {
   url = "git+https://github.com/bainchild/loft2d.git"
}
description = {
   summary = "lcurses keyboard input backend for LOFT2d",
   homepage = "https://github.com/bainchild/loft2d",
   license = "Unlicense"
}
build = {
   type = "builtin",
   modules = {
      ["loft-keyboard-lcurses"] = "init.lua"
   }
}
dependencies = {
   "lcurses >= 9.0.0"
}
