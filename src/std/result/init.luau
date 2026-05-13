local Result = {}
local ResultPrototype = table.freeze({
    __index = Result;
})

export type Result<T, E> = setmetatable<{
    read _ok: true | false;
    read _value: T;
    read _err: E;
}, typeof(ResultPrototype)>

export type Ok<T> = Result<T, never>
export type Err<E> = Result<never, E>

--- Checks if the given value is a Result.
local function is(value: unknown): boolean
    return type(value) == "table" and getmetatable(value) == ResultPrototype
end

--- Constructs a new `Ok` Result.
local function ok<T>(value: T): Ok<T>
    return table.freeze(setmetatable({
        _ok = true :: true;
        _value = value;
        _err = nil :: never;
    }, ResultPrototype))
end

--- Constructs a new `Err` Result.
local function err<E>(err: E): Err<E>
    return table.freeze(setmetatable({
        _ok = false :: false;
        _value = nil :: never;
        _err = err;
    }, ResultPrototype))
end

--- Returns `true` if the result is `Ok`.
function Result.is_ok<T, E>(self: Result<T, E>): boolean
    return self._ok
end

--- Returns `true` if the result is `Ok` and the value inside of it matches a predicate.
function Result.is_ok_and<T, E>(self: Result<T, E>, f: (T) -> boolean): boolean
    if self._ok then
        return f(self._value)
    end

    return false
end

--- Returns `true` if the result is `Err`.
function Result.is_err<T, E>(self: Result<T, E>): boolean
    return not self._ok
end

--- Returns `true` if the result is `Err` and the value inside of it matches a predicate.
function Result.is_err_and<T, E>(self: Result<T, E>, f: (E) -> boolean): boolean
    if not self._ok then
        return f(self._err)
    end

    return false
end

--- Maps a `Result<T, E>` to `Result<U, E>` by applying a function to a contained `Ok` value, leaving an `Err` value untouched.
--- this function can be used to compose the result of two functions.
function Result.map<T, E, U>(self: Result<T, E>, op: (T) -> U): Result<U, E>
    if not self._ok then
        return self
    end

    return ok(op(self._value))
end

--- Returns the provided default (if `Err`), or applies a function to the contained value (if `Ok`).
--- Arguments passed to `map_or` are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `map_or_else`, which is lazily evaluated.
function Result.map_or<T, E, U>(self: Result<T, E>, default: U, op: (T) -> U): U
    if not self._ok then
        return default
    end

    return op(self._value)
end

--- Maps a `Result<T, E>` to `U` by applying fallback function `default` to a contained `Err` value, or function `f` to a contained `Ok` value.
--- this function can be used to unpack a successful result while handling an error.
function Result.map_or_else<T, E, U>(self: Result<T, E>, default: (E) -> U, f: (T) -> U): U
    if self._ok then
        return f(self._value)
    end

    return default(self._err)
end

--- Maps a `Result<T, E>` to `Result<T, F>` by applying a function to a contained `Err` value, leaving an `Ok` value untouched.
--- This function can be used to pass through a successful result while handling an error.
function Result.map_err<T, E, F>(self: Result<T, E>, op: (E) -> F): Result<T, F>
    if self._ok then
        return self
    end

    return err(op(self._err))
end

--- Calls a function with the contained value if `Ok`, then returns the original result.
function Result.inspect<T, E>(self: Result<T, E>, f: (T) -> ()): Result<T, E>
    if self._ok then
        f(self._value)
    end

    return self
end

--- Calls a function with the contained error if `Err`, then returns the original result.
function Result.inspect_err<T, E>(self: Result<T, E>, f: (E) -> ()): Result<T, E>
    if not self._ok then
        f(self._err)
    end

    return self
end

--- Returns the contained `Ok` value, consuming the `self` value.
--- Because this function may panic, its use is generally discouraged. Instead, prefer to use pattern matching and handle the `Err` case explicitly, or call `unwrap_or`, or `unwrap_or_else`.
--- Panics if the value is an `Err`, with a panic message including the passed message, and the content of the `Err`.
function Result.expect<T, E>(self: Result<T, E>, msg: string): T
    if not self._ok then
        error(msg, 2)
    end

    return self._value
end

--- Returns the contained `Ok` value, consuming the `self` value.
--- Because this function may panic, its use is generally discouraged. Panics are meant for unrecoverable errors, and _may abort the entire program._
--- Instead, prefer pattern matching to handle the `Err` case explicitly, or call `unwrap_or`, or `unwrap_or_else`.
--- Panics if the value is an `Err`, with a panic message provided by the `Err`'s value.
function Result.unwrap<T, E>(self: Result<T, E>): T
    if not self._ok then
        error(self._err, 2)
    end

    return self._value
end

--- Returns the contained `Err` value, consuming the `self` value.
--- Panics if the value is an `Ok`, with a panic message including the passed message, and the content of the `Ok`.
function Result.expect_err<T, E>(self: Result<T, E>, msg: string): E
    if self._ok then
        error(msg, 2)
    end

    return self._err
end

--- Returns the contained `Err` value, consuming the `self` value.
--- Panics if the value is an `Ok`, with a custom panic message provided by the `Ok`'s value.
function Result.unwrap_err<T, E>(self: Result<T, E>): E
    if self._ok then
        error(self._value, 2)
    end

    return self._err
end

--- Returns `res` if the result is `Ok`, otherwise returns the `Err` value of `self`.
--- Arguments passed to `and_res` are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `and_then`, which is lazily evaluated.
function Result.and_res<T, E, U>(self: Result<T, E>, res: Result<U, E>): Result<U, E>
    if self._ok then
        return res
    end

    return self
end

--- Calls `op` if the result is `Ok`, otherwise returns the `Err` value of `self`.
--- This function can be used for control flow based on `Result` values.
function Result.and_then<T, E, U>(self: Result<T, E>, op: (T) -> Result<U, E>): Result<U, E>
    if self._ok then
        return op(self._value)
    end

    return self
end

--- Returns `res` if the result is `Err`, otherwise returns the `Ok` value of `self`.
--- Arguments passed to `or_res` are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `or_else`, which is lazily evaluated.
function Result.or_res<T, E, F>(self: Result<T, E>, res: Result<T, F>): Result<T, F>
    if not self._ok then
        return res
    end

    return self
end

--- Call `op` if the result is `Err`, otherwise returns the `Ok` value of `self`.
--- this function can be used for control flow based on result values.
function Result.or_else<T, E, F>(self: Result<T, E>, op: (E) -> Result<T, F>): Result<T, F>
    if not self._ok then
        return op(self._err)
    end

    return self
end

--- Returns the contained `Ok` value or a provided default.
--- Arguments passed to `unwrap_or` are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `unwrap_or_else`, which is lazily evaluated.
function Result.unwrap_or<T, E>(self: Result<T, E>, default: T): T
    if self._ok then
        return self._value
    end

    return default
end

--- Returns the contained `Ok` value or computes it from a closure.
function Result.unwrap_or_else<T, E>(self: Result<T, E>, op: (E) -> T): T
    if self._ok then
        return self._value
    end

    return op(self._err)
end

--- Returns the contained `Ok` value, consuming the `self` value, without checking that the value is not an `Err`.
--- Calling this method on an `Err` is _undefined behavior_.
function Result.unwrap_unchecked<T, E>(self: Result<T, E>): T
    return self._value
end

--- Returns the contained `Err` value, consuming the `self` value, without checking the value is not an `Ok`.
--- calling this method on an `Ok`. is _undefined behavior_.
function Result.unwrap_err_unchecked<T, E>(self: Result<T, E>): E
    return self._err
end

--- Class Result
return {
    is = is;
    ok = ok;
    err = err;
}