/**
 * Copyright © 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
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
    public convenience init?() {
        guard let luaC = LuaC() else {return nil}
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

public extension Lua {
    func execute(_ script: LuaC.Source, after customize: (_ lua: Lua) throws -> Void) throws {
        // Cleanup in case we're being reused
        var status = luaC.reset()
        if status != .ok {
            throw status
        }
        cleanupCFunctions()
        
        // Open stdlibs
        luaC.openlibs()
        
        // Call customization closure
        weak var weakSelf: Lua? = self
        try customize(weakSelf!)
        
        // Run the script
        status = luaC.doScript(source: script)
        if status != .ok {
            throw status
        }
    }
}

public extension Lua {
    fileprivate static var cFunctionMap: [OpaquePointer:[String:((Lua)->[LuaValueType])]] = [:]
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
    func setFunction(_ function: @escaping (_ lua: Lua)->[LuaValueType], withScriptName name: String) {
        self.luaC.pushString(name)
        self.luaC.pushCClosure(luaCFunction(luaState:), 1)
        self.luaC.setGloabal(named: name)
        
        var funcDatabase = Self.cFunctionMap[luaC.state] ?? [:]
        funcDatabase[name] = function
        Self.cFunctionMap[luaC.state] = funcDatabase
    }
}

fileprivate func luaCFunction(luaState: OpaquePointer!) -> Int32 {
    let luaC = LuaC(existingState: luaState)
    let functionName = luaC.toString(at: LuaC.upValueIndex(1))!
    let funcDatabase = Lua.cFunctionMap[luaState]!
    let returnValues = funcDatabase[functionName]!(Lua(luaC))
    
    luaC.pop(luaC.getTop())
    
    for value in returnValues {
        switch value {
        case let value as String:
            luaC.pushString(value)
        case let value as Double:
            luaC.pushNumber(value)
        case let value as Float:
            luaC.pushNumber(LuaC.Number(value))
        case let value as Int:
            luaC.pushInteger(LuaC.Integer(value))
        case let value as Bool:
            luaC.pushBoolean(value)
        default:
            fatalError("Unhandled type.")
        }
    }
    
    return Int32(returnValues.count)
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
public protocol LuaNonNumericValueType {}
extension Float: LuaValueType {}
extension Double: LuaValueType {}
extension Int: LuaValueType {}
extension Bool: LuaValueType, LuaNonNumericValueType {}
extension String: LuaValueType, LuaNonNumericValueType {}
