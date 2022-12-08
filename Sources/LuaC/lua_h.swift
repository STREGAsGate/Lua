/**
 * Copyright © 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import _LuaC

public extension LuaC {
    @inline(__always)
    static var versionMajor: String {LUA_VERSION_MAJOR}
    @inline(__always)
    static var versionMinor: String {LUA_VERSION_MINOR}
    @inline(__always)
    static var versionRelease: String {LUA_VERSION_RELEASE}
    
    @inline(__always)
    static var versionNum: Int32 {LUA_VERSION_NUM}
    @inline(__always)
    static var authors: String {LUA_AUTHORS}
}

public extension LuaC {
    /// mark for precompiled code ('<esc>Lua')
    @inline(__always)
    static var signature: String {LUA_SIGNATURE}
    
    /// option for multiple returns in 'lua_pcall' and 'lua_call'
    @inline(__always)
    static var multipleReturns: Int32 {LUA_MULTRET}
}

/*
 ** Pseudo-indices
 ** (-LUAI_MAXSTACK is the minimum valid index; we keep some free empty
 ** space after that to help overflow detection)
 */
public extension LuaC {
    @inline(__always)
    static let registryIndex: Int32 = -LUAI_MAXSTACK - 1000
    
    /// Returns the pseudo-index that represents the i-th upvalue of the running function (see §4.2). i must be in the range [1,256].
    @inline(__always)
    static func upValueIndex(_ i: Int32) -> Int32 {
        return LuaC.registryIndex - i
    }
}

/* thread status */
public extension LuaC {
    enum ThreadStatus: Int32, Error {
        case ok = 0
        case yield
        case errRun
        case errSyntax
        case errMem
        case errErr
        case errFile
    }
}

/*
 ** basic types
 */
public extension LuaC {
    enum BasicType: Int32 {
        case none = -1
        case `nil`
        case boolean
        case lightUserData
        case number
        case string
        case table
        case function
        case userData
        case thread
        case numTypes
    }
}

public extension LuaC {
    /// minimum Lua stack available to a C function
    @inline(__always)
    static var mainStack: Int32 {LUA_MINSTACK}
    
    /// predefined values in the registry
    @inline(__always)
    static var ridxMainThread: Int32 {LUA_RIDX_MAINTHREAD}
    @inline(__always)
    static var ridxGlobals: Int32 {LUA_RIDX_GLOBALS}
    @inline(__always)
    static var ridxLast: Int32 {LUA_RIDX_LAST}
}

public extension LuaC {
    /// type of numbers in Lua
    typealias Number = Double
    
    /// type for integer functions
    typealias Integer = Int64
    
    /// unsigned integer type
    typealias UnsignedInteger = UInt64
    
    /// type for continuation-function contexts
    typealias KContext = Int
    
    /// Type for C functions registered with Lua
    typealias CFunction = @convention(c) (OpaquePointer?) -> Int32
    
    /// Type for continuation functions
    typealias KFunction = @convention(c) (OpaquePointer?, Int32, KContext) -> Int32
    
    /// Type for functions that read/write blocks when loading/dumping Lua chunks
    typealias Reader = @convention(c) (OpaquePointer?, UnsafeMutableRawPointer?, UnsafeMutablePointer<Int>?) -> UnsafePointer<CChar>?
    
    typealias Writer = @convention(c) (OpaquePointer?, UnsafeRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32
    
    /// Type for memory-allocation functions
    typealias Alloc = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, Int, Int) -> UnsafeMutableRawPointer?
    
    /// Type for warning functions
    typealias WarnFunction = @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, Int32) -> Void
}
/*
 ** generic extra include file
 */

/*
 ** RCS ident string
 */

/*
 ** state manipulation
 */
public extension LuaC {
    /**
     Close all active to-be-closed variables in the main thread, release all objects in the given Lua state (calling the corresponding garbage-collection metamethods, if any), and frees all dynamic memory used by this state.
     
     - note: On several platforms, you may not need to call this function, because all resources are naturally released when the host program ends. On the other hand, long-running programs that create multiple states, such as daemons or web servers, will probably need to close states as soon as they are not needed.
     */
    @inline(__always)
    func close() {
        lua_close(state)
    }
    
    /**
     Creates a new thread, pushes it on the stack, and returns a pointer to a lua_State that represents this new thread. The new thread returned by this function shares with the original thread its global environment, but has an independent execution stack.
     
     - note: Threads are subject to garbage collection, like any Lua object.
     */
    @inline(__always)
    func newThread() -> LuaC? {
        if let state = lua_newthread(state) {
            return LuaC(managedState: state)
        }
        return nil
    }
    
    /**
     Resets a thread, cleaning its call stack and closing all pending to-be-closed variables. Returns a status code: LUA_OK for no errors in the thread (either the original error that stopped the thread or errors in closing methods), or an error status otherwise. In case of error, leaves the error object on the top of the stack.
     */
    @inline(__always)
    func reset() -> ThreadStatus {
        if let status = ThreadStatus(rawValue: lua_resetthread(state)) {
            return status
        }
        return .errErr
    }
    
    /// Sets a new panic function and returns the old one (see §4.4).
    @inline(__always)
    func atPanic(_ panicf: CFunction!) -> CFunction! {
        return lua_atpanic(state, panicf)
    }
    
    /// Returns the version number of this core.
    @inline(__always)
    var version: Number {lua_version(state)}
}
/*
 ** basic stack manipulation
 */
public extension LuaC {
    /// Converts the acceptable index idx into an equivalent absolute index (that is, one that does not depend on the stack size).
    @inline(__always)
    func absIndex(_ idx: Int32) -> Int32 {
        return lua_absindex(state, idx)
    }
    
    /// Returns the index of the top element in the stack. Because indices start at 1, this result is equal to the number of elements in the stack; in particular, 0 means an empty stack.
    @inline(__always)
    func getTop() -> Int32 {
        return lua_gettop(state)
    }
    
    /**
     Accepts any index, or 0, and sets the stack top to this index. If the new top is greater than the old one, then the new elements are filled with nil. If index is 0, then all stack elements are removed.
     
     - note: This function can run arbitrary code when removing an index marked as to-be-closed from the stack.
     */
    @inline(__always)
    func setTop(_ idx: Int32) {
        lua_settop(state, idx)
    }
    
    /// Pushes a copy of the element at the given index onto the stack.
    @inline(__always)
    func pushValue(_ idx: Int32) {
        lua_pushvalue(state, idx)
    }
    
    /**
     Rotates the stack elements between the valid index idx and the top of the stack. The elements are rotated n positions in the direction of the top, for a positive n, or -n positions in the direction of the bottom, for a negative n. The absolute value of n must not be greater than the size of the slice being rotated. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
     */
    @inline(__always)
    func rotate(idx: Int32, by n: Int32) {
        lua_rotate(state, idx, n)
    }
    
    /// Copies the element at index fromidx into the valid index toidx, replacing the value at that position. Values at other positions are not affected.
    @inline(__always)
    func copy(from fromidx: Int32, to toidx: Int32) {
        lua_copy(state, fromidx, toidx)
    }
    
    /**
     Ensures that the stack has space for at least n extra elements, that is, that you can safely push up to n values into it. It returns false if it cannot fulfill the request, either because it would cause the stack to be greater than a fixed maximum size (typically at least several thousand elements) or because it cannot allocate memory for the extra space. This function never shrinks the stack; if the stack already has space for the extra elements, it is left unchanged.
     */
    @inline(__always)
    func checkStack(count n: Int32) -> Bool {
        return lua_checkstack(state, n) != 0
    }
    
    /**
     Exchange values between different threads of the same state.
     
     - note: This function pops n values from the stack from, and pushes them onto the stack to.
     */
    @inline(__always)
    func xMove(from: LuaC, to: LuaC, count n: Int32) {
        lua_xmove(from.state, to.state, n)
    }
}

/*
 ** access functions (stack -> C)
 */
public extension LuaC {
    /// Returns 1 if the value at the given index is a number or a string convertible to a number, and 0 otherwise.
    @inline(__always)
    func isNumber(at idx: Int32) -> Bool {
        return lua_isnumber(state, idx) != 0
    }
    
    /// Returns 1 if the value at the given index is a string or a number (which is always convertible to a string), and 0 otherwise.
    @inline(__always)
    func isString(at idx: Int32) -> Bool {
        return lua_isstring(state, idx) != 0
    }
    
    /// Returns 1 if the value at the given index is a C function, and 0 otherwise.
    @inline(__always)
    func isCFunction(at idx: Int32) -> Bool {
        return lua_iscfunction(state, idx) != 0
    }
    
    /// Returns 1 if the value at the given index is an integer (that is, the value is a number and is represented as an integer), and 0 otherwise.
    @inline(__always)
    func isInteger(at idx: Int32) -> Bool {
        return lua_isinteger(state, idx) != 0
    }
    
    /// Returns 1 if the value at the given index is a userdata (either full or light), and 0 otherwise.
    @inline(__always)
    func isUserData(at idx: Int32) -> Bool {
        return lua_isuserdata(state, idx) != 0
    }
    
    /**
     Returns the type of the value in the given valid index, or LUA_TNONE for a non-valid but acceptable index. The types returned by lua_type are coded by the following constants defined in lua.h: LUA_TNIL, LUA_TNUMBER, LUA_TBOOLEAN, LUA_TSTRING, LUA_TTABLE, LUA_TFUNCTION, LUA_TUSERDATA, LUA_TTHREAD, and LUA_TLIGHTUSERDATA.
     */
    @inline(__always)
    func type(at idx: Int32) -> BasicType {
        if let basicType = BasicType(rawValue: lua_type(state, idx)) {
            return basicType
        }
        return .none
    }
    
    /// Returns the name of the type encoded by the value tp, which must be one the values returned by lua_type.
    @inline(__always)
    func typeName(_ tp: BasicType) -> String {
        guard let cString = lua_typename(state, tp.rawValue) else {return "Unknown"}
        return String(cString: cString)
    }
}

public extension LuaC {
    /**
     Converts the Lua value at the given index to the C type lua_Number (see lua_Number). The Lua value must be a number or a string convertible to a number (see §3.4.3); otherwise, lua_tonumberx returns 0.
     
     - note: If isnum is not NULL, its referent is assigned a boolean value that indicates whether the operation succeeded.
     */
    @inline(__always)
    func toNumber(at idx: Int32) -> Number? {
        var v: Int32 = 0
        let number = lua_tonumberx(state, idx, &v)
        if v != 0 {
            return number
        }
        return nil
    }
    
    /**
     Converts the Lua value at the given index to the signed integral type lua_Integer. The Lua value must be an integer, or a number or string convertible to an integer (see §3.4.3); otherwise, lua_tointegerx returns 0.
     
     - note: If isnum is not NULL, its referent is assigned a boolean value that indicates whether the operation succeeded.
     */
    @inline(__always)
    func toInteger(at idx: Int32) -> Integer? {
        var v: Int32 = 0
        let integer = lua_tointegerx(state, idx, &v)
        if v != 0 {
            return integer
        }
        return nil
    }
    
    /**
     Converts the Lua value at the given index to a C boolean value (0 or 1). Like all tests in Lua, lua_toboolean returns true for any Lua value different from false and nil; otherwise it returns false. (If you want to accept only actual boolean values, use lua_isboolean to test the value's type.)
     */
    @inline(__always)
    func toBoolean(at idx: Int32) -> Bool {
        return lua_toboolean(state, idx) != 0
    }
    
    /**
     Converts the Lua value at the given index to a C string. If len is not NULL, it sets *len with the string length. The Lua value must be a string or a number; otherwise, the function returns NULL. If the value is a number, then lua_tolstring also changes the actual value in the stack to a string. (This change confuses lua_next when lua_tolstring is applied to keys during a table traversal.)
     
     - note: lua_tolstring returns a pointer to a string inside the Lua state (see §4.1.3). This string always has a zero ('\0') after its last character (as in C), but can contain other zeros in its body.
     */
    @inline(__always)
    func toString(at idx: Int32) -> String? {
        var len: Int = 0
        guard let cString = lua_tolstring(state, idx, &len) else {return nil}
        guard len > 0 else {return nil}
        return String(cString: cString)
    }
    
    /**
     Returns the raw "length" of the value at the given index: for strings, this is the string length; for tables, this is the result of the length operator ('#') with no metamethods; for userdata, this is the size of the block of memory allocated for the userdata. For other values, this call returns 0.
     */
    @inline(__always)
    func rawLen(at idx: Int32) -> UnsignedInteger {
        return lua_rawlen(state, idx)
    }
    
    /**
     Converts a value at the given index to a C function. That value must be a C function; otherwise, returns NULL.
     */
    @inline(__always)
    func toCFunction(at idx: Int32) -> CFunction? {
        return lua_tocfunction(state, idx)
    }
    
    /**
     If the value at the given index is a full userdata, returns its memory-block address. If the value is a light userdata, returns its value (a pointer). Otherwise, returns NULL.
     */
    @inline(__always)
    func toUserData(at idx: Int32) -> UnsafeMutableRawPointer? {
        return lua_touserdata(state, idx)
    }
    
    /**
     Converts the value at the given index to a Lua thread (represented as lua_State*). This value must be a thread; otherwise, the function returns NULL.
     */
    @inline(__always)
    func toThread(at idx: Int32) -> LuaC? {
        guard let threadState = lua_tothread(state, idx) else {return nil}
        return LuaC(existingState: threadState)
    }
    
    /**
     Converts the value at the given index to a generic C pointer (void*). The value can be a userdata, a table, a thread, a string, or a function; otherwise, lua_topointer returns NULL. Different objects will give different pointers. There is no way to convert the pointer back to its original value.
     
     - note: Typically this function is used only for hashing and debug information.
     */
    @inline(__always)
    func toPointer(at idx: Int32) -> UnsafeRawPointer? {
        return lua_topointer(state, idx)
    }
}

/*
 ** Comparison and arithmetic functions
 */
public extension LuaC {
    enum Operator: Int32 { /* ORDER TM, ORDER OP */
        /// LUA_OPADD: performs addition (+)
        case add = 0
        /// LUA_OPSUB: performs subtraction (-)
        case subtract
        /// LUA_OPMUL: performs multiplication (*)
        case multiply
        /// LUA_OPMOD: performs modulo (%)
        case modulo
        /// LUA_OPPOW: performs exponentiation (^)
        case pow
        /// LUA_OPDIV: performs float division (/)
        case division
        /// LUA_OPIDIV: performs floor division (//)
        case divisionFlooring
        /// LUA_OPBAND: performs bitwise AND (&)
        case binaryAnd
        /// LUA_OPBOR: performs bitwise OR (|)
        case binaryOr
        /// LUA_OPBXOR: performs bitwise exclusive OR (~)
        case binardExclusiveOr
        /// LUA_OPSHL: performs left shift (<<)
        case shiftLeft
        /// LUA_OPSHR: performs right shift (>>)
        case shiftRight
        /// LUA_OPUNM: performs mathematical negation (unary -)
        case negate
        /// LUA_OPBNOT: performs bitwise NOT (~)
        case binaryNot
    }
    
    /**
     Performs an arithmetic or bitwise operation over the two values (or one, in the case of negations) at the top of the stack, with the value on the top being the second operand, pops these values, and pushes the result of the operation. The function follows the semantics of the corresponding Lua operator (that is, it may call metamethods).
     */
    @inline(__always)
    func arith(_ op: Operator) {
        lua_arith(state, op.rawValue)
    }
    
    enum Comparison: Int32 {
        /// LUA_OPEQ: compares for equality (==)
        case equal = 0
        /// LUA_OPLT: compares for less than (<)
        case lessThan
        /// LUA_OPLE: compares for less or equal (<=)
        case lessThanOrEqual
    }
    
    /// Returns 1 if the two values in indices index1 and index2 are primitively equal (that is, equal without calling the __eq metamethod). Otherwise returns 0. Also returns 0 if any of the indices are not valid.
    @inline(__always)
    func rawEqual(lhs idx1: Int32, rhs idx2: Int32) -> Bool {
        return lua_rawequal(state, idx1, idx2) != 0
    }
    
    /**
     Compares two Lua values. Returns 1 if the value at index index1 satisfies op when compared with the value at index index2, following the semantics of the corresponding Lua operator (that is, it may call metamethods). Otherwise returns 0. Also returns 0 if any of the indices is not valid.
     */
    @inline(__always)
    func compare(lhs idx1: Int32, rhs idx2: Int32, comparison op: Comparison) -> Bool {
        return lua_compare(state, idx1, idx2, op.rawValue) != 0
    }
}

/*
 ** push functions (C -> stack)
 */
public extension LuaC {
    /// Pushes a nil value onto the stack.
    @inline(__always)
    func pushNil() {
        lua_pushnil(state)
    }
    
    /// Pushes a float with value n onto the stack.
    @inline(__always)
    func pushNumber(_ n: Number) {
        lua_pushnumber(state, n)
    }
    
    /// Pushes an integer with value n onto the stack.
    @inline(__always)
    func pushInteger(_ n: Integer) {
        lua_pushinteger(state, n)
    }
    
    /**
     Pushes the string pointed to by s with size len onto the stack. Lua will make or reuse an internal copy of the given string, so the memory at s can be freed or reused immediately after the function returns. The string can contain any binary data, including embedded zeros.
     
     - returns: Returns a pointer to the internal copy of the string (see §4.1.3).
     */
    @inline(__always) @discardableResult
    func pushString(_ s: String) -> UnsafePointer<CChar> {
        return s.withCString { cString in
            return lua_pushstring(state, cString)
        }
    }
    
    /**
     Pushes a new C closure onto the stack. This function receives a pointer to a C function and pushes onto the stack a Lua value of type function that, when called, invokes the corresponding C function. The parameter n tells how many upvalues this function will have (see §4.2).
     
     Any function to be callable by Lua must follow the correct protocol to receive its parameters and return its results (see lua_CFunction).
     
     When a C function is created, it is possible to associate some values with it, the so called upvalues; these upvalues are then accessible to the function whenever it is called. This association is called a C closure (see §4.2). To create a C closure, first the initial values for its upvalues must be pushed onto the stack. (When there are multiple upvalues, the first value is pushed first.) Then lua_pushcclosure is called to create and push the C function onto the stack, with the argument n telling how many values will be associated with the function. lua_pushcclosure also pops these values from the stack.
     
     The maximum value for n is 255.
     
     When n is zero, this function creates a light C function, which is just a pointer to the C function. In that case, it never raises a memory error.
     */
    @inline(__always)
    func pushCClosure(_ fn: @escaping CFunction, _ n: Int32) {
        lua_pushcclosure(state, fn, n)
    }
    
    /// Pushes a boolean value with value b onto the stack.
    @inline(__always)
    func pushBoolean(_ b: Bool) {
        lua_pushboolean(state, b ? 1 : 0)
    }
    
    /**
     Pushes a light userdata onto the stack.
     
     Userdata represent C values in Lua. A light userdata represents a pointer, a void*. It is a value (like a number): you do not create it, it has no individual metatable, and it is not collected (as it was never created). A light userdata is equal to "any" light userdata with the same C address.
     */
    @inline(__always)
    func pushLightUserData(_ p: UnsafeMutableRawPointer) {
        lua_pushlightuserdata(state, p)
    }
    
    /// Pushes the thread represented by L onto the stack. Returns 1 if this thread is the main thread of its state.
    @inline(__always)
    func pushThread(_ l: LuaC) -> Bool {
        return lua_pushthread(l.state) != 0
    }
}

/*
 ** get functions (Lua -> stack)
 */
public extension LuaC {
    /// Pushes onto the stack the value of the global name. Returns the type of that value.
    @inline(__always) @discardableResult
    func getGlobal(named name: String) -> BasicType {
        return name.withCString { cString in
            return BasicType(rawValue: lua_getglobal(state, cString))!
        }
    }
    
    /**
     Pushes onto the stack the value t[k], where t is the value at the given index and k is the value on the top of the stack.
     
     This function pops the key from the stack, pushing the resulting value in its place. As in Lua, this function may trigger a metamethod for the "index" event (see §2.4).
     
     - returns: Returns the type of the pushed value.
     */
    @inline(__always) @discardableResult
    func getTable(at idx: Int32) -> BasicType {
        return BasicType(rawValue: lua_gettable(state, idx))!
    }
    
    /**
     Pushes onto the stack the value t[k], where t is the value at the given index. As in Lua, this function may trigger a metamethod for the "index" event (see §2.4).
     
     - returns: Returns the type of the pushed value.
     */
    @inline(__always) @discardableResult
    func getField(at idx: Int32, _ k: String) -> BasicType {
        return k.withCString { cString in
            return BasicType(rawValue: lua_getfield(state, idx, cString))!
        }
    }
    
    /**
     Pushes onto the stack the value t[i], where t is the value at the given index. As in Lua, this function may trigger a metamethod for the "index" event (see §2.4).
     
     - returns: Returns the type of the pushed value.
     */
    @inline(__always) @discardableResult
    func getI(at idx: Int32, number n: Integer) -> BasicType {
        return BasicType(rawValue: lua_geti(state, idx, n))!
    }
    
    /// Similar to lua_gettable, but does a raw access (i.e., without metamethods).
    @inline(__always) @discardableResult
    func rawGet(at idx: Int32) -> BasicType {
        return BasicType(rawValue: lua_rawget(state, idx))!
    }
    
    /**
     Pushes onto the stack the value t[n], where t is the table at the given index. The access is raw, that is, it does not use the __index metavalue.
     
     - returns: Returns the type of the pushed value.
     */
    @inline(__always) @discardableResult
    func rawGetI(at idx: Int32, number n: Integer) -> BasicType {
        return BasicType(rawValue: lua_rawgeti(state, idx, n))!
    }
    
    /**
     Pushes onto the stack the value t[k], where t is the table at the given index and k is the pointer p represented as a light userdata. The access is raw; that is, it does not use the __index metavalue.
     
     - returns: Returns the type of the pushed value.
     */
    @inline(__always) @discardableResult
    func rawGetI(at idx: Int32, pointer p: UnsafeRawPointer) -> BasicType {
        return BasicType(rawValue: lua_rawgetp(state, idx, p))!
    }
    
    /**
     Creates a new empty table and pushes it onto the stack. Parameter narr is a hint for how many elements the table will have as a sequence; parameter nrec is a hint for how many other elements the table will have. Lua may use these hints to preallocate memory for the new table. This preallocation may help performance when you know in advance how many elements the table will have. Otherwise you can use the function lua_newtable.
     */
    @inline(__always)
    func createTable(_ narr: Int32, _ nrec: Int32) {
        lua_createtable(state, narr, nrec)
    }
    
    /**
     This function creates and pushes on the stack a new full userdata, with nuvalue associated Lua values, called user values, plus an associated block of raw memory with size bytes. (The user values can be set and read with the functions lua_setiuservalue and lua_getiuservalue.)
     
     - returns: The function returns the address of the block of memory. Lua ensures that this address is valid as long as the corresponding userdata is alive (see §2.5). Moreover, if the userdata is marked for finalization (see §2.5.3), its address is valid at least until the call to its finalizer.
     */
    @inline(__always)
    func newUserDataUV(_ sz: Int, nuvalue: Int32) -> UnsafeMutableRawPointer {
        return lua_newuserdatauv(state, sz, nuvalue)
    }
    
    /// If the value at the given index has a metatable, the function pushes that metatable onto the stack and returns 1. Otherwise, the function returns 0 and pushes nothing on the stack.
    @inline(__always)
    func getMetaTable(_ objindex: Int32) -> Bool {
        return lua_getmetatable(state, objindex) != 0
    }
    
    /**
     Pushes onto the stack the n-th user value associated with the full userdata at the given index and returns the type of the pushed value.
     
     If the userdata does not have that value, pushes nil and returns LUA_TNONE.
     */
    @inline(__always) @discardableResult
    func getIUserValue(at idx: Int32, _ n: Int32) -> BasicType {
        return BasicType(rawValue: lua_getiuservalue(state, idx, n))!
    }
}

/*
 ** set functions (stack -> Lua)
 */
public extension LuaC {
    /// Pops a value from the stack and sets it as the new value of global name.
    @inline(__always)
    func setGloabal(named name: String) {
        name.withCString { cString in
            lua_setglobal(state, cString)
        }
    }
    
    /**
     Does the equivalent to t[k] = v, where t is the value at the given index, v is the value on the top of the stack, and k is the value just below the top.
     
     This function pops both the key and the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see §2.4).
     */
    @inline(__always)
    func setTable(at idx: Int32) {
        lua_settable(state, idx)
    }
    
    /**
     Does the equivalent to t[k] = v, where t is the value at the given index and v is the value on the top of the stack.
     
     This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see §2.4).
     */
    @inline(__always)
    func setField(at idx: Int32, _ k: String) {
        k.withCString { cString in
            lua_setfield(state, idx, cString)
        }
    }
    
    /**
     Does the equivalent to t[n] = v, where t is the value at the given index and v is the value on the top of the stack.
     
     This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see §2.4).
     */
    @inline(__always)
    func setI(at idx: Int32, number n: Integer) {
        lua_seti(state, idx, n)
    }
    
    /// Similar to lua_settable, but does a raw assignment (i.e., without metamethods).
    @inline(__always)
    func rawSet(at idx: Int32) {
        lua_rawset(state, idx)
    }
    
    /**
     Does the equivalent of t[i] = v, where t is the table at the given index and v is the value on the top of the stack.
     
     This function pops the value from the stack. The assignment is raw, that is, it does not use the __newindex metavalue.
     */
    @inline(__always)
    func rawSetI(at idx: Int32, number n: Integer) {
        lua_rawseti(state, idx, n)
    }
    
    /**
     Does the equivalent of t[p] = v, where t is the table at the given index, p is encoded as a light userdata, and v is the value on the top of the stack.
     
     This function pops the value from the stack. The assignment is raw, that is, it does not use the __newindex metavalue.
     */
    @inline(__always)
    func rawSetP(at idx: Int32, pointer p: UnsafeRawPointer) {
        lua_rawsetp(state, idx, p)
    }
    
    /**
     Pops a table or nil from the stack and sets that value as the new metatable for the value at the given index. (nil means no metatable.)
     
     (For historical reasons, this function returns an int, which now is always 1.)
     */
    @inline(__always) @discardableResult
    func setMetaTable(_ objindex: Int32) -> Int32 {
        return lua_setmetatable(state, objindex)
    }
    
    /// Pops a value from the stack and sets it as the new n-th user value associated to the full userdata at the given index. Returns 0 if the userdata does not have that value.
    @inline(__always)
    func setIUserValue(at idx: Int32, _ n: Int32) -> Bool {
        return lua_setiuservalue(state, idx, n) != 0
    }
}


/*
 ** 'load' and 'call' functions (load and run Lua code)
 */
public extension LuaC {
    
    /// This function behaves exactly like lua_call, but allows the called function to yield (see §4.5).
    @inline(__always)
    func callk(_ nargs: Int32, _ nresults: Int32, _ ctx: lua_KContext, _ k: KFunction?) {
        lua_callk(state, nargs, nresults, ctx, k)
    }
    
    /**
     Calls a function. Like regular Lua calls, lua_call respects the __call metamethod. So, here the word "function" means any callable value.
     
     To do a call you must use the following protocol: first, the function to be called is pushed onto the stack; then, the arguments to the call are pushed in direct order; that is, the first argument is pushed first. Finally you call lua_call; nargs is the number of arguments that you pushed onto the stack. When the function returns, all arguments and the function value are popped and the call results are pushed onto the stack. The number of results is adjusted to nresults, unless nresults is LUA_MULTRET. In this case, all results from the function are pushed; Lua takes care that the returned values fit into the stack space, but it does not ensure any extra space in the stack. The function results are pushed onto the stack in direct order (the first result is pushed first), so that after the call the last result is on the top of the stack.
     
     Any error while calling and running the function is propagated upwards (with a longjmp).
     
     The following example shows how the host program can do the equivalent to this Lua code:
     
     a = f("how", t.x, 14)
     Here it is in C:
     
     lua_getglobal(L, "f");                  /* function to be called */
     lua_pushliteral(L, "how");                       /* 1st argument */
     lua_getglobal(L, "t");                    /* table to be indexed */
     lua_getfield(L, -1, "x");        /* push result of t.x (2nd arg) */
     lua_remove(L, -2);                  /* remove 't' from the stack */
     lua_pushinteger(L, 14);                          /* 3rd argument */
     lua_call(L, 3, 1);     /* call 'f' with 3 arguments and 1 result */
     lua_setglobal(L, "a");                         /* set global 'a' */
     Note that the code above is balanced: at its end, the stack is back to its original configuration. This is considered good programming practice.
     */
    @inline(__always)
    func call(_ nargs: Int32, _ nresults: Int32) {
        callk(nargs, nresults, 0, nil)
    }
    
    /// This function behaves exactly like lua_pcall, except that it allows the called function to yield (see §4.5).
    @inline(__always)
    func pcallk(_ nargs: Int32, _ nresults: Int32, _ errfunc: Int32, _ ctx: lua_KContext, _ k: lua_KFunction?) -> ThreadStatus {
        return ThreadStatus(rawValue: lua_pcallk(state, nargs, nresults, errfunc, ctx, k))!
    }
    
    /**
     Calls a function (or a callable object) in protected mode.
     
     Both nargs and nresults have the same meaning as in lua_call. If there are no errors during the call, lua_pcall behaves exactly like lua_call. However, if there is any error, lua_pcall catches it, pushes a single value on the stack (the error object), and returns an error code. Like lua_call, lua_pcall always removes the function and its arguments from the stack.
     
     If msgh is 0, then the error object returned on the stack is exactly the original error object. Otherwise, msgh is the stack index of a message handler. (This index cannot be a pseudo-index.) In case of runtime errors, this handler will be called with the error object and its return value will be the object returned on the stack by lua_pcall.
     
     Typically, the message handler is used to add more debug information to the error object, such as a stack traceback. Such information cannot be gathered after the return of lua_pcall, since by then the stack has unwound.
     
     The lua_pcall function returns one of the following status codes: LUA_OK, LUA_ERRRUN, LUA_ERRMEM, or LUA_ERRERR.
     */
    @inline(__always)
    func pcall(_ nargs: Int32, _ nresults: Int32, _ errfunc: Int32) -> ThreadStatus {
        return pcallk(nargs, nresults, errfunc, 0, nil)
    }
    
    /**
     Loads a Lua chunk without running it. If there are no errors, lua_load pushes the compiled chunk as a Lua function on top of the stack. Otherwise, it pushes an error message.
     
     The lua_load function uses a user-supplied reader function to read the chunk (see lua_Reader). The data argument is an opaque value passed to the reader function.
     
     The chunkname argument gives a name to the chunk, which is used for error messages and in debug information (see §4.7).
     
     lua_load automatically detects whether the chunk is text or binary and loads it accordingly (see program luac). The string mode works as in function load, with the addition that a NULL value is equivalent to the string "bt".
     
     lua_load uses the stack internally, so the reader function must always leave the stack unmodified when returning.
     
     lua_load can return LUA_OK, LUA_ERRSYNTAX, or LUA_ERRMEM. The function may also return other values corresponding to errors raised by the read function (see §4.4.1).
     
     If the resulting function has upvalues, its first upvalue is set to the value of the global environment stored at index LUA_RIDX_GLOBALS in the registry (see §4.3). When loading main chunks, this upvalue will be the _ENV variable (see §2.2). Other upvalues are initialized with nil.
     */
    @inline(__always)
    func load(_ reader: @escaping Reader, _ dt: UnsafeMutableRawPointer!, _ chunkname: UnsafePointer<CChar>!, _ mode: UnsafePointer<CChar>!) -> ThreadStatus {
        let status = lua_load(state, reader, dt, chunkname, mode)
        return ThreadStatus(rawValue: status)!
    }
    
    /**
     Dumps a function as a binary chunk. Receives a Lua function on the top of the stack and produces a binary chunk that, if loaded again, results in a function equivalent to the one dumped. As it produces parts of the chunk, lua_dump calls function writer (see lua_Writer) with the given data to write them.
     
     If strip is true, the binary representation may not include all debug information about the function, to save space.
     
     The value returned is the error code returned by the last call to the writer; 0 means no errors.
     
     This function does not pop the Lua function from the stack.
     */
    @inline(__always)
    func dump(_ writer: @escaping Writer, _ data: UnsafeMutableRawPointer!, _ strip: Int32) -> ThreadStatus {
        let status = lua_dump(state, writer, data, strip)
        return ThreadStatus(rawValue: status)!
    }
}

/*
 ** coroutine functions
 */
public extension LuaC {
    /**
     Yields a coroutine (thread).
     
     When a C function calls lua_yieldk, the running coroutine suspends its execution, and the call to lua_resume that started this coroutine returns. The parameter nresults is the number of values from the stack that will be passed as results to lua_resume.
     
     When the coroutine is resumed again, Lua calls the given continuation function k to continue the execution of the C function that yielded (see §4.5). This continuation function receives the same stack from the previous function, with the n results removed and replaced by the arguments passed to lua_resume. Moreover, the continuation function receives the value ctx that was passed to lua_yieldk.
     
     Usually, this function does not return; when the coroutine eventually resumes, it continues executing the continuation function. However, there is one special case, which is when this function is called from inside a line or a count hook (see §4.7). In that case, lua_yieldk should be called with no continuation (probably in the form of lua_yield) and no results, and the hook should return immediately after the call. Lua will yield and, when the coroutine resumes again, it will continue the normal execution of the (Lua) function that triggered the hook.
     
     This function can raise an error if it is called from a thread with a pending C call with no continuation function (what is called a C-call boundary), or it is called from a thread that is not running inside a resume (typically the main thread).
     */
    @inline(__always)
    func yieldk(_ nresults: Int32, _ ctx: KContext, _ k: KFunction?) -> ThreadStatus {
        let status = lua_yieldk(state, nresults, ctx, k)
        return ThreadStatus(rawValue: status)!
    }
    
    /**
     This function is equivalent to lua_yieldk, but it has no continuation (see §4.5). Therefore, when the thread resumes, it continues the function that called the function calling lua_yield. To avoid surprises, this function should be called only in a tail call.
     */
    @inline(__always)
    func yield(_ nresults: Int32) -> ThreadStatus {
        return yieldk(nresults, 0, nil)
    }
    
    /**
     Starts and resumes a coroutine in the given thread L.
     
     To start a coroutine, you push the main function plus any arguments onto the empty stack of the thread. then you call lua_resume, with nargs being the number of arguments. This call returns when the coroutine suspends or finishes its execution. When it returns, *nresults is updated and the top of the stack contains the *nresults values passed to lua_yield or returned by the body function. lua_resume returns LUA_YIELD if the coroutine yields, LUA_OK if the coroutine finishes its execution without errors, or an error code in case of errors (see §4.4.1). In case of errors, the error object is on the top of the stack.
     
     To resume a coroutine, you remove the *nresults yielded values from its stack, push the values to be passed as results from yield, and then call lua_resume.
     
     The parameter from represents the coroutine that is resuming L. If there is no such coroutine, this parameter can be NULL.
     */
    @inline(__always)
    func resume(_ from: LuaC?, _ narg: Int32, _ nres: inout Int32) -> ThreadStatus {
        let status = lua_resume(state, from?.state, narg, &nres)
        return ThreadStatus(rawValue: status)!
    }
    
    /**
     Returns the status of the thread L.
     
     The status can be LUA_OK for a normal thread, an error code if the thread finished the execution of a lua_resume with an error, or LUA_YIELD if the thread is suspended.
     
     You can call functions only in threads with status LUA_OK. You can resume threads with status LUA_OK (to start a new coroutine) or LUA_YIELD (to resume a coroutine).
     */
    @inline(__always)
    var status: ThreadStatus {
        return ThreadStatus(rawValue: lua_status(state))!
    }
    
    /// Returns 1 if the given coroutine can yield, and 0 otherwise.
    var isYieldable: Bool {
        return lua_isyieldable(state) != 0
    }
}

/*
 ** Warning-related functions
 */
public extension LuaC {
    /// Sets the warning function to be used by Lua to emit warnings (see lua_WarnFunction). The ud parameter sets the value ud passed to the warning function.
    @inline(__always)
    func setWarnF(_ f: @escaping WarnFunction, _ ud: UnsafeMutableRawPointer?) {
        lua_setwarnf(state, f, ud)
    }
    
    /**
     Emits a warning with the given message. A message in a call with tocont true should be continued in another call to this function.
     
     See warn for more details about warnings.
     */
    @inline(__always)
    func warning(_ msg: String, _ tocont: Bool) {
        msg.withCString { cString in
            lua_warning(state, cString, tocont ? 1 : 0)
        }
    }
}

/*
 ** garbage-collection function and options
 */
public extension LuaC {
    enum GarbageCollectionOption: Int32 {
        /// LUA_GCSTOP: Stops the garbage collector.
        case stop = 0
        /// LUA_GCRESTART: Restarts the garbage collector.
        case restart
        /// LUA_GCCOLLECT: Performs a full garbage-collection cycle.
        case collect
        /// LUA_GCCOUNT: Returns the current amount of memory (in Kbytes) in use by Lua.
        case count
        /// LUA_GCCOUNTB: Returns the remainder of dividing the current amount of bytes of memory in use by Lua by 1024.
        case countB
        /// LUA_GCSTEP (int stepsize): Performs an incremental step of garbage collection, corresponding to the allocation of stepsize Kbytes.
        case step
        case setPause
        case setStepMul
        /// LUA_GCISRUNNING: Returns a boolean that tells whether the collector is running (i.e., not stopped).
        case isRunning
        /// LUA_GCGEN (int minormul, int majormul): Changes the collector to generational mode with the given parameters (see §2.5.2). Returns the previous mode (LUA_GCGEN or LUA_GCINC).
        case gen
        /// LUA_GCINC (int pause, int stepmul, stepsize): Changes the collector to incremental mode with the given parameters (see §2.5.1). Returns the previous mode (LUA_GCGEN or LUA_GCINC).
        case inc
    }
}

/*
 ** miscellaneous functions
 */
public extension LuaC {
    /// Raises a Lua error, using the value on the top of the stack as the error object. This function does a long jump, and therefore never returns (see luaL_error).
    @inline(__always)
    func error() {
        _ = lua_error(state)
    }
    
    /**
     Pops a key from the stack, and pushes a key–value pair from the table at the given index, the "next" pair after the given key. If there are no more elements in the table, then lua_next returns 0 and pushes nothing.
     
     A typical table traversal looks like this:
     
     /* table is in the stack at index 't' */
     lua_pushnil(L);  /* first key */
     while (lua_next(L, t) != 0) {
     /* uses 'key' (at index -2) and 'value' (at index -1) */
     printf("%s - %s\n",
     lua_typename(L, lua_type(L, -2)),
     lua_typename(L, lua_type(L, -1)));
     /* removes 'value'; keeps 'key' for next iteration */
     lua_pop(L, 1);
     }
     While traversing a table, avoid calling lua_tolstring directly on a key, unless you know that the key is actually a string. Recall that lua_tolstring may change the value at the given index; this confuses the next call to lua_next.
     
     This function may raise an error if the given key is neither nil nor present in the table. See function next for the caveats of modifying the table during its traversal.
     */
    @inline(__always)
    func next(at idx: Int32) -> Bool {
        return lua_next(state, idx) != 0
    }
    
    /**
     Concatenates the n values at the top of the stack, pops them, and leaves the result on the top. If n is 1, the result is the single value on the stack (that is, the function does nothing); if n is 0, the result is the empty string. Concatenation is performed following the usual semantics of Lua (see §3.4.6).
     */
    @inline(__always)
    func concat(_ n: Int32) {
        lua_concat(state, n)
    }
    
    /// Returns the length of the value at the given index. It is equivalent to the '#' operator in Lua (see §3.4.7) and may trigger a metamethod for the "length" event (see §2.4). The result is pushed on the stack.
    @inline(__always)
    func len(at idx: Int32) {
        lua_len(state, idx)
    }
    
    /**
     Converts the zero-terminated string s to a number, pushes that number into the stack, and returns the total size of the string, that is, its length plus one. The conversion can result in an integer or a float, according to the lexical conventions of Lua (see §3.1). The string may have leading and trailing whitespaces and a sign. If the string is not a valid numeral, returns 0 and pushes nothing. (Note that the result can be used as a boolean, true if the conversion succeeds.)
     */
    @inline(__always)
    func stringToNumber(_ s: String) -> Bool {
        return s.withCString { cString in
            return lua_stringtonumber(state, cString) != 0
        }
    }
    
    /// Returns the memory-allocation function of a given state. If ud is not NULL, Lua stores in *ud the opaque pointer given when the memory-allocator function was set.
    @inline(__always)
    func getAllocF(_ ud: UnsafeMutablePointer<UnsafeMutableRawPointer?>? = nil) -> Alloc {
        return lua_getallocf(state, ud)
    }
    
    /// Changes the allocator function of a given state to f with user data ud.
    @inline(__always)
    func setAllocF(_ f: @escaping Alloc, _ ud: UnsafeMutableRawPointer?) {
        lua_setallocf(state, f, ud)
    }
    
    /**
     Marks the given index in the stack as a to-be-closed slot (see §3.3.8). Like a to-be-closed variable in Lua, the value at that slot in the stack will be closed when it goes out of scope. Here, in the context of a C function, to go out of scope means that the running function returns to Lua, or there is an error, or the slot is removed from the stack through lua_settop or lua_pop, or there is a call to lua_closeslot. A slot marked as to-be-closed should not be removed from the stack by any other function in the API except lua_settop or lua_pop, unless previously deactivated by lua_closeslot.
     
     This function should not be called for an index that is equal to or below an active to-be-closed slot.
     
     Note that, both in case of errors and of a regular return, by the time the __close metamethod runs, the C stack was already unwound, so that any automatic C variable declared in the calling function (e.g., a buffer) will be out of scope.
     */
    @inline(__always)
    func toClose(at idx: Int32) {
        lua_toclose(state, idx)
    }
    
    /**
     Close the to-be-closed slot at the given index and set its value to nil. The index must be the last index previously marked to be closed (see lua_toclose) that is still active (that is, not closed yet).
     
     A __close metamethod cannot yield when called through this function.
     
     (Exceptionally, this function was introduced in release 5.4.3. It is not present in previous 5.4 releases.)
     */
    @inline(__always)
    func closeSlot(at idx:Int32) {
        lua_closeslot(state, idx)
    }
}

/*
 ** {==============================================================
 ** some useful macros
 ** ===============================================================
 */
public extension LuaC {
    /// Pops n elements from the stack. It is implemented as a macro over lua_settop.
    @inline(__always)
    func pop(_ n: Int32) {
        setTop(-n - 1)
    }
    
    /// Creates a new empty table and pushes it onto the stack. It is equivalent to lua_createtable(L, 0, 0).
    @inline(__always)
    func newTable() {
        createTable(0, 0)
    }
    
    /// Sets the C function f as the new value of global name.
    @inline(__always)
    func register(function fn: @escaping CFunction, named name: String) {
        pushCFunction(fn)
        setGloabal(named: name)
    }
    
    /// Pushes a C function onto the stack. This function is equivalent to lua_pushcclosure with no upvalues.
    @inline(__always)
    func pushCFunction(_ fn: @escaping CFunction) {
        self.pushCClosure(fn, 0)
    }
    
    /// Returns 1 if the value at the given index is a function (either C or Lua), and 0 otherwise.
    @inline(__always)
    func isFunction(at idx: Int32) -> Bool {
        return type(at: idx) == .function
    }
    
    /// Returns 1 if the value at the given index is a table, and 0 otherwise.
    @inline(__always)
    func isTable(at idx: Int32) -> Bool {
        return type(at: idx) == .table
    }
    
    /// Returns 1 if the value at the given index is a light userdata, and 0 otherwise.
    @inline(__always)
    func isLightUserData(at idx: Int32) -> Bool {
        return type(at: idx) == .lightUserData
    }
    
    /// Returns 1 if the value at the given index is nil, and 0 otherwise.
    @inline(__always)
    func isNil(at idx: Int32) -> Bool {
        return type(at: idx) == .nil
    }
    
    /// Returns 1 if the value at the given index is a boolean, and 0 otherwise.
    @inline(__always)
    func isBoolean(at idx: Int32) -> Bool {
        return type(at: idx) == .boolean
    }
    
    /// Returns 1 if the value at the given index is a thread, and 0 otherwise.
    @inline(__always)
    func isThread(at idx: Int32) -> Bool {
        return type(at: idx) == .thread
    }
    
    /// Returns 1 if the given index is not valid, and 0 otherwise.
    @inline(__always)
    func isNone(at idx: Int32) -> Bool {
        return type(at: idx) == .none
    }
    
    /// Returns 1 if the given index is not valid or if the value at this index is nil, and 0 otherwise.
    @inline(__always)
    func isNoneOrNil(at idx: Int32) -> Bool {
        return type(at: idx).rawValue <= 0
    }
    
    /// This macro is equivalent to lua_pushstring, but should be used only when s is a literal string. (Lua may optimize this case.)
    @inline(__always)
    func pushLiteral(_ s: String) {
        pushString(s)
    }
    
    /// Pushes the global environment onto the stack.
    @inline(__always)
    func pushGlobalTable() {
        _ = rawGetI(at: LuaC.registryIndex, number: Integer(LuaC.ridxGlobals))
    }
    
    /// Moves the top element into the given valid index, shifting up the elements above this index to open space. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
    @inline(__always)
    func insert(at idx: Int32) {
        rotate(idx: idx, by: 1)
    }
    
    /// Removes the element at the given valid index, shifting down the elements above this index to fill the gap. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
    @inline(__always)
    func remove(at idx: Int32) {
        rotate(idx: idx, by: -1)
        pop(1)
    }
    
    /// Moves the top element into the given valid index without shifting any element (therefore replacing the value at that given index), and then pops the top element.
    @inline(__always)
    func replace(at idx: Int32) {
        copy(from: -1, to: idx)
        pop(1)
    }
}

public extension LuaC {
    @inline(__always)
    static var numTags: Int32 {BasicType.numTypes.rawValue}
}


/* }============================================================== */

/*
 ** {======================================================================
 ** Debug API
 ** =======================================================================
 */
public extension LuaC {
    /*
     ** Event codes
     */
    enum EventCode: Int32 {
        case hookCall = 0
        case hookRet
        case hookLine
        case hookCount
        case hookTailCall
    }
    
    /*
     ** Event masks
     */
    struct EventMask: OptionSet {
        public typealias RawValue = Int32
        public let rawValue: RawValue
        
        static let maskCall = EventMask(rawValue: 1 << EventCode.hookCall.rawValue)
        static let maskRet = EventMask(rawValue: 1 << EventCode.hookRet.rawValue)
        static let maskLine = EventMask(rawValue: 1 << EventCode.hookLine.rawValue)
        static let maskCount = EventMask(rawValue: 1 << EventCode.hookCount.rawValue)
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
    
    /* Functions to be called by the debugger in specific events */
    typealias Hook = @convention(c) (OpaquePointer?, UnsafeMutablePointer<lua_Debug>?) -> Void
    
    /**
     Gets information about the interpreter runtime stack.
     
     This function fills parts of a lua_Debug structure with an identification of the activation record of the function executing at a given level. Level 0 is the current running function, whereas level n+1 is the function that has called level n (except for tail calls, which do not count in the stack). When called with a level greater than the stack depth, lua_getstack returns 0; otherwise it returns 1.
     */
    @inline(__always)
    func getStack(_ level: Int32, _ ar: inout lua_Debug) -> Bool {
        return lua_getstack(state, level, &ar) != 0
    }
    
    /**
     Gets information about a specific function or function invocation.
     
     To get information about a function invocation, the parameter ar must be a valid activation record that was filled by a previous call to lua_getstack or given as argument to a hook (see lua_Hook).
     
     To get information about a function, you push it onto the stack and start the what string with the character '>'. (In that case, lua_getinfo pops the function from the top of the stack.) For instance, to know in which line a function f was defined, you can write the following code:
     
     lua_Debug ar;
     lua_getglobal(L, "f");  /* get global 'f' */
     lua_getinfo(L, ">S", &ar);
     printf("%d\n", ar.linedefined);
     Each character in the string what selects some fields of the structure ar to be filled or a value to be pushed on the stack. (These characters are also documented in the declaration of the structure lua_Debug, between parentheses in the comments following each field.)
     
     'f': pushes onto the stack the function that is running at the given level;
     'l': fills in the field currentline;
     'n': fills in the fields name and namewhat;
     'r': fills in the fields ftransfer and ntransfer;
     'S': fills in the fields source, short_src, linedefined, lastlinedefined, and what;
     't': fills in the field istailcall;
     'u': fills in the fields nups, nparams, and isvararg;
     'L': pushes onto the stack a table whose indices are the lines on the function with some associated code, that is, the lines where you can put a break point. (Lines with no code include empty lines and comments.) If this option is given together with option 'f', its table is pushed after the function. This is the only option that can raise a memory error.
     This function returns 0 to signal an invalid option in what; even then the valid options are handled correctly.
     */
    @inline(__always)
    func getInfo(_ what: String, _ ar: inout lua_Debug) -> Bool {
        return what.withCString { cString in
            return lua_getinfo(state, cString, &ar) != 0
        }
    }
    
    /**
     Gets information about a local variable or a temporary value of a given activation record or a given function.
     
     In the first case, the parameter ar must be a valid activation record that was filled by a previous call to lua_getstack or given as argument to a hook (see lua_Hook). The index n selects which local variable to inspect; see debug.getlocal for details about variable indices and names.
     
     lua_getlocal pushes the variable's value onto the stack and returns its name.
     
     In the second case, ar must be NULL and the function to be inspected must be on the top of the stack. In this case, only parameters of Lua functions are visible (as there is no information about what variables are active) and no values are pushed onto the stack.
     
     Returns NULL (and pushes nothing) when the index is greater than the number of active local variables.
     */
    @inline(__always)
    func getLocal(_ ar: inout lua_Debug!, _ n: Int32) -> String? {
        guard let cString = lua_getlocal(state, &ar, n) else {return nil}
        return String(cString: cString)
    }
    
    /**
     Sets the value of a local variable of a given activation record. It assigns the value on the top of the stack to the variable and returns its name. It also pops the value from the stack.
     
     Returns NULL (and pops nothing) when the index is greater than the number of active local variables.
     
     Parameters ar and n are as in the function lua_getlocal.
     */
    @inline(__always)
    func setLocal(_ ar: inout lua_Debug!, _ n: Int32) -> String? {
        guard let cString = lua_setlocal(state, &ar, n) else {return nil}
        return String(cString: cString)
    }
    
    /**
     Gets information about the n-th upvalue of the closure at index funcindex. It pushes the upvalue's value onto the stack and returns its name. Returns NULL (and pushes nothing) when the index n is greater than the number of upvalues.
     
     See debug.getupvalue for more information about upvalues.
     */
    @inline(__always)
    func getUpValue(_ funcindex: Int32, _ n: Int32) -> String? {
        guard let cString = lua_getupvalue(state, funcindex, n) else {return nil}
        return String(cString: cString)
    }
    
    /**
     Sets the value of a closure's upvalue. It assigns the value on the top of the stack to the upvalue and returns its name. It also pops the value from the stack.
     
     Returns NULL (and pops nothing) when the index n is greater than the number of upvalues.
     
     Parameters funcindex and n are as in the function lua_getupvalue.
     */
    @inline(__always)
    func setUpValue(_ funcindex: Int32, _ n: Int32) -> String? {
        guard let cString = lua_setupvalue(state, funcindex, n) else {return nil}
        return String(cString: cString)
    }
    
    /**
     Returns a unique identifier for the upvalue numbered n from the closure at index funcindex.
     
     These unique identifiers allow a program to check whether different closures share upvalues. Lua closures that share an upvalue (that is, that access a same external local variable) will return identical ids for those upvalue indices.
     
     Parameters funcindex and n are as in the function lua_getupvalue, but n cannot be greater than the number of upvalues.
     */
    @inline(__always)
    func upValueID(_ fidx: Int32, _ n: Int32) -> UnsafeMutableRawPointer! {
        return lua_upvalueid(state, fidx, n)
    }
    
    /// Make the n1-th upvalue of the Lua closure at index funcindex1 refer to the n2-th upvalue of the Lua closure at index funcindex2.
    @inline(__always)
    func upValueJoin(_ fidx1: Int32, _ n1: Int32, _ fidx2: Int32, _ n2: Int32) {
        lua_upvaluejoin(state, fidx1, n1, fidx2, n2)
    }
    
    /**
     Sets the debugging hook function.
     
     Argument f is the hook function. mask specifies on which events the hook will be called: it is formed by a bitwise OR of the constants LUA_MASKCALL, LUA_MASKRET, LUA_MASKLINE, and LUA_MASKCOUNT. The count argument is only meaningful when the mask includes LUA_MASKCOUNT. For each event, the hook is called as explained below:
     
     The call hook: is called when the interpreter calls a function. The hook is called just after Lua enters the new function.
     The return hook: is called when the interpreter returns from a function. The hook is called just before Lua leaves the function.
     The line hook: is called when the interpreter is about to start the execution of a new line of code, or when it jumps back in the code (even to the same line). This event only happens while Lua is executing a Lua function.
     The count hook: is called after the interpreter executes every count instructions. This event only happens while Lua is executing a Lua function.
     Hooks are disabled by setting mask to zero.
     */
    @inline(__always)
    func setHook(_ f: @escaping Hook, _ mask: EventMask, _ count: Int32) {
        lua_sethook(state, f, mask.rawValue, count)
    }
    
    /// Returns the current hook function.
    @inline(__always)
    func getHook() -> Hook? {
        return lua_gethook(state)
    }
    
    /// Returns the current hook mask.
    @inline(__always)
    func getHookMask() -> EventMask {
        let mask = lua_gethookmask(state)
        return EventMask(rawValue: mask)
    }
    
    /// Returns the current hook count.
    @inline(__always)
    func getHookCount() -> Int32 {
        return lua_gethookcount(state)
    }
    
    @inline(__always)
    func setCStackLimit(_ limit: UInt32) -> Int32 {
        return lua_setcstacklimit(state, limit)
    }
}
