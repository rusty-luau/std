--!nolint LocalUnused

local trait = require("../../../src/std/trait")

-- A trait, defined the convention way: the `Requires` / `Defaults` / `For`
-- triple, and `define` with no turbofish.
type DisplayRequires<Self> = {
    display: (self: Self) -> string;
}

local display_defaults = {}

-- Default method: `self` is `DisplayFor<Self>` because the body calls a trait
-- method (`self:display()`).
function display_defaults.print_display<Self>(self: DisplayFor<Self>): ()
    print(self:display())
end

type DisplayDefaults = typeof(display_defaults)
type DisplayFor<Self> = DisplayRequires<Self> & DisplayDefaults

local Display = trait.define(display_defaults)

-- `define` infers `D` from the defaults table; the result is `Trait<D>`.
local display_trait: trait.Trait<DisplayDefaults> = Display

-- An implementer, built the convention way: a method table whose name doubles
-- as the type name, `__index :: {}`, public type
-- `setmetatable<...> & Trait.For<...>`, and a constructor ending in `:: T`.
local Point = {}
local PointPrototype = table.freeze({
    __index = Point :: {};
})

function Point.display(self: Point): string
    return `({ self.x }, { self.y })`
end

trait.impl<<typeof(Point), DisplayRequires<Point>>>(Point, Display)

type Point = setmetatable<{
    read x: number;
    read y: number;
}, typeof(PointPrototype)> & DisplayFor<Point>

local function new_point(x: number, y: number): Point
    return table.freeze(setmetatable({
        x = x;
        y = y;
    }, PointPrototype)) :: Point
end

-- The implementer exposes both the required method and the copied-in default
-- method off its single public type.
local origin: Point = new_point(0, 0)
local _origin_display: string = origin:display()
origin:print_display()

-- A class missing the required `display` is not assignable to `M & Requires`,
-- so the `impl` call would be a type error:
local bad_methods = {}
function bad_methods.unrelated(self: typeof(bad_methods)): number
    return 0
end

-- trait.impl<<typeof(bad_methods), DisplayRequires<typeof(bad_methods)>>>(bad_methods, Display) -- should error

-- A wrongly-typed required method (returns `number`, not `string`) fails the
-- same contract check:
local wrong_methods = {}
function wrong_methods.display(self: typeof(wrong_methods)): number
    return 0
end

-- trait.impl<<typeof(wrong_methods), DisplayRequires<typeof(wrong_methods)>>>(wrong_methods, Display) -- should error
