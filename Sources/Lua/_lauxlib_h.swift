/**
 * Copyright (c) 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import LuaC

public extension Lua {
    /// global table
    @inline(__always)
    static var gname: String {LUA_GNAME}
    
    /// key, in the registry, for table of loaded modules
    @inline(__always)
    static var loadedTable: String {LUA_LOADED_TABLE}
    
    /// key, in the registry, for table of preloaded loaders
    @inline(__always)
    static var preloadedTable: String {LUA_PRELOAD_TABLE}

    @inline(__always)
    static var numSizes: Int {MemoryLayout<Integer>.stride * 16 + MemoryLayout<Number>.stride}
    
    /// Type for arrays of functions to be registered by luaL_setfuncs. name is the function name and func is a pointer to the function. Any array of luaL_Reg must end with a sentinel entry in which both name and func are NULL.
    typealias Registration = luaL_Reg
    
    @inline(__always)
    func _checkVersion(_ ver: Number, _ sz: Int) {
        luaL_checkversion_(state, ver, sz)
    }
    
    /// Checks whether the code making the call and the Lua library being called are using the same version of Lua and the same numeric types.
    @inline(__always)
    func checkVersion() {
        _checkVersion(Number(Lua.versionNum), Lua.numSizes)
    }

    /// Pushes onto the stack the field e from the metatable of the object at index obj and returns the type of the pushed value. If the object does not have a metatable, or if the metatable does not have this field, pushes nothing and returns `LUA_TNIL`.
    @inline(__always)
    func getMetaField(_ obj: Int32, _ e: String) -> Int32? {
        let v = e.withCString { cString in
            return luaL_getmetafield(state, obj, cString)
        }
        return v == LUA_TNIL ? nil : v
    }
    
    /**
     Calls a metamethod.

     If the object at index `obj` has a metatable and this metatable has a field `e`, this function calls this field passing the object as its only argument. In this case this function returns true and pushes onto the stack the value returned by the call. If there is no metatable or no metamethod, this function returns false without pushing any value on the stack.
     */
    @inline(__always)
    func callMeta(_ obj: Int32, _ e: String) -> Int32? {
        let v = e.withCString { cString in
            luaL_callmeta(state, obj, e)
        }
        return v == 0 ? nil : v
    }
    
    /**
     Converts any Lua value at the given index to a C string in a reasonable format. The resulting string is pushed onto the stack and also returned by the function (see §4.1.3). If len is not NULL, the function also sets *len with the string length.

     If the value has a metatable with a `__tostring` field, then `luaL_tolstring` calls the corresponding metamethod with the value as argument, and uses the result of the call as its result.
     */
    @inline(__always)
    func toLString(_ idx: Int32, _ len: inout Int) -> String {
        let cString = luaL_tolstring(state, idx, &len)!
        return String(cString: cString)
    }
    
    /**
     Raises an error reporting a problem with argument arg of the C function that called it, using a standard message that includes `extramsg` as a comment:

          bad argument #arg to 'funcname' (extramsg)
     This function never returns.
     */
    @inline(__always)
    func argError(_ arg: Int32, _ extramsg: String) -> Never {
        extramsg.withCString { cString in
            _ = luaL_argerror(state, arg, cString)
        }
        fatalError()
    }
    
    /// Checks whether cond is true. If it is not, raises an error about the type of the argument arg with a standard message (see luaL_typeerror).
    @inline(__always)
    func typeError(_ arg: Int32, _ tname: String) -> Int32 {
        return tname.withCString { cString in
            return luaL_typeerror(state, arg, cString)
        }
    }
    
    /**
     Checks whether the function argument arg is a string and returns this string; if l is not NULL fills its referent with the string's length.

     This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.
     */
    @inline(__always)
    func checkLString(_ arg: Int32, _ l: inout Int) -> String {
        let cString = luaL_checklstring(state, arg, &l)!
        return String(cString: cString)
    }
    
    /**
     If the function argument arg is a string, returns this string. If this argument is absent or is nil, returns d. Otherwise, raises an error.

     If l is not NULL, fills its referent with the result's length. If the result is NULL (only possible when returning d and d == NULL), its length is considered zero.

     This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.
     */
    @inline(__always)
    func optLString(_ arg: Int32, _ def: String, _ l: inout Int) -> String {
        return def.withCString { cString in
            let cString = luaL_optlstring(state, arg, cString, &l)!
            return String(cString: cString)
        }
    }
    
    /// Checks whether the function argument arg is a number and returns this number converted to a lua_Number.
    @inline(__always)
    func checkNumber(_ arg: Int32) -> Number {
        return luaL_checknumber(state, arg)
    }
    
    /// If the function argument arg is a number, returns this number as a lua_Number. If this argument is absent or is nil, returns d. Otherwise, raises an error.
    @inline(__always)
    func optNumber(_ arg: Int32, _ def: Number) -> Number {
        return luaL_optnumber(state, arg, def)
    }

    /// Checks whether the function argument arg is an integer (or can be converted to an integer) and returns this integer.
    @inline(__always)
    func checkInteger(_ arg: Int32) -> Integer {
        return luaL_checkinteger(state, arg)
    }
    
    /// If the function argument arg is an integer (or it is convertible to an integer), returns this integer. If this argument is absent or is nil, returns d. Otherwise, raises an error.
    @inline(__always)
    func optInteger(_ arg: Int32, _ def: Integer) -> Integer {
        return luaL_optinteger(state, arg, def)
    }

    /// Grows the stack size to top + sz elements, raising an error if the stack cannot grow to that size. msg is an additional text to go into the error message (or NULL for no additional text).
    @inline(__always)
    func checkStack(_ sz: Int32, _ msg: String) {
        msg.withCString { cString in
            luaL_checkstack(state, sz, cString)
        }
    }
    
    /// Checks whether the function argument arg has type t. See lua_type for the encoding of types for t.
    @inline(__always)
    func checkType(_ arg: Int32, _ t: Int32) {
        luaL_checktype(state, arg, t)
    }
    
    /// Checks whether the function has an argument of any type (including nil) at position arg.
    @inline(__always)
    func checkAny(_ arg: Int32) {
        luaL_checkany(state, arg)
    }

    /// Checks whether the function argument arg is a userdata of the type tname (see luaL_newmetatable) and returns the userdata's memory-block address (see lua_touserdata).
    @inline(__always)
    func newMetaTable(_ tname: UnsafePointer<CChar>!) -> Int32 {
        return luaL_newmetatable(state, tname)
    }
    
    /// Sets the metatable of the object on the top of the stack as the metatable associated with name tname in the registry (see luaL_newmetatable).
    @inline(__always)
    func setMetaTable(_ tname: UnsafePointer<CChar>!) {
        luaL_setmetatable(state, tname)
    }
    
    /// This function works like luaL_checkudata, except that, when the test fails, it returns NULL instead of raising an error.
    @inline(__always)
    func testUData(_ ud: Int32, _ tname: String) -> UnsafeMutableRawPointer? {
        return tname.withCString { cString in
            return luaL_testudata(state, ud, cString)
        }
    }
    
    /// Checks whether the function argument arg is a userdata of the type tname (see luaL_newmetatable) and returns the userdata's memory-block address (see lua_touserdata).
    @inline(__always)
    func checkUData(_ ud: Int32, _ tname: String) -> UnsafeMutableRawPointer! {
        return tname.withCString { cString in
            return luaL_checkudata(state, ud, cString)
        }
    }

    /**
     Pushes onto the stack a string identifying the current position of the control at level lvl in the call stack. Typically this string has the following format:

          chunkname:currentline:
     Level 0 is the running function, level 1 is the function that called the running function, etc.

     This function is used to build a prefix for error messages.
     */
    @inline(__always)
    func `where`(_ lvl: Int32) {
        luaL_where(state, lvl)
    }

    /**
     Checks whether the function argument arg is a string and searches for this string in the array lst (which must be NULL-terminated). Returns the index in the array where the string was found. Raises an error if the argument is not a string or if the string cannot be found.

     If def is not NULL, the function uses def as a default value when there is no argument arg or when this argument is nil.

     This is a useful function for mapping strings to C enums. (The usual convention in Lua libraries is to use strings instead of numbers to select options.)
     */
    @inline(__always)
    func checkOption(_ arg: Int32, _ def: UnsafePointer<CChar>!, _ lst: UnsafePointer<UnsafePointer<CChar>?>!) -> Int32 {
        return luaL_checkoption(state, arg, def, lst)
    }

    /// This function produces the return values for file-related functions in the standard library (io.open, os.rename, file:seek, etc.).
    @inline(__always)
    func fileResult(_ L: OpaquePointer!, _ stat: Int32, _ fname: UnsafePointer<CChar>!) -> Int32 {
        return luaL_fileresult(state, stat, fname)
    }
    
    /// This function produces the return values for process-related functions in the standard library (os.execute and io.close).
    @inline(__always)
    func execResult(_ stat: Int32) -> Int32 {
        return luaL_execresult(state, stat)
    }

    /* predefined references */
    @inline(__always)
    static var noRef: Int32 {LUA_NOREF}
    @inline(__always)
    static var refNil: Int32 {LUA_REFNIL}

    /**
     Creates and returns a reference, in the table at index t, for the object on the top of the stack (and pops the object).

     A reference is a unique integer key. As long as you do not manually add integer keys into the table t, luaL_ref ensures the uniqueness of the key it returns. You can retrieve an object referred by the reference r by calling lua_rawgeti(L, t, r). The function luaL_unref frees a reference.

     If the object on the top of the stack is nil, `ref(_:)` returns the constant `Lua.refNil`. The constant `Lua.noRef` is guaranteed to be different from any reference returned by `ref(_:)`.
     */
    @inline(__always)
    func ref(_ t: Int32) -> Int32 {
        return luaL_ref(state, t)
    }
    
    /**
     Releases the reference ref from the table at index t (see luaL_ref). The entry is removed from the table, so that the referred object can be collected. The reference ref is also freed to be used again.

     If ref is LUA_NOREF or LUA_REFNIL, luaL_unref does nothing.
     */
    @inline(__always)
    func unref(_ t: Int32, _ ref: Int32) {
        luaL_unref(state, t, ref)
    }

    /**
     Loads a file as a Lua chunk. This function uses lua_load to load the chunk in the file named filename. If filename is NULL, then it loads from the standard input. The first line in the file is ignored if it starts with a #.

     The string mode works as in the function lua_load.

     This function returns the same results as lua_load or LUA_ERRFILE for file-related errors.

     As lua_load, this function only loads the chunk; it does not run it.
     */
    @inline(__always)
    func loadFileX(_ filename: String?, _ mode: String?) -> ThreadStatus {
        let filename = filename?.utf8CString
        let filenameP = filename?.withUnsafeBytes({ bufferP in
            return bufferP.baseAddress
        })
        
        let mode = mode?.utf8CString
        let modeP = mode?.withUnsafeBytes({ bufferP in
            return bufferP.baseAddress
        })

        let status = luaL_loadfilex(state, filenameP, modeP)
        return ThreadStatus(rawValue: status)!
    }
    
    /// Equivalent to luaL_loadfilex with mode equal to NULL.
    @inline(__always)
    func loadFile(_ filename: String?) -> ThreadStatus {
        return loadFileX(filename, nil)
    }

    /**
     Loads a buffer as a Lua chunk. This function uses lua_load to load the chunk in the buffer pointed to by buff with size sz.

     This function returns the same results as lua_load. name is the chunk name, used for debug information and error messages. The string mode works as in the function lua_load.
     */
    @inline(__always)
    func loadBufferX(_ buff: String, _ sz: Int, _ name: String, _ mode: String?) -> ThreadStatus {
        let status: Int32 = buff.withCString { buff in
            let mode = mode?.utf8CString
            let modeP = mode?.withUnsafeBytes({ bufferP in
                return bufferP.baseAddress
            })

            return luaL_loadbufferx(state, buff, sz, name, modeP)
        }
        return ThreadStatus(rawValue: status)!
    }
    
    /**
     Similar to load, but gets the chunk from the given string.

     To load and run a given string, use the idiom

          assert(loadstring(s))()
     When absent, chunkname defaults to the given string.
     */
    @inline(__always)
    func loadString(_ s: String) -> ThreadStatus {
        let status = s.withCString { s in
            return luaL_loadstring(state, s)
        }
        return ThreadStatus(rawValue: status)!
    }

    /**
     Creates a new Lua state. It calls lua_newstate with an allocator based on the standard C allocation functions and then sets a warning function and a panic function (see §4.4) that print messages to the standard error output.

     Returns the new state, or NULL if there is a memory allocation error.
     */
    @inline(__always)
    static func newState() -> Lua? {
        if let state = luaL_newstate() {
            return Lua(managedState: state)
        }
        return nil
    }

    /// Returns the "length" of the value at the given index as a number; it is equivalent to the '#' operator in Lua (see §3.4.7). Raises an error if the result of the operation is not an integer. (This case can only happen through metamethods.)
    @inline(__always)
    func len(_ idx: Int32) -> Integer {
        return luaL_len(state, idx)
    }

    /// Adds a copy of the string s to the buffer B (see luaL_Buffer), replacing any occurrence of the string p with the string r.
    @inline(__always)
    static func addgsub(_ b: inout Buffer, _ s: String, _ p: String, _ r: String) {
        s.withCString { s in
            p.withCString { p in
                r.withCString { r in
                    luaL_addgsub(&b, s, p, r)
                }
            }
        }
    }
    
    /// Creates a copy of string s, replacing any occurrence of the string p with the string r. Pushes the resulting string on the stack and returns it.
    @inline(__always)
    func gsub(_ s: String, _ p: String, _ r: String) -> String {
        return s.withCString { s in
            return p.withCString { p in
                return r.withCString { r in
                    let cString = luaL_gsub(state, s, p, r)!
                    return String(cString: cString)
                }
            }
        }
    }

    /**
     Registers all functions in the array l (see luaL_Reg) into the table on the top of the stack (below optional upvalues, see next).

     When nup is not zero, all functions are created with nup upvalues, initialized with copies of the nup values previously pushed on the stack on top of the library table. These values are popped from the stack after the registration.

     A function with a NULL value represents a placeholder, which is filled with false.
     */
    @inline(__always)
    func setFuncs(_ l: [Registration], _ nup: Int32) {
        luaL_setfuncs(state, l, nup)
    }

    /// Ensures that the value t[fname], where t is the value at index idx, is a table, and pushes that table onto the stack. Returns true if it finds a previous table there and false if it creates a new table.
    @inline(__always)
    func getSubTable(_ idx: Int32, _ fname: String) -> Bool {
        return fname.withCString { fname in
            return luaL_getsubtable(state, idx, fname) != 0
        }
    }

    /// Creates and pushes a traceback of the stack L1. If msg is not NULL, it is appended at the beginning of the traceback. The level parameter tells at which level to start the traceback.
    @inline(__always)
    func traceback(_ L1: OpaquePointer!, _ msg: String?, _ level: Int32) {
        let msg = msg?.utf8CString
        let msgP = msg?.withUnsafeBytes({ bufferP in
            return bufferP.baseAddress
        })
        luaL_traceback(state, L1, msgP, level)
    }

    /**
     If package.loaded[modname] is not true, calls the function openf with the string modname as an argument and sets the call result to package.loaded[modname], as if that function has been called through require.

     If glb is true, also stores the module into the global modname.

     Leaves a copy of the module on the stack.
     */
    @inline(__always)
    func requiref(_ modname: String, _ openf: CFunction!, _ glb: Bool) {
        modname.withCString { modname in
            luaL_requiref(state, modname, openf, glb ? 1 : 0)
        }
    }
}
/*
** ===============================================================
** some useful macros
** ===============================================================
*/
public extension Lua {
    /**
     Creates a new table with a size optimized to store all entries in the array l (but does not actually store them). It is intended to be used in conjunction with luaL_setfuncs (see luaL_newlib).

     It is implemented as a macro. The array l must be the actual array, not a pointer to it.
     */
    @inline(__always)
    func newLibTable(_ l: [Registration]) {
        let elementSize = MemoryLayout<Registration>.stride
        let arraySize = elementSize * l.count
        lua_createtable(state, 0, Int32(arraySize / elementSize - 1))
    }
    
    /**
     Creates a new table and registers there the functions in list l.

     It is implemented as the following macro:

          (luaL_newlibtable(L,l), luaL_setfuncs(L,l,0))
     The array l must be the actual array, not a pointer to it.
     */
    @inline(__always)
    func newLib(_ l: [Registration]) {
        checkVersion()
        newLibTable(l)
        setFuncs(l, 0)
    }
    
    /// Checks whether cond is true. If it is not, raises an error with a standard message (see luaL_argerror).
    @inline(__always)
    func argCheck(_ cond: Int32, _ arg: Int32, _ extramsg: String) {
        if cond == 0 {
            extramsg.withCString { cString in
                _ = luaL_argerror(state, arg, cString)
            }
        }
    }
    
    /// Checks whether cond is true. If it is not, raises an error about the type of the argument arg with a standard message (see luaL_typeerror).
    @inline(__always)
    func argExpected(_ cond: Int32, _ arg: Int32, _ tname: String) {
        if cond != 0 {
            tname.withCString { cString in
                _ = luaL_typeerror(state, arg, cString)
            }
        }
    }
    
    /**
     Checks whether the function argument arg is a string and returns this string.

     This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.
     */
    @inline(__always)
    func checkString(_ arg: Int32) -> String {
        let cString = luaL_checklstring(state, arg, nil)!
        return String(cString: cString)
    }
    
    /// If the function argument narg is a string, returns this string. If this argument is absent or is nil, returns d. Otherwise, raises an error.
    @inline(__always)
    func optString(_ arg: Int32?, _ def: String) -> String {
        let arg = arg ?? 0
        return def.withCString { cString in
            let cString = luaL_optlstring(state, arg, cString, nil)!
            return String(cString: cString)
        }
    }
    
    /// Returns the name of the type of the value at the given index.
    @inline(__always)
    func typeName(at idx: Int32) -> String {
        return typeName(type(at: idx))
    }
    
    /**
     Loads and runs the given file.
     
     It is defined as the following macro:
     
          (luaL_loadfile(L, filename) || lua_pcall(L, 0, LUA_MULTRET, 0))
     It returns 0 if there are no errors or 1 in case of errors.
     */
    @inline(__always)
    func doFile(_ fn: String?) -> ThreadStatus {
        let r = loadFile(fn)
        if r == .ok {
            return pcall(0, Lua.multipleReturns, 0)
        }
        return r
    }
    
    /**
     Loads and runs the given string. It is defined as the following macro:

          (luaL_loadstring(L, str) || lua_pcall(L, 0, LUA_MULTRET, 0))
     It returns 0 if there are no errors or 1 in case of errors.
     */
    @inline(__always)
    func doString(_ s: String) -> ThreadStatus {
        let r = loadString(s)
        if r == .ok {
            return pcall(0, Lua.multipleReturns, 0)
        }
        return r
    }
    
    /// Pushes onto the stack the metatable associated with name tname in the registry (see luaL_newmetatable).
    @inline(__always)
    func getMetaTable(_ n: String) {
        _ = getField(at: Lua.registryIndex, n)
    }
    
    /**
     This macro is defined as follows:

          (lua_isnoneornil(L,(arg)) ? (dflt) : func(L,(arg)))
     In words, if the argument arg is nil or absent, the macro results in the default dflt. Otherwise, it results in the result of calling func with the state L and the argument index arg as arguments. Note that it evaluates the expression dflt only if needed.
     */
    @inline(__always) @available(*, unavailable, message: "This C macro cannot be represented in Swift.")
    func opt(_ func: Any, _ arg: Any, _ dflt: Any) -> Any? {
        fatalError()
    }
    
    /// Equivalent to luaL_loadbufferx with mode equal to NULL.
    @inline(__always)
    func loadBuffer(_ buff: String, _ sz: Int, _ name: String) -> ThreadStatus {
        return loadBufferX(buff, sz, name, nil)
    }
    
    /// Perform arithmetic operations on lua_Integer values with wrap-around semantics, as the Lua core does.
    @inline(__always) @available(*, unavailable, message: "This C macro cannot be represented in Swift.")
    func intOp(_ op: Any, _ v1: Integer, _ v2: Integer) -> Integer {
        fatalError()
    }
    
    /// Pushes the fail value onto the stack (see §6).
    @inline(__always)
    func pushFail() {
        pushNil()
    }
}

/*
** {======================================================
** Generic Buffer manipulation
** =======================================================
*/

public extension Lua {
    typealias Buffer = luaL_Buffer
    
    /// Returns the length of the current content of buffer B (see luaL_Buffer).
    @inline(__always)
    func bufferLen(_ B: Buffer) -> Int {
        return B.n
    }
    
    /// Returns the address of the current content of buffer B (see luaL_Buffer). Note that any addition to the buffer may invalidate this address.
    @inline(__always)
    func bufferAddr(_ B: Buffer) -> UnsafeMutablePointer<CChar>! {
        return B.b
    }

    /// Adds the byte c to the buffer B (see luaL_Buffer).
    @inline(__always)
    func addChar(_ B: inout Buffer, _ c: CChar) {
        if B.n < B.size {
            _ = prepBuffSize(&B, 1)
        }
        B.n += 1
        B.b[B.n] = c
    }
    
    /// Adds to the buffer B a string of length n previously copied to the buffer area (see luaL_prepbuffer).
    @inline(__always)
    func addSize(_ B: inout Buffer, _ s: Int) {
        B.n += s
    }
    
    /// Removes n bytes from the the buffer B (see luaL_Buffer). The buffer must have at least that many bytes.
    @inline(__always)
    func buffSub(_ B: inout Buffer, _ s: Int) {
        B.n -= s
    }
    
    /// Initializes a buffer B (see luaL_Buffer). This function does not allocate any space; the buffer must be declared as a variable.
    @inline(__always)
    func buffInit(_ B: inout Buffer) {
        luaL_buffinit(state, &B)
    }
    
    /// Returns an address to a space of size sz where you can copy a string to be added to buffer B (see luaL_Buffer). After copying the string into this space you must call luaL_addsize with the size of the string to actually add it to the buffer.
    @inline(__always)
    func prepBuffSize(_ B: inout Buffer, _ sz: Int) -> UnsafeMutablePointer<CChar>! {
        return luaL_prepbuffsize(&B, sz)
    }
    
    /// Adds the string pointed to by s with length l to the buffer B (see luaL_Buffer). The string can contain embedded zeros.
    @inline(__always)
    func addLString(_ B: inout Buffer, _ s: String) {
        s.withCString { cString in
            luaL_addlstring(&B, cString, s.utf8.count)
        }
    }
    
    /// Adds the zero-terminated string pointed to by s to the buffer B (see luaL_Buffer).
    @inline(__always)
    func addString(_ B: inout Buffer, _ s: UnsafePointer<CChar>!) {
        luaL_addstring(&B, s)
    }
    
    /**
     Adds the value on the top of the stack to the buffer B (see luaL_Buffer). Pops the value.

     This is the only function on string buffers that can (and must) be called with an extra element on the stack, which is the value to be added to the buffer.
     */
    @inline(__always)
    func addValue(_ B: inout Buffer) {
        luaL_addvalue(&B)
    }
    
    /// Finishes the use of buffer B leaving the final string on the top of the stack.
    @inline(__always)
    func pushResult(_ B: inout Buffer) {
        luaL_pushresult(&B)
    }
    
    /// Equivalent to the sequence luaL_addsize, luaL_pushresult.
    @inline(__always)
    func pushResultSize(_ B: inout Buffer, _ sz: Int) {
        luaL_pushresultsize(&B, sz)
    }
    
    /// Equivalent to the sequence luaL_buffinit, luaL_prepbuffsize.
    @inline(__always)
    func buffInitSize(_ B: inout Buffer, _ sz: Int) -> UnsafeMutablePointer<CChar>! {
        luaL_buffinitsize(state, &B, sz)
    }
    
    /// Equivalent to luaL_prepbuffsize with the predefined size LUAL_BUFFERSIZE.
    @inline(__always)
    func prepBuffer(_ B: inout Buffer) -> UnsafeMutablePointer<CChar>! {
        let LUAL_BUFFERSIZE = Int(16 * MemoryLayout<UnsafeRawPointer>.stride * MemoryLayout<Number>.stride)
        return prepBuffSize(&B, LUAL_BUFFERSIZE)
    }
}



/* }====================================================== */

/*
** {======================================================
** File handles for IO library
** =======================================================
*/

/*
** A file handle is a userdata with metatable 'LUA_FILEHANDLE' and
** initial structure 'luaL_Stream' (it may contain other fields
** after that initial structure).
*/
public extension Lua {
    @inline(__always)
    static var fileHandle: String {LUA_FILEHANDLE}
}
