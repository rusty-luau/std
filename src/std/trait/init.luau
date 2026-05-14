--- A `Trait` carries a trait's default-method implementations (`D`). It does
--- *not* carry the required-method contract: the contract is supplied directly
--- at each `impl` call (see below). Keeping the contract out of the `Trait`
--- value - and out of every implementer's type - is the key fix over earlier
--- attempts, where intersecting a `Requires` contract into a class' public
--- type re-declared methods the class already had. Luau then saw each such
--- method as an *overloaded* function (`(A) -> R & (B) -> R`) and refused to
--- call it: "Calling function ... is ambiguous". Here the contract is only
--- ever a *constraint* on `impl`'s argument; it never reaches a class type.
export type Trait<D> = {
    read defaults: D;
}

--- Defines a trait from its table of default methods. `D` is inferred from
--- `defaults`, so no turbofish is needed:
---
---     return trait.define(defaults)
local function define<D>(defaults: D): Trait<D>
    return table.freeze({
        defaults = defaults;
    })
end

--- Implements `t` for `methods` (a class' `__index` method table): copies the
--- trait's default methods into `methods` and returns it retyped as `M & D`.
--- Defaults never overwrite a method the class already defines - the
--- implementer's own definitions always win.
---
--- The parameter type `methods: M & R` is what enforces the required-method
--- contract: `R` is the trait's `Requires` type, and if `methods` is missing a
--- required method it is not assignable to `M & R`, which is a type error *at
--- this call*. `M` and `R` must both be supplied via turbofish (`M` cannot be
--- recovered from the `M & R` intersection of a single value; `R` is the
--- contract being asserted). `D` is inferred from `t`:
---
---     local Impl = trait.impl<<typeof(methods), MyTrait.Requires>>(methods, MyTrait)
---
--- For a generic trait, pass the contract instantiated at the concrete element
--- type for a fully precise check:
---
---     local Impl = trait.impl<<typeof(methods), Iter.Requires<number>>>(methods, IterTrait)
local function impl<M, R, D>(methods: M & R, t: Trait<D>): M & D
    local target: any = methods
    local defaults: any = t.defaults

    for key, default_fn in defaults do
        if target[key] == nil then
            target[key] = default_fn
        end
    end

    return target
end

return table.freeze({
    define = define;
    impl = impl;
})
