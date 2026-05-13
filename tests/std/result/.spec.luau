local test = require("@std/test")

local Result = require("../../../src/std/result")

test.suite("std.result", function(suite)
    suite:case(".ok", function(asserts)
        local res = Result.ok(42)

        asserts.eq(res:is_ok(), true)
        asserts.eq(res:is_err(), false)
        asserts.eq(res:unwrap(), 42)
    end)

    suite:case(".err", function(asserts)
        local res = Result.err("error")

        asserts.eq(res:is_ok(), false)
        asserts.eq(res:is_err(), true)
        asserts.eq(res:unwrap_err(), "error")
    end)

    suite:case(".is", function(asserts)
        asserts.eq(Result.is(Result.ok(1)), true)
        asserts.eq(Result.is(Result.err("e")), true)
        asserts.eq(Result.is({}), false)
        asserts.eq(Result.is(nil), false)
        asserts.eq(Result.is(42), false)
        asserts.eq(Result.is("ok"), false)
    end)

    suite:case(":is_ok_and", function(asserts)
        local even = function(n: number) return n % 2 == 0 end

        asserts.eq(Result.ok(2):is_ok_and(even), true)
        asserts.eq(Result.ok(3):is_ok_and(even), false)
        asserts.eq((Result.err("e")):is_ok_and(even), false)
    end)

    suite:case(":is_err_and", function(asserts)
        local isNotFound = function(e: string) return e == "not_found" end

        asserts.eq(Result.err("not_found"):is_err_and(isNotFound), true)
        asserts.eq(Result.err("other"):is_err_and(isNotFound), false)
        asserts.eq((Result.ok(1)):is_err_and(isNotFound), false)
    end)

    suite:case(":map on Ok applies the function", function(asserts)
        local res = Result.ok(2):map(function(n: number) return n * 10 end)

        asserts.eq(res:is_ok(), true)
        asserts.eq(res:unwrap(), 20)
    end)

    suite:case(":map on Err passes through", function(asserts)
        local res = Result.err("e"):map(function(n: number) return n * 10 end)

        asserts.eq(res:is_err(), true)
        asserts.eq(res:unwrap_err(), "e")
    end)

    suite:case(":map_or", function(asserts)
        local double = function(n: number) return n * 2 end

        asserts.eq(Result.ok(5):map_or(0, double), 10)
        asserts.eq(Result.err("e"):map_or(0, double), 0)
    end)

    suite:case(":map_or_else", function(asserts)
        local fallback = function(e: string) return #e end
        local double = function(n: number) return n * 2 end

        asserts.eq(Result.ok(5):map_or_else(fallback, double), 10)
        asserts.eq(Result.err("oops"):map_or_else(fallback, double), 4)
    end)

    suite:case(":map_err on Err applies the function", function(asserts)
        local res = Result.err("bad"):map_err(function(e) return `wrapped:{e}` end)

        asserts.eq(res:is_err(), true)
        asserts.eq(res:unwrap_err(), "wrapped:bad")
    end)

    suite:case(":map_err on Ok passes through", function(asserts)
        local res = Result.ok(1):map_err(function(e: string) return `wrapped:{e}` end)

        asserts.eq(res:is_ok(), true)
        asserts.eq(res:unwrap(), 1)
    end)

    suite:case(":inspect runs the closure only on Ok and returns self", function(asserts)
        local seen: number? = nil
        local original = Result.ok(7)
        local returned = original:inspect(function(v) seen = v end)

        asserts.eq(seen, 7)
        asserts.eq(returned, original)

        seen = nil
        local errOriginal = Result.err("e")
        local errReturned = errOriginal:inspect(function(v) seen = v end)

        asserts.eq(seen, nil)
        asserts.eq(errReturned, errOriginal)
    end)

    suite:case(":inspect_err runs the closure only on Err and returns self", function(asserts)
        local seen: string? = nil
        local original = Result.err("boom")
        local returned = original:inspect_err(function(e) seen = e end)

        asserts.eq(seen, "boom")
        asserts.eq(returned, original)

        seen = nil
        local okOriginal = Result.ok(1)
        local okReturned = okOriginal:inspect_err(function(e) seen = e end)

        asserts.eq(seen, nil)
        asserts.eq(okReturned, okOriginal)
    end)

    suite:case(":expect returns value on Ok", function(asserts)
        asserts.eq(Result.ok(42):expect("should not panic"), 42)
    end)

    suite:case(":expect throws with the given message on Err", function(asserts)
        asserts.throwsWith("boom", function()
            Result.err("inner"):expect("boom")
        end)
    end)

    suite:case(":unwrap returns value on Ok", function(asserts)
        asserts.eq(Result.ok("hello"):unwrap(), "hello")
    end)

    suite:case(":unwrap throws with the inner error on Err", function(asserts)
        asserts.throwsWith("inner error", function()
            Result.err("inner error"):unwrap()
        end)
    end)

    suite:case(":expect_err returns error on Err", function(asserts)
        asserts.eq(Result.err("e"):expect_err("should not panic"), "e")
    end)

    suite:case(":expect_err throws with the given message on Ok", function(asserts)
        asserts.throwsWith("expected err", function()
            Result.ok(1):expect_err("expected err")
        end)
    end)

    suite:case(":unwrap_err returns error on Err", function(asserts)
        asserts.eq(Result.err("oops"):unwrap_err(), "oops")
    end)

    suite:case(":unwrap_err throws with the inner value on Ok", function(asserts)
        asserts.throwsWith("inner value", function()
            Result.ok("inner value"):unwrap_err()
        end)
    end)

    suite:case(":and_res", function(asserts)
        local later = Result.ok(99)

        asserts.eq(Result.ok(1):and_res(later):unwrap(), 99)

        local errSelf = Result.err("first")
        local andResult = errSelf:and_res(later)
        asserts.eq(andResult:is_err(), true)
        asserts.eq(andResult:unwrap_err(), "first")
    end)

    suite:case(":and_then chains on Ok and passes through on Err", function(asserts)
        local sqrtOrErr = function(n: number): Result.Result<number, string>
            if n < 0 then return Result.err("negative") end
            return Result.ok(math.sqrt(n))
        end

        local okChain = Result.ok(16):and_then(sqrtOrErr)
        asserts.eq(okChain:unwrap(), 4)

        local errChain = Result.ok(-1):and_then(sqrtOrErr)
        asserts.eq(errChain:unwrap_err(), "negative")

        local passthrough = Result.err("first"):and_then(sqrtOrErr)
        asserts.eq(passthrough:unwrap_err(), "first")
    end)

    suite:case(":or_res", function(asserts)
        local fallback = Result.ok(99)

        asserts.eq(Result.ok(1):or_res(fallback):unwrap(), 1)

        local errSelf = Result.err("first")
        asserts.eq(errSelf:or_res(fallback):unwrap(), 99)
    end)

    suite:case(":or_else chains on Err and passes through on Ok", function(asserts)
        local recover = function(e: string): Result.Result<number, string>
            if e == "recoverable" then return Result.ok(0) end
            return Result.err(`fatal:{e}`)
        end

        local errChain = (Result.err("recoverable")):or_else(recover)
        asserts.eq(errChain:unwrap(), 0)

        local errChain2 = (Result.err("bad")):or_else(recover)
        asserts.eq(errChain2:unwrap_err(), "fatal:bad")

        local passthrough = Result.ok(7):or_else(recover)
        asserts.eq(passthrough:unwrap(), 7)
    end)

    suite:case(":unwrap_or", function(asserts)
        asserts.eq(Result.ok(1):unwrap_or(99), 1)
        asserts.eq((Result.err("e")):unwrap_or(99), 99)
    end)

    suite:case(":unwrap_or_else", function(asserts)
        local recover = function(e: string) return #e end

        asserts.eq(Result.ok(1):unwrap_or_else(recover), 1)
        asserts.eq((Result.err("hello")):unwrap_or_else(recover), 5)
    end)

    suite:case(":unwrap_unchecked returns the inner value on Ok", function(asserts)
        asserts.eq(Result.ok(42):unwrap_unchecked(), 42)
    end)

    suite:case(":unwrap_err_unchecked returns the inner error on Err", function(asserts)
        asserts.eq(Result.err("e"):unwrap_err_unchecked(), "e")
    end)

    suite:case("instances are frozen", function(asserts)
        local res = Result.ok(1)
        asserts.eq(table.isfrozen(res), true)
    end)
end)

return nil