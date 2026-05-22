--!nolint LocalUnused

local Option = require("../../../src/std/option")

local some_1 = Option.some(1)
local some_2: Option.Some<number>

some_2 = some_1

local none_1 = Option.none()
local none_2: Option.None

none_2 = none_1

-- `None = Option<never>` is a subtype of every `Some<T>` (via `never <: T`):
some_2 = none_1

-- Conversely, `Some<T>` is NOT a subtype of `None` (would require `T <: never`):
-- none_2 = some_1 -- should error

local opt: Option.Option<number>
opt = some_1
opt = none_1

local opt_2: Option.Option<number>

-- A generic `Option<T>` is not assignable to `None` either:
-- none_2 = opt_2 -- should error

local function do_nothing<T>(opt: T & (Option.Option<any>)): T
    return opt
end

local some: Option.Some<number> = do_nothing(some_1)
local none: Option.None = do_nothing(none_1)

-- do_nothing(1) -- should error

local some_or_none = Option.from(nil)
-- some = some_or_none -- should error
-- none = some_or_none -- should error