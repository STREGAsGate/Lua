// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var libraryType: Product.Library.LibraryType? = nil
#if os(Windows)
libraryType = .dynamic
#endif

var cSettings: [CSetting] {
    return [
        .define("LUA_USE_APICHECK", .when(configuration: .debug)),
        
        // Flags
        //.unsafeFlags(["-Wall", "-fno-stack-protector", "-fno-common"]),
        //.unsafeFlags(["-O2"], .when(configuration: .release)),
        
        // Windows
        .define("LUA_BUILD_AS_DLL", .when(platforms: [.windows])),
        
        // Linux
        .define("LUA_USE_LINUX", .when(platforms: [.linux])),
        .define("LUA_USE_READLINE", .when(platforms: [.linux])),
        
        // macOS
        .define("LUA_USE_MACOSX", .when(platforms: [.macOS])),
        .define("LUA_USE_READLINE", .when(platforms: [.macOS])),
        
        // iOS
        .define("LUA_USE_POSIX", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
        .define("LUA_USE_DLOPEN", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
        .define("LUA_USE_READLINE", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
    ]
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
    let files = ["Makefile", "lua.c", "luac.c"]
    return files.map({"src/" + $0})
}

var cLanguageStandard: CLanguageStandard {
    #if os(Windows)
    return .c89
    #else
    return .c99
    #endif
}

let package = Package(
    name: "Lua",
    products: [
        .library(name: "Lua", type: libraryType, targets: ["Lua"]),
        .library(name: "LuaC", type: libraryType, targets: ["LuaC"]),
    ],
    targets: [
        .target(name: "LuaC",
                exclude: exclude,
                sources: sources,
                publicHeadersPath: "Include",
                cSettings: cSettings),
        .target(name: "Lua", dependencies: ["LuaC"]),
    ],
    cLanguageStandard: cLanguageStandard
)
