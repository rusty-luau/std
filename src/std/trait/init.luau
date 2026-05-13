--- A trait wrap default method implementations together with a required-method
--- contract `R`. `R` is carried by the phantom `_requires` field in
--- contravariant position so the type solver can recover it at `impl` sites
--- and enforce it against the implementer.
export type Trait<R, D> = {
    read defaults: D;
    read _requires: (R) -> ();
}

-- Defines a trait. `R` (the required-method shape) must be supplied via
--- turbofish: `trait.define<<MyRequires, typeof(defaults)>>(defaults)`.
local function define<R, D>(defaults: D): Trait<R, D>
    return table.freeze({
        defaults = defaults;
        _requires = function(_: R) end;
    })
end

--- Injects a trait's default methods into `class_table`.
--- `class_table: C & R` enforces structurally that the class satisfies the
--- trait's require-method contract; missing methods produce a type error.
--- Methods already present on the class are NOT overwritten - user
--- implemtations always win, whether defined before or after this call.
local function impl<C, D, R>(class_table: C & R, t: Trait<R, D>): C & D
    local class_any: any = class_table
    local defaults: any = t.defaults

    for key, fn in defaults do
        if class_any[key] == nil then
            class_any[key] = fn
        end
    end

    return class_any
end

return {
    define = define;
    impl = impl;
}