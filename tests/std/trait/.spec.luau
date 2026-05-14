local test = require("@std/test")

local trait = require("../../../src/std/trait")

--- A small trait, defined the convention way: one required method (`name`) and
--- one default method (`greeting`) that dispatches through it. `greeting`'s
--- `self` is `GreetFor<Self>` because the body calls a trait method.
type GreetRequires<Self> = {
    name: (self: Self) -> string;
}

local greet_defaults = {}

function greet_defaults.greeting<Self>(self: GreetFor<Self>): string
    return `Hello, { self:name() }`
end

type GreetDefaults = typeof(greet_defaults)
type GreetFor<Self> = GreetRequires<Self> & GreetDefaults

local Greet = trait.define(greet_defaults)

test.suite("std.trait", function(suite)
    suite:case(".define exposes the defaults table", function(asserts)
        asserts.eq(Greet.defaults, greet_defaults)
        asserts.eq(type(Greet.defaults.greeting), "function")
    end)

    suite:case(".define returns a frozen trait", function(asserts)
        asserts.eq(table.isfrozen(Greet :: any), true)
    end)

    suite:case(".impl copies default methods into the method table", function(asserts)
        local methods = {}
        function methods.name(self: typeof(methods)): string
            return "world"
        end

        trait.impl<<typeof(methods), GreetRequires<typeof(methods)>>>(methods, Greet)

        asserts.eq(type((methods :: any).greeting), "function")
    end)

    suite:case(".impl returns the same method table", function(asserts)
        local methods = {}
        function methods.name(self: typeof(methods)): string
            return "world"
        end

        local returned = trait.impl<<typeof(methods), GreetRequires<typeof(methods)>>>(methods, Greet)

        asserts.eq(returned, methods)
    end)

    suite:case(".impl does not overwrite a method the class already defines", function(asserts)
        local methods = {}
        function methods.name(self: typeof(methods)): string
            return "world"
        end
        -- the class defines its own `greeting`, shadowing the trait default
        function methods.greeting(self: typeof(methods)): string
            return "custom"
        end

        trait.impl<<typeof(methods), GreetRequires<typeof(methods)>>>(methods, Greet)

        asserts.eq((methods :: any):greeting(), "custom")
    end)

    suite:case("a default method dispatches through the implementer's required method", function(asserts)
        -- A convention-shaped implementer: a method table whose name doubles as
        -- the type name, with `__index :: {}` so methods have a single type
        -- source, and a public type `setmetatable<...> & For<...>`.
        local Person = {}
        local PersonPrototype = table.freeze({
            __index = Person :: {};
        })

        function Person.name(self: Person): string
            return self.who
        end

        trait.impl<<typeof(Person), GreetRequires<Person>>>(Person, Greet)

        type Person = setmetatable<{
            read who: string;
        }, typeof(PersonPrototype)> & GreetFor<Person>

        local alice: Person = table.freeze(setmetatable({
            who = "Alice";
        }, PersonPrototype)) :: Person

        asserts.eq(alice:name(), "Alice")
        asserts.eq(alice:greeting(), "Hello, Alice")
    end)
end)

return nil
