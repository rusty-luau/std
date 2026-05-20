local Alignment = {}
local AlignmentPrototype = table.freeze({
    __index = Alignment;
})

export type Alignment = setmetatable<{}, typeof(AlignmentPrototype)>

local LEFT = table.freeze(setmetatable({}, AlignmentPrototype))
local RIGHT = table.freeze(setmetatable({}, AlignmentPrototype))
local CENTER = table.freeze(setmetatable({}, AlignmentPrototype))

--- Returns Left Alignment
local function left(): Alignment
    return LEFT
end

--- Returns Right Alignment
local function right(): Alignment
    return RIGHT
end

--- Returns Center Alignment
local function center(): Alignment
    return CENTER
end

--- Enum Alignment
return table.freeze({
    left = left;
    right = right;
    center = center;
})