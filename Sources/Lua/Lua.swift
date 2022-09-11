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
    private let managed: Bool
    /**
     - description: Creates a new Lua state. It calls lua_newstate with an allocator based on the standard C allocation functions and then sets a warning function and a panic function (see §4.4) that print messages to the standard error output.
     - returns:Returns the new state, or NULL if there is a memory allocation error.
     **/
    public convenience init?() {
        guard let state = luaL_newstate() else {return nil}
        self.init(managedState: state)
    }
    
    public convenience init?(_ f: @escaping Alloc, _ ud: UnsafeMutableRawPointer!) {
        guard let state = lua_newstate(f, ud) else {return nil}
        self.init(managedState: state)
    }
    
    @usableFromInline
    internal init(managedState state: OpaquePointer) {
        self.state = state
        managed = true
    }
    
    /// Use this in CFunctions to gain access `let lua = Lua(state)`
    public init(existingState state: OpaquePointer) {
        self.state = state
        managed = false
    }
    
    deinit {
        if managed {
            self.close()
        }
    }
}

extension Lua: Equatable {
    public static func ==(lhs: Lua, rhs: Lua) -> Bool {
        return lhs.state == rhs.state
    }
}
