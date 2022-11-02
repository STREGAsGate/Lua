/**
 * Copyright (c) 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import LuaC

public extension Lua {
    /// Opens all standard Lua libraries into the given state.
    @inline(__always)
    func openlibs() {
        luaL_openlibs(state)
    }
}
