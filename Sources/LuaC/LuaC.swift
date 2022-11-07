//
//  File.swift
//  
//
//  Created by Dustin Collins on 11/7/22.
//

import _LuaC

public final class LuaC {
    public let state: OpaquePointer

    /// True if this object contains the original state pointer.
    public let isManaged: Bool
    /**
     - description: Creates a new Lua state. It calls lua_newstate with an allocator based on the standard C allocation functions and then sets a warning function and a panic function (see §4.4) that print messages to the standard error output.
     - returns:Returns the new state, or NULL if there is a memory allocation error.
     **/
    public convenience init?(_ path: String) {
        guard let state = luaL_newstate() else {return nil}
        self.init(managedState: state)
        if loadFile(path) != .ok {
            return nil
        }
    }
    
    public init(managedState state: OpaquePointer) {
        self.state = state
        self.isManaged = true
    }
    
    /// Use this in CFunctions to gain access `let lua = Lua(state)`
    public init(existingState state: OpaquePointer) {
        self.state = state
        self.isManaged = false
    }
    
    deinit {
        if isManaged {
            self.close()
        }
    }
}
