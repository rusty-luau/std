local test = require("@std/test")

local Option = require("../../../src/std/option")

test.suite("std.option", function(suite)
    suite:case(".some", function(asserts)
        local opt = Option.some(42)

        asserts.eq(opt:is_some(), true)
        asserts.eq(opt:is_none(), false)
        asserts.eq(opt:unwrap(), 42)
    end)

    suite:case(".none", function(asserts)
        local opt = Option.none()

        asserts.eq(opt:is_some(), false)
        asserts.eq(opt:is_none(), true)
    end)

    suite:case(".is", function(asserts)
        asserts.eq(Option.is(Option.some(1)), true)
        asserts.eq(Option.is(Option.none()), true)
        asserts.eq(Option.is({}), false)
        asserts.eq(Option.is(nil), false)
        asserts.eq(Option.is(42), false)
        asserts.eq(Option.is("some"), false)
    end)

    suite:case(":is_some_and", function(asserts)
        local even = function(n: number) return n % 2 == 0 end

        asserts.eq(Option.some(2):is_some_and(even), true)
        asserts.eq(Option.some(3):is_some_and(even), false)
        asserts.eq(Option.none():is_some_and(even), false)
    end)

    suite:case(":is_none_or", function(asserts)
        local even = function(n: number) return n % 2 == 0 end

        asserts.eq(Option.none():is_none_or(even), true)
        asserts.eq(Option.some(2):is_none_or(even), true)
        asserts.eq(Option.some(3):is_none_or(even), false)
    end)

    suite:case(":expect returns value on Some", function(asserts)
        asserts.eq(Option.some(42):expect("should not panic"), 42)
    end)

    suite:case(":expect throws with the given message on None", function(asserts)
        asserts.throwsWith("boom", function()
            Option.none():expect("boom")
        end)
    end)

    suite:case(":unwrap returns value on Some", function(asserts)
        asserts.eq(Option.some("hello"):unwrap(), "hello")
    end)

    suite:case(":unwrap throws on None", function(asserts)
        asserts.throwsWith("called `Option.unwrap()` on a `None` value", function()
            Option.none():unwrap()
        end)
    end)

    suite:case(":unwrap_or", function(asserts)
        asserts.eq(Option.some(1):unwrap_or(99), 1)
        asserts.eq(Option.none():unwrap_or(99), 99)
    end)

    suite:case(":unwrap_or_else", function(asserts)
        local fallback = function() return 99 end

        asserts.eq(Option.some(1):unwrap_or_else(fallback), 1)
        asserts.eq(Option.none():unwrap_or_else(fallback), 99)
    end)

    suite:case(":unwrap_unchecked returns the inner value on Some", function(asserts)
        asserts.eq(Option.some(42):unwrap_unchecked(), 42)
    end)

    suite:case(":map on Some applies the function", function(asserts)
        local opt = Option.some(2):map(function(n: number) return n * 10 end)

        asserts.eq(opt:is_some(), true)
        asserts.eq(opt:unwrap(), 20)
    end)

    suite:case(":map on None stays None", function(asserts)
        local opt = Option.none():map(function(n: number) return n * 10 end)

        asserts.eq(opt:is_none(), true)
    end)

    suite:case(":inspect runs the closure only on Some and returns self", function(asserts)
        local seen: number? = nil
        local original = Option.some(7)
        local returned = original:inspect(function(v) seen = v end)

        asserts.eq(seen, 7)
        asserts.eq(returned, original)

        seen = nil
        local noneOriginal = Option.none()
        local noneReturned = noneOriginal:inspect(function(v) seen = v end)

        asserts.eq(seen, nil)
        asserts.eq(noneReturned, noneOriginal)
    end)

    suite:case(":map_or", function(asserts)
        local double = function(n: number) return n * 2 end

        asserts.eq(Option.some(5):map_or(0, double), 10)
        asserts.eq(Option.none():map_or(0, double), 0)
    end)

    suite:case(":map_or_else", function(asserts)
        local fallback = function() return -1 end
        local double = function(n: number) return n * 2 end

        asserts.eq(Option.some(5):map_or_else(fallback, double), 10)
        asserts.eq(Option.none():map_or_else(fallback, double), -1)
    end)

    suite:case(":and_opt", function(asserts)
        local later = Option.some(99)

        asserts.eq(Option.some(1):and_opt(later):unwrap(), 99)
        asserts.eq(Option.none():and_opt(later):is_none(), true)
        asserts.eq(Option.some(1):and_opt(Option.none()):is_none(), true)
    end)

    suite:case(":and_then chains on Some and passes through None", function(asserts)
        local positive_sqrt = function(n: number): Option.Option<number>
            if n < 0 then return Option.none() end
            return Option.some(math.sqrt(n))
        end

        asserts.eq(Option.some(16):and_then(positive_sqrt):unwrap(), 4)
        asserts.eq(Option.some(-1):and_then(positive_sqrt):is_none(), true)
        asserts.eq(Option.none():and_then(positive_sqrt):is_none(), true)
    end)

    suite:case(":filter keeps Some when predicate true, drops otherwise", function(asserts)
        local even = function(n: number) return n % 2 == 0 end

        asserts.eq(Option.some(4):filter(even):unwrap(), 4)
        asserts.eq(Option.some(5):filter(even):is_none(), true)
        asserts.eq(Option.none():filter(even):is_none(), true)
    end)

    suite:case(":or_opt", function(asserts)
        local fallback = Option.some(99)

        asserts.eq(Option.some(1):or_opt(fallback):unwrap(), 1)
        asserts.eq(Option.none():or_opt(fallback):unwrap(), 99)
        asserts.eq(Option.none():or_opt(Option.none()):is_none(), true)
    end)

    suite:case(":or_else chains on None, passes through on Some", function(asserts)
        local recover = function(): Option.Option<number>
            return Option.some(99)
        end

        asserts.eq(Option.some(1):or_else(recover):unwrap(), 1)
        asserts.eq(Option.none():or_else(recover):unwrap(), 99)
    end)

    suite:case(":xor returns the only Some, or None if both/neither", function(asserts)
        asserts.eq(Option.some(1):xor(Option.none()):unwrap(), 1)
        asserts.eq(Option.none():xor(Option.some(2)):unwrap(), 2)
        asserts.eq(Option.some(1):xor(Option.some(2)):is_none(), true)
        asserts.eq(Option.none():xor(Option.none()):is_none(), true)
    end)

    suite:case("None is a shared singleton", function(asserts)
        asserts.eq(Option.none(), Option.none())
    end)

    suite:case("instances are frozen", function(asserts)
        asserts.eq(table.isfrozen(Option.some(1) :: any), true)
        asserts.eq(table.isfrozen(Option.none() :: any), true)
    end)
end)

return nil
