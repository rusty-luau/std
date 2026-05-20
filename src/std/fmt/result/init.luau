--[[

    Type Alias Result

]]

local Result = require("../result")

local Error = require("./error")

export type Result = Result.Result<nil, Error.Error>
export type Ok = Result.Result<nil, never>
export type Err = Result.Result<never, Error.Error>

local OK = Result.ok(nil)
local ERR = Result.err(Error.new())

--- Returns `Ok<nil>` Result.
local function ok(): Ok
    return OK
end

--- Returns `Err<fmt::Error>` Result.
local function err(): Err
    return ERR
end

--- Enum fmt::result
return table.freeze({
    ok = ok;
    err = err;
})