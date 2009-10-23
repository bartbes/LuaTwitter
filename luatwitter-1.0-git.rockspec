package = "LuaTwitter"
version = "1.0-git"
source = {
    url = "git://github.com/bartbes/LuaTwitter.git"
}
description = {
    summary = "A twitter library for Lua",
    detailed = [[
        LuaTwitter is an extensive twitter library
        for Lua that provides wrappers for many
        twitter API functions.
    ]],
    homepage = "http://github.com/bartbes/LuaTwitter",
    license = "MIT"
}
dependencies = {
    "lua >= 5.1",
    "luasocket >= 2.0",
    "json4lua >= 0.9.2"
}
build = {
    type = "none",
    install = { lua = {
        twitter = "lua/twitter.lua"
    }}
}
