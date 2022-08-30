/**
 * Copyright (c) 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import _LuaC

public class Lua {
    @usableFromInline let state: OpaquePointer
    
    /**
     - description: Creates a new Lua state. It calls lua_newstate with an allocator based on the standard C allocation functions and then sets a warning function and a panic function (see §4.4) that print messages to the standard error output.
     - returns:Returns the new state, or NULL if there is a memory allocation error.
     **/
    public convenience init?() {
        guard let state = luaL_newstate() else {return nil}
        self.init(state)
    }
    
    public convenience init?(_ f: @escaping Alloc, _ ud: UnsafeMutableRawPointer!) {
        guard let state = lua_newstate(f, ud) else {return nil}
        self.init(state)
    }
    
    @usableFromInline
    internal init(_ state: OpaquePointer) {
        self.state = state
    }
    
    deinit {
        self.close()
    }
}
