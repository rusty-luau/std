local Option = {}
local OptionPrototype = table.freeze({
    __index = Option;
})

export type Option<T> = setmetatable<{
    read _is_some: true | false;
    read _value: T;
}, typeof(OptionPrototype)>

export type Some<T> = Option<T>
export type None<T = never> = Option<T>

local NONE: None = table.freeze(setmetatable({
    _is_some = false :: false;
    _value = nil :: never;
}, OptionPrototype))

--- Checks if the given value is an Option.
local function is(value: unknown): boolean
    return type(value) == "table" and getmetatable(value) == OptionPrototype
end

--- Constructs a new Some value containing the given value.
local function some<T>(value: T): Some<T>
    return table.freeze(setmetatable({
        _is_some = true :: true;
        _value = value;
    }, OptionPrototype))
end

--- Constructs a new None value.
local function none(): None
    return NONE
end

--- Constructs a new `None` value if the given value is `nil`, Otherwise returns `Some<T>`.
local function from<T>(value: T?): Some<T> | None
    return
        if value ~= nil
            then some(value)
            else NONE
end

--- Returns `true` if the option is a `Some` value.
function Option.is_some<T>(self: Option<T>): boolean
    return self._is_some
end

--- Returns `true` if the option is a `Some` value and the value inside of it matches a predicate.
function Option.is_some_and<T>(self: Option<T>, f: (T) -> boolean): boolean
    return self._is_some and f(self._value)
end

--- Returns `true` if the option is a `None` value.
function Option.is_none<T>(self: Option<T>): boolean
    return not self._is_some
end

--- Returns `true` if the option is a `None` value or the value inside of it matches a predicate.
function Option.is_none_or<T>(self: Option<T>, f: (T) -> boolean): boolean
    return not self._is_some or f(self._value)
end

--- Returns the contained `Some` value, consuming the `self` value.
--- Panics if the value is a `None`, with a panic message provided by `msg`.
function Option.expect<T>(self: Option<T>, msg: string): T
    if not self._is_some then
        error(msg, 2)
    end

    return self._value
end

--- Returns the contained `Some` value, consuming the `self` value.
--- Because this function may panic, its use is generally discouraged. Panics are meant for unrecoverable errors, and may abort the entire program.
--- Instead, prefer to use pattern matching and handle the `None` case explicitly, or call `unwrap_or`, or `unwrap_or_else`.
--- Panics if the self value equals `None`.
function Option.unwrap<T>(self: Option<T>): T
    if not self._is_some then
        error("called `Option.unwrap()` on a `None` value", 2)
    end

    return self._value
end

--- Returns the contained `Some` value or a provided default.
--- Arguments passed to `unwrap_or` are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `unwrap_or_else`, which is lazily evaluated.
function Option.unwrap_or<T>(self: Option<T>, default: T): T
    if self._is_some then
        return self._value
    end

    return default
end

--- Returns the contained `Some` value or computes it from a closure.
function Option.unwrap_or_else<T>(self: Option<T>, f: () -> T): T
    if self._is_some then
        return self._value
    end

    return f()
end

--- Returns the contained `Some` value, consuming the `self` value, without checking that the value is not `None`.
--- Calling this method on a `None` value is _undefined behavior_.
function Option.unwrap_unchecked<T>(self: Option<T>): T
    return self._value
end

--- Maps an `Option<T>` to `Option<U>` by applying a function to a contained `Some` value (if `Some`) or returns `None` (if `None`).
function Option.map<T, U>(self: Option<T>, f: (T) -> U): Option<U>
    if self._is_some then
        return some(f(self._value))
    end

    return none()
end

--- Calls a function with the contained value if `Some`, then returns the original option.
function Option.inspect<T>(self: Option<T>, f: (T) -> ()): Option<T>
    if self._is_some then
        f(self._value)
    end

    return self
end

--- Returns the provided default result (if none), or applies a function to the contained value (if any).
--- Arguments passed to `map_or` are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `map_or_else`, which is lazily evaluated.
function Option.map_or<T, U>(self: Option<T>, default: U, f: (T) -> U): U
    if self._is_some then
        return f(self._value)
    end

    return default
end

--- Computes a default result (if none), or applies a different function to the contained value (if any).
function Option.map_or_else<T, U>(self: Option<T>, default: () -> U, f: (T) -> U): U
    if self._is_some then
        return f(self._value)
    end

    return default()
end

--- Returns `None` if the option is `None`, otherwise returns `optb`.
--- Arguments passed to `and_opt` are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `and_then`, which is lazily evaluated.
function Option.and_opt<T, U>(self: Option<T>, optb: Option<U>): Option<U>
    if self._is_some then
        return optb
    end

    return none()
end

--- Returns `None` if the option is `None`, otherwise calls `f` with the wrapped value and returns the result.
--- Some languages call this operation `flat_map`.
function Option.and_then<T, U>(self: Option<T>, f: (T) -> Option<U>): Option<U>
    if self._is_some then
        return f(self._value)
    end

    return none()
end

--- Returns `None` if the option is `None`, otherwise calls `predicate` with the wrapped value and returns:
--- - `Some(t)` if the `predicate` returns `true` (where `t` is the wrapped value), and
--- - `None` if the `predicate` returns `false`.
function Option.filter<T>(self: Option<T>, predicate: (T) -> boolean): Option<T>
    if self._is_some and predicate(self._value) then
        return self
    end

    return none()
end

--- Returns the option if it contains a value, otherwise returns `optb`.
--- Arguments passed to `or_opt` are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `or_else`, which is lazily evaluated.
function Option.or_opt<T>(self: Option<T>, optb: Option<T>): Option<T>
    if self._is_some then
        return self
    end

    return optb
end

--- Returns the option if it contains a value, otherwise calls `f` and returns the result.
function Option.or_else<T>(self: Option<T>, f: () -> Option<T>): Option<T>
    if self._is_some then
        return self
    end

    return f()
end

--- Returns `Some` if exactly one of `self`, `optb` contains a value, otherwise returns `None`.
function Option.xor<T>(self: Option<T>, optb: Option<T>): Option<T>
    if self._is_some ~= optb._is_some then
        if self._is_some then
            return self
        else
            return optb
        end
    end

    return none()
end

--- Class Option
return {
    is = is;
    some = some;
    none = none;
    from = from;
}