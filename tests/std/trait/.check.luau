--!nolint LocalUnused

local trait = require("../../../src/std/trait")

--- A trait for the type-level checks below.
type DisplayRequires<Self> = {
    display: (self: Self) -> string;
}

local display_defaults = {}

function display_defaults.print_display<Self>(self: Self & DisplayRequires<Self>): ()
    print(self:display())
end

type DisplayDefaults = typeof(display_defaults)

local Display = trait.define(display_defaults)

-- `define` infers `D` from the defaults table.
local display_trait: trait.Trait<DisplayDefaults> = Display

-- A correct implementer: `point_methods` satisfies `DisplayRequires`.
local point_methods = {}

function point_methods.display(self: any): string
    return "(point)"
end

-- This call typechecks: `point_methods` satisfies the `DisplayRequires`
-- contract, so the required-method check passes.
trait.impl<<typeof(point_methods), DisplayRequires<typeof(point_methods)>>>(point_methods, Display)

-- A class missing the required `display` is not assignable to `M & Requires`,
-- so the `impl` call is a type error:
local bad_methods = {}
function bad_methods.unrelated(self: any): number
    return 0
end

-- trait.impl<<typeof(bad_methods), DisplayRequires<typeof(bad_methods)>>>(bad_methods, Display) -- should error

-- A wrongly-typed required method (returns `number`, not `string`) fails the
-- same contract check:
local wrong_methods = {}
function wrong_methods.display(self: any): number
    return 0
end

-- trait.impl<<typeof(wrong_methods), DisplayRequires<typeof(wrong_methods)>>>(wrong_methods, Display) -- should error
