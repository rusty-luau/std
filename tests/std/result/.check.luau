--!nolint LocalUnused

local Result = require("../../../src/std/result")

local ok_1 = Result.ok(1)
local ok_2: Result.Ok<number>

ok_2 = ok_1

local err_1 = Result.err("error")
local err_2: Result.Err<string>

err_2 = err_1

-- ok_2 = err_1 -- should error
-- err_2 = ok_1 -- should error

local res: Result.Result<number, string>
res = ok_1
res = err_1

local res_2: Result.Result<number, string>

-- ok_2 = res_2 -- should error
-- err_2 = res_2 -- should error

local function do_nothing<T>(res: T & (Result.Result<any, any>)): T
    return res
end

local ok: Result.Ok<number> = do_nothing(ok_1)
local err: Result.Err<string> = do_nothing(err_1)

-- do_nothing(1) -- should error