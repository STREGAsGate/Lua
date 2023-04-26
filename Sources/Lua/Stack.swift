/**
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import LuaC
import Foundation

public extension Lua {
    typealias LuaType = LuaC.BasicType
    
    typealias Integer = LuaC.Integer
    typealias UnsignedInteger = LuaC.UnsignedInteger
    typealias Number = LuaC.Number
}

public extension Lua {
    /**
     Removes values from the top of the stack.
     - parameter count: The number of values to remove from the top of the stack.
     */
    func pop(_ count: Int = 1) {
        luaC.pop(Int32(count))
    }
    
    /**
     Copies the element at index fromidx into the valid index toidx, replacing the value at that position. Values at other positions are not affected.
     - parameter from: The source stack index.
     - parameter to: The destination stack index.
     */
    func copy(from source: Int, to destination: Int) {
        luaC.copy(from: Int32(source), to: Int32(destination))
    }
}

public extension Lua {
    /**
     Places `value` on the top of the stack.
     - parameter value: The value to add to the stack
     - returns: A pointer to the string in the stack
     */
    @discardableResult
    func push(_ value: String) -> UnsafePointer<CChar> {
        luaC.pushString(value)
    }
    
    /**
     Places `value` on the top of the stack.
     - parameter value: The value to add to the stack
     */
    func push<T:BinaryFloatingPoint>(_ value: T) {
        return luaC.pushNumber(LuaC.Number(value))
    }
    
    /**
     Places `value` on the top of the stack.
     - parameter value: The value to add to the stack
     */
    func push<T:BinaryInteger>(_ value: T) {
        return luaC.pushInteger(LuaC.Integer(value))
    }
    
    /**
     Places `value` on the top of the stack.
     - parameter value: The value to add to the stack
     */
    func push(_ value: Bool) {
        return luaC.pushBoolean(value)
    }
    
    /**
     Places `value` on the top of the stack.
     - parameter value: The value to add to the stack
     */
    func pushNil() {
        return luaC.pushNil()
    }
    
    /**
     Returns the value at stack index `index` as a String.
     - parameter index The stack position of the desired value.
     - note Does not pop the value off of the stack.
     */
    func getString(at index: Int) -> String? {
        if let value = luaC.toString(at: Int32(index)) {
            return value
        }
        return nil
    }
    
    /**
     Returns the value at stack index `index` as a Double.
     - parameter index: The stack position of the desired value.
     - note: Does not pop the value off of the stack.
     */
    func getDouble(at index: Int) -> Double? {
        if let value = luaC.toNumber(at: Int32(index)) {
            return value
        }
        return nil
    }
    
    /**
     Returns the value at stack index `index` as a Float.
     - parameter index: The stack position of the desired value.
     - note: Does not pop the value off of the stack.
     */
    func getFloat(at index: Int) -> Float? {
        if let value = luaC.toNumber(at: Int32(index)) {
            return Float(value)
        }
        return nil
    }
    
    /**
     Returns the value at stack index `index` as a Int.
     - parameter index: The stack position of the desired value.
     - note: Does not pop the value off of the stack.
     */
    func getInt(at index: Int) -> Int? {
        if let value = luaC.toInteger(at: Int32(index)) {
            return Int(value)
        }
        return nil
    }
    
    /**
     Returns the value at stack index `index` as a Int.
     - parameter index: The stack position of the desired value.
     - note: Does not pop the value off of the stack.
     */
    func getBool(at index: Int) -> Bool {
        return luaC.toBoolean(at: Int32(index))
    }
}

public extension Lua {
    class FunctionReference {
        let lua: Lua
        let reference: Int32
        public func runScript(withArguments args: LuaValueType...) {
            let type = lua.luaC.rawGetI(at: LuaC.registryIndex, number: LuaC.Integer(reference))
            assert(type == .function)
            for value in args {
                switch value {
                case let value as String:
                    lua.push(value)
                case let value as Double:
                    lua.push(value)
                case let value as Float:
                    lua.push(value)
                case let value as Int:
                    lua.push(value)
                case let value as Bool:
                    lua.push(value)
                default:
                    fatalError("Unhandled type.")
                }
            }
            lua.luaC.call(Int32(args.count), 0)
        }
        internal init(lua: Lua, reference: Int32) {
            self.lua = lua
            self.reference = reference
        }
        deinit {
            lua.luaC.unref(LuaC.registryIndex, reference)
        }
    }
    
    func getFunction(at index: Int) -> FunctionReference? {
        // add garbage data
        pushNil()
        // Replace garbage with func
        copy(from: index, to: self.top)
        if typeOfValue(at: self.top) != .function {
            // Remove the added entry
            pop()
            return nil
        }
        // Pop func and create reference
        let reference = luaC.ref(LuaC.registryIndex)
        return FunctionReference(lua: self, reference: reference)
    }
}

public extension Lua {
    struct Table {
        public let lua: Lua
        public let tableIndex: Int32
        
        /** True if the stack index used to create this `Table` is still a Lua table.
         - note: There is no check for the table being a different table.
         */
        public var isValid: Bool {
            return lua.typeOfValue(at: Int(tableIndex)) == .table
        }
        
        internal init(lua: Lua, tableIndex: Int32) {
            self.lua = lua
            self.tableIndex = tableIndex
        }
        
        /// The number of elements in the table
        public var count: Int {
            return Int(lua.luaC.rawLen(at: tableIndex))
        }
        
        /// Returns all values representable by (Bool, Double, or String) in the table.
        var values: [LuaValueType] {
            var array: [LuaValueType] = []
            for index in 1...count {
                let type = lua.luaC.rawGetI(at: -1, number: Lua.Integer(index))
                var value: LuaValueType? = nil
                switch type {
                case .boolean:
                    value = lua.luaC.toBoolean(at: -1)
                case .number:
                    value = lua.luaC.toNumber(at: -1)
                case .string:
                    value = lua.luaC.toString(at: -1)
                case .table, .userData, .lightUserData:
                    break
                case .thread, .function:
                    break
                case .none, .nil, .numTypes:
                    break
                }
                if let value = value {
                    array.append(value)
                }
                lua.pop(1)
            }
            return array
        }
        
        @inline(__always)
        private var valuesAsStrings: [String] {
            var array: [String] = []
            for index in 1...Lua.Integer(count) {
                lua.luaC.rawGetI(at: -1, number: index)
                if let value = lua.luaC.toString(at: -1) {
                    array.append(value)
                }
                lua.pop()
            }
            return array
        }
        
        @inline(__always)
        private var valuesAsNumbers: [Lua.Number] {
            var array: [Lua.Number] = []
            for index in 1...Lua.Integer(count) {
                lua.luaC.rawGetI(at: -1, number: index)
                if let value = lua.luaC.toNumber(at: -1) {
                    array.append(value)
                }
                lua.pop()
            }
            return array
        }
        
        @inline(__always)
        private var valuesAsBooleans: [Bool] {
            var array: [Bool] = []
            for index in 1...Lua.Integer(count) {
                lua.luaC.rawGetI(at: -1, number: index)
                let value = lua.luaC.toBoolean(at: -1)
                array.append(value)
                
                lua.pop()
            }
            return array
        }
        
        public func values<T:LuaNonNumericValueType>(as type: T.Type) -> [T] {
            switch type {
            case _ as String.Type:
                return valuesAsStrings as! [T]
            case _ as Bool.Type:
                return valuesAsBooleans as! [T]
            default:
                fatalError("Type \(type) not implimented.")
            }
        }
        
        public func values<T:BinaryInteger & FixedWidthInteger>(as type: T.Type) -> [T] {
            return valuesAsStrings.compactMap { T($0) }
        }
        
        public func values<T:BinaryFloatingPoint>(as type: T.Type) -> [T] {
            return valuesAsNumbers.map({T($0)}) as! [T]
        }
    }
    
    /**
     Provides access to a table on the stack.
     - parameter index: The stack position of the desired value.
     - parameter tableAccess: A closure that provides access to the table. The table is only valid within this block. The table may become invalid if the stack is manipulated, such as it's index is popped.
     */
    func getTable<ReturnValue>(at tableIndex: Int, tableAccess: (_ table: Table) -> ReturnValue) -> ReturnValue {
        assert(typeOfValue(at: tableIndex) == .table)
        let table = Table(lua: self, tableIndex: Int32(tableIndex))
        return tableAccess(table)
    }
}

public extension Lua.Table {
    /**
     Returns the value at stack index `index` as a String.
     - parameter index The stack position of the desired value.
     - note Does not pop the value off of the stack.
     */
    func getString(forKey key: String) -> String? {
        assert(self.isValid, "A table is no longer located at stack index \(tableIndex).")
        guard lua.luaC.getField(at: tableIndex, key) == .string else {return nil}
        let value = lua.luaC.toString(at: -1)
        lua.pop()
        return value
    }
    
    /**
     Returns the value at stack index `index` as a Double.
     - parameter index The stack position of the desired value.
     - note Does not pop the value off of the stack.
     */
    func getDouble(forKey key: String) -> Double? {
        assert(self.isValid, "A table is no longer located at stack index \(tableIndex).")
        guard lua.luaC.getField(at: tableIndex, key) == .number else {return nil}
        let value = lua.luaC.toNumber(at: -1)
        lua.pop()
        if let value = value {
            return Double(value)
        }
        return nil
    }
    
    /**
     Returns the value at stack index `index` as a Float.
     - parameter index The stack position of the desired value.
     - note Does not pop the value off of the stack.
     */
    func getFloat(forKey key: String) -> Float? {
        assert(self.isValid, "A table is no longer located at stack index \(tableIndex).")
        guard lua.luaC.getField(at: tableIndex, key) == .number else {return nil}
        let value = lua.luaC.toNumber(at: -1)
        lua.pop()
        if let value = value {
            return Float(value)
        }
        return nil
    }
    
    /**
     Returns the value for `key` as a Int.
     - parameter key: The table name of the desired value.
     */
    func getInt(forKey key: String) -> Int? {
        assert(self.isValid, "A table is no longer located at stack index \(tableIndex).")
        guard lua.luaC.getField(at: tableIndex, key) == .number else {return nil}
        let value = lua.luaC.toInteger(at: -1)
        lua.pop()
        if let value = value {
            return Int(value)
        }
        return nil
    }
    
    /**
     Returns the value at stack index `index` as a Int.
     - parameter index: The stack position of the desired value.
     - note: Does not pop the value off of the stack.
     */
    func getBool(forKey key: String) -> Bool {
        assert(self.isValid, "A table is no longer located at stack index \(tableIndex).")
        guard lua.luaC.getField(at: tableIndex, key) == .boolean else {return false}
        let value = lua.luaC.toBoolean(at: -1)
        lua.pop()
        return value
    }
    
    /**
     Returns the value at stack index `index` as a Int.
     - parameter index The stack position of the desired value.
     - note Pushes a value onto the stack. You must pop the value when you are done with the table.
     */
    func getTable<ReturnValue>(forKey key: String, block: (_ table: Lua.Table) -> ReturnValue) -> ReturnValue? {
        assert(self.isValid, "A table is no longer located at stack index \(tableIndex).")
        let type = lua.luaC.getField(at: tableIndex, key)
        if type == .table {
            assert(type == .table)
            let table = Self(lua: lua, tableIndex: Int32(lua.top))
            let value = block(table)
            lua.pop()
            return value
        }else{
            lua.pop()
            return nil
        }
    }
    
    func getFunction(forKey key: String) -> Lua.FunctionReference? {
        let type = lua.luaC.getField(at: tableIndex, key)
        if type != .function {
            lua.pop()
            return nil
        }
        
        let ref = lua.luaC.ref(LuaC.registryIndex)
        if ref == LuaC.refNil || ref == LuaC.noRef {
            return nil
        }
        
        return Lua.FunctionReference(lua: lua, reference: ref)
    }
}

public extension Lua {
    /**
     Returns the type of value at stack index `index`.
     - parameter index The stack position of the desired value type.
     */
    func typeOfValue(at index: Int) -> Lua.LuaType {
        return luaC.type(at: Int32(index))
    }
}

public extension Lua {
    /**
     Returns the index of the top element in the stack.
     - note: Because indices start at 1, this result is equal to the number of elements in the stack; in particular, 0 means an empty stack.
     */
    var top: Int {
        get {
            return Int(luaC.getTop())
        }
        set {
            luaC.setTop(Int32(newValue))
        }
    }
    
    /**
     Returns an array of all value types on the stack.
     */
    var types: [Lua.LuaType] {
        var types: [Lua.LuaType] = []
        if top > 0 {
            types.reserveCapacity(Int(top))
            for index in (1 ... top).reversed() {
                let type = typeOfValue(at: index)
                types.append(type)
            }
        }
        return types
    }
    
    var debugDescription: String {
        var string: String = "Lua Stack (\(top)):"
        if top > 0 {
            for index in (1 ... top).reversed() {
                let type = luaC.type(at: Int32(index))
                string += "\n          \(index)\t\(type)"
            }
        }
        return string
    }
}
