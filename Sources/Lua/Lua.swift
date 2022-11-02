/**
 * Copyright (c) 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import LuaC

public final class Lua {
    @usableFromInline let state: OpaquePointer
    public private(set) lazy var stack: Stack = Stack(lua: self)

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
        self.managed = true
    }
    
    /// Use this in CFunctions to gain access `let lua = Lua(state)`
    public init(existingState state: OpaquePointer) {
        self.state = state
        self.managed = false
    }
    
    deinit {
        if managed {
            self.close()
        }
    }
}

extension Lua {
    public struct Stack {
        let lua: Lua
        

    }
}

public extension Lua.Stack {
    var top: Int32 {
        get {
            return lua_gettop(lua.state)
        }
        set {
            lua_settop(lua.state, newValue)
        }
    }
    
}

extension Lua.Stack: CustomDebugStringConvertible {
    public var debugDescription: String {
        var string: String = "Lua Stack (\(top)):"
        if top > 0 {
            for index in (1 ... top).reversed() {
                let type = lua.type(at: index)
                string += "\n          \(index)\t\(type)"
            }
        }
        return string
    }
}

extension Lua: Equatable {
    public static func ==(lhs: Lua, rhs: Lua) -> Bool {
        return lhs.state == rhs.state
    }
}

extension Lua: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(state)
    }
}
