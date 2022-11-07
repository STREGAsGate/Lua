/**
 * Copyright (c) 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import _LuaC

public extension LuaC {
    /// Opens all standard Lua libraries into the given state.
    @inline(__always)
    func openlibs() {
        luaL_openlibs(state)
    }
}
