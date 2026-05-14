<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-white.svg">
    <img src="assets/logo-black.svg" alt="rusty-luau" width="200" />
  </picture>
</p>

<p align="center">
  <a href="TRAIT_CONVENTIONS.ko.md">한국어</a>
</p>

# Trait conventions

How to define and implement traits with [`src/std/trait`](src/std/trait/init.luau).

The type machinery is deliberately explicit - past attempts that hid it behind
a clever runtime wrapper produced unsolvable type errors (`*CYCLE*`, "Calling
function ... is ambiguous"). These conventions keep the explicit parts uniform so
they are easy to write, easy to read, and hard to get subtly wrong.

Canonical working references live in [`src/std/trait/examples/`](src/std/trait/examples/):
`AnimalTrait` + `Sheep`/`Wolf` (non-generic), `IterTrait` + `RangeIter` (generic).

## The one rule that matters

**Every method on an implementer's public type must have exactly one source.**

A method that appears twice in an intersection - once from the class' own
method table and once from a trait contract - becomes an *overloaded* function
that Luau refuses to call. Both earlier trait designs failed on exactly this.

The conventions below are just the mechanical way to satisfy that rule.

## Defining a trait

A trait module exports three types and returns `trait.define(defaults)`:

- `Requires<Self, ...>` - the required-method contract, generic over the
  implementer's own type `Self` (and any element types). Generic `Self` keeps
  it fully typed: an implementer's `(self: Sheep) -> string` satisfies
  `Requires<Sheep>` exactly, with no `any` widening.
- `Defaults` - `typeof(defaults)`, the default-method table.
- `For<Self, ...>` - `Requires<...> & Defaults`, the full trait surface that
  implementers intersect onto their public type.

```luau
local trait = require("../../trait")

-- Required-method contract, generic over the implementer's type `Self`.
export type Requires<Self> = {
    noise: (self: Self) -> string;
}

local defaults = {}

-- Default methods are *generic functions*. `self` is `Self & Requires<Self>`:
--  * `& Requires<Self>` lets the body call required methods - `self:noise()`
--    typechecks because `Self & Requires<Self>` is a subtype of `Self`;
--  * the leading `Self` lets callers pass their full concrete type back in.
-- A default that calls *other* defaults uses `Self & Requires<Self> & Defaults`.
function defaults.introduce<Self>(self: Self & Requires<Self>): ()
    print(`Hi-{ self:noise() }`)
end

export type Defaults = typeof(defaults)
export type For<Self> = Requires<Self> & Defaults

return trait.define(defaults)
```

Rules:

- Default-method `self` is **always** `Self & Requires<Self>` (add `& Defaults`
  only if the method calls other defaults). Never `self: any`.
- `define` takes no turbofish - `D` is inferred from `defaults`.
- Generic traits add type parameters to `Requires` / `For` (e.g.
  `Requires<Self, T>`); the `defaults` table stays non-generic, holding generic
  *functions*, so `define` is still one plain call.

## Implementing a trait

```luau
local trait = require("../../trait")
local AnimalTrait = require("./AnimalTrait")

-- 1. Plain method table. Write required methods directly onto it.
local SheepMethods = {}

function SheepMethods.noise(self: Sheep): string
    return "baaaaaah!"
end

-- 2. `impl` checks the contract (a missing/wrong `noise` errors *here*) and
--    copies the trait's default methods into `SheepMethods` at runtime.
--    Turbofish: `<<typeof(methods), Trait.Requires<Self, ...>>>`.
trait.impl<<typeof(SheepMethods), AnimalTrait.Requires<Sheep>>>(SheepMethods, AnimalTrait)

-- 3. Prototype. `__index` is cast to `{}` so the *type* does not re-expose the
--    methods - they must come only from `& For<Self>` below, or they would be
--    sourced twice and collapse into an ambiguous overload.
local SheepPrototype = table.freeze({
    __index = SheepMethods :: {};
})

-- 4. Public type: the metatable shape, intersected with the trait surface.
--    `& AnimalTrait.For<Sheep>` is the single source of every trait method and
--    makes `Sheep <: AnimalTrait.For<Sheep>` hold trivially.
export type Sheep = setmetatable<{
    read kind: "Sheep";
}, typeof(SheepPrototype)> & AnimalTrait.For<Sheep>

-- 5. Constructor. The `:: Sheep` cast is required: the raw `setmetatable` value
--    cannot carry the copied-in defaults in its type, so it is narrowed here.
local function new(): Sheep
    return table.freeze(setmetatable({
        kind = "Sheep" :: "Sheep";
    }, SheepPrototype)) :: Sheep
end

return table.freeze({
    new = new;
})
```

Rules:

- The method table (`SheepMethods`) holds **only** the class' own methods.
  Defaults are never written here - `impl` injects them at runtime.
- `impl` is turbofished with `typeof(methods)` and the trait's `Requires`
  instantiated at this implementer's `Self` (and element types). Its return
  value is unused in this pattern; the call is for the contract check + the
  runtime default-copy.
- `__index` is **always** cast `:: {}`.
- The public type is **always** `setmetatable<Fields, typeof(Prototype)> & Trait.For<Self>`.
- The constructor body **always** ends with `:: T`.
- Multiple traits: add `& TraitA.For<Self> & TraitB.For<Self>`, one `impl` call
  each. (The traits' method names must not collide.)

## Why the odd bits exist - do not "clean them up"

| Looks removable | Why it must stay |
| --- | --- |
| `__index = methods :: {}` | Without the `:: {}`, methods are typed on both `__index` and `& For<Self>` -> ambiguous overload. |
| `:: T` in the constructor | The `setmetatable` value's type cannot include the runtime-copied defaults; the cast narrows it to the declared surface. |
| generic `<Self>` on every default method | A non-generic / `any` `self` either breaks the method body or forces implementers to accept `any`. |
| `& Trait.For<Self>` listing the surface explicitly | Makes `Impl <: Trait.For<Self>` trivial, so trait-method calls resolve without the solver having to reconstruct it through the metatable. |
