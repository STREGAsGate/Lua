/**
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import _LuaC

@_exported import struct _LuaC.lua_Debug

public final class LuaC {
    public let state: OpaquePointer
    public enum Source {
        case string(_ string: String)
        case file(path: String)
    }

    /// True if this object contains the original state pointer.
    public let isManaged: Bool
    /**
     - description: Creates a new Lua state. It calls lua_newstate with an allocator based on the standard C allocation functions and then sets a warning function and a panic function (see §4.4) that print messages to the standard error output.
     - returns:Returns the new state, or NULL if there is a memory allocation error.
     **/
    public convenience init?() {
        guard let state = luaL_newstate() else {return nil}
        self.init(managedState: state)
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
    
    public func doScript(source: Source) -> ThreadStatus {
        switch source {
        case let .file(path):
            return doFile(path)
        case let .string(string):
            return doString(string)
        }
    }
    
    deinit {
        if isManaged {
            self.close()
        }
    }
}
