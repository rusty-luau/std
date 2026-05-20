local Error = {}
local ErrorPrototype = table.freeze({
    __index = Error;
})

export type Error = setmetatable<{}, typeof(ErrorPrototype)>

local ERROR = table.freeze(setmetatable({}, ErrorPrototype))

--- Returns error.
local function new(): Error
    return ERROR
end

--- Enum Error
return table.freeze({
    new = new;
})