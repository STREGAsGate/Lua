/**
 * Copyright (c) 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import LuaC

public final class Lua {
    public let luaC: LuaC
    
    /**
     - description: Creates a new Lua state. It calls lua_newstate with an allocator based on the standard C allocation functions and then sets a warning function and a panic function (see §4.4) that print messages to the standard error output.
     - returns:Returns the new state, or NULL if there is a memory allocation error.
     **/
    public convenience init?(_ path: String) {
        guard let luaC = LuaC(path) else {return nil}
        self.init(luaC)
    }
    
    internal init(_ luaC: LuaC) {
        self.luaC = luaC
    }
    
    deinit {
        if luaC.isManaged {
            self.cleanupCFunctions()
        }
    }
}

#if canImport(Foundation)
import Foundation
public extension Lua {
    convenience init?(_ url: URL) {
        self.init(url.path)
    }
}
#endif

public extension Lua {
    func runScript() throws {
        luaC.openlibs()
        let status = luaC.pcall(0, LuaC.multipleReturns, 0)
        if status != .ok {
            throw status
        }
    }
}

public extension Lua {
    fileprivate static var cFunctionMap: [OpaquePointer:[String:((Lua)->Int)]] = [:]
    fileprivate func cleanupCFunctions() {
        Self.cFunctionMap[luaC.state] = nil
    }
    
    /**
        Sets a Swift function that is called when Lua encounters a script function of the given name.
        - parameter function: A Swift function to call when Lua encounters a function named `name`.
                              This function returns the count of arguments pushed onto the Lua stack.
                              The pushed values are the values that will be returned by the Lua script's function call.
        - parameter name: The name of a function you intend to write in the Lua script.
     */
    func setFunction(_ function: @escaping (_ lua: Lua)->Int, withScriptName name: String) {
        self.luaC.register(function: luaCFunction(luaState:), named: name)
        var funcDatabase = Self.cFunctionMap[luaC.state] ?? [:]
        funcDatabase[name] = function
        Self.cFunctionMap[luaC.state] = funcDatabase
    }
}

fileprivate func luaCFunction(luaState: OpaquePointer!) -> Int32 {
    let luaC = LuaC(existingState: luaState)

    @inline(__always)
    func currentFunctionName(luaC: LuaC) -> String? {
        luaC.traceback(luaC.state, nil, 0)
        guard var traceback = luaC.toString(at: 1) else {return nil}
        luaC.pop(1)
        
        guard let index1 = traceback.firstIndex(where: {$0 == "\'"}) else {return nil}
        traceback.removeSubrange(...index1)
        guard let index2 = traceback.firstIndex(where: {$0 == "\'"}) else {return nil}
        traceback.removeSubrange(index2...)
        guard traceback.isEmpty == false else {return nil}
        return traceback
    }
    
    guard let functionName = currentFunctionName(luaC: luaC) else {
        fatalError("Failed to get a function name. Lua for Swift uses the function name as a look up.")
    }
    let funcDatabase = Lua.cFunctionMap[luaState]!
    let args = funcDatabase[functionName]!(Lua(luaC))
    return Int32(args)
}

extension Lua: Equatable {
    public static func ==(lhs: Lua, rhs: Lua) -> Bool {
        return lhs.luaC.state == rhs.luaC.state
    }
}

extension Lua: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(luaC.state)
    }
}

public protocol LuaValueType {}
extension Float: LuaValueType {}
extension Double: LuaValueType {}
extension Int: LuaValueType {}
extension Bool: LuaValueType {}
extension String: LuaValueType {}
