// swift-tools-version: 5.4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var cSettings: [CSetting] {
    var array: [CSetting] = []
    
    array.append(.define("LUA_USE_APICHECK", .when(configuration: .debug)))
    
    // Windows
    array.append(.define("LUA_USE_WINDOWS", .when(platforms: [.windows])))
    
    // Linux
    array.append(.define("LUA_USE_LINUX", .when(platforms: [.linux])))
    
    // macOS
    array.append(.define("LUA_USE_MACOSX", .when(platforms: [.macOS])))
    
    return array
}

var sources: [String] {
    var array: [String] = []
    
    let core = ["lapi.c", "lcode.c", "lctype.c", "ldebug.c", "ldo.c", "ldump.c", "lfunc.c", "lgc.c", "llex.c", "lmem.c", "lobject.c", "lopcodes.c", "lparser.c", "lstate.c", "lstring.c", "ltable.c", "ltm.c", "lundump.c", "lvm.c", "lzio.c"]
    array.append(contentsOf: core.map({"src/" + $0}))

    let lib = ["lauxlib.c", "lbaselib.c", "lcorolib.c", "ldblib.c", "liolib.c", "lmathlib.c", "loadlib.c", "loslib.c", "lstrlib.c", "ltablib.c", "lutf8lib.c", "linit.c"]
    array.append(contentsOf: lib.map({"src/" + $0}))

    return array
}

var exclude: [String] {
    var array: [String] = []
    
    let files = ["Makefile", "lua.c", "luac.c"]
    array.append(contentsOf: files.map({"src/" + $0}))

    return array
}

let package = Package(
    name: "Lua",
    products: [
        .library(name: "Lua", targets: ["Lua"]),
    ],
    targets: [
        .target(name: "Lua", dependencies: ["_LuaC"]),
        .target(name: "_LuaC",
                exclude: exclude,
                sources: sources,
                publicHeadersPath: "Include",
                cSettings: cSettings),
    ],
    cLanguageStandard: .gnu99
)