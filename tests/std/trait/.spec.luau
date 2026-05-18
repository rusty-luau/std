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

    suite:case(".inherent copies own methods into the class table", function(asserts)
        local methods = {}
        function methods.greet(self: typeof(methods)): string
            return "hi"
        end

        local class_table = trait.inherent({}, methods)

        asserts.eq(type(class_table.greet), "function")
    end)

    suite:case(".inherent returns the class table", function(asserts)
        local methods = {}
        function methods.greet(self: typeof(methods)): string
            return "hi"
        end

        local class_table = {}
        local returned = trait.inherent(class_table, methods)

        asserts.eq(returned, class_table)
    end)

    suite:case(".inherent does not overwrite a method the class already defines", function(asserts)
        local class_table = {}
        function class_table.greet(self: typeof(class_table)): string
            return "original"
        end

        local methods = {}
        function methods.greet(self: typeof(methods)): string
            return "new"
        end

        trait.inherent(class_table, methods)

        asserts.eq((class_table :: any):greet(), "original")
    end)

    suite:case("a default method dispatches through the implementer's required method", function(asserts)
        -- A convention-shaped implementer: own methods kept in a separate
        -- table and merged via `inherent`; trait defaults merged via `impl`;
        -- public type ends with `& Trait.For<...>`.
        local person_methods = {}
        function person_methods.name(self: Person): string
            return self.who
        end

        local Person = trait.inherent({}, person_methods)
        local PersonPrototype = table.freeze({
            __index = Person :: {};
        })

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
