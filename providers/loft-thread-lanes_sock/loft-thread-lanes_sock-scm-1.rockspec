package = "loft-thread-lanes_sock"
version = "scm-1"
source = {
   url = "git+https://github.com/bainchild/loft2d.git"
}
description = {
   summary = "Lua lanes + luasocket thread backend for LOFT2d",
   homepage = "https://github.com/bainchild/loft2d/providers",
   license = "Unlicense"
}
dependencies = {
   "lanes >= 3.16.2-0",
   "luasocket >= 3.0rc1-2"
}
build = {
   type = "builtin",
   modules = {
      ["loft-thread-lanes_sock"] = "init.lua"
   }
}
