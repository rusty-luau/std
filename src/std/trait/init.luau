--- A trait: a frozen container holding the trait's default methods.
export type Trait<D> = {
    read defaults: D;
}

--- Defines a trait from its default methods.
local function define<D>(defaults: D): Trait<D>
    return table.freeze({
        defaults = defaults;
    })
end

--- Implements a trait on a class table. The class must already provide the
--- trait's required methods (`R`); each default is copied in only when the
--- class does not already define a method of the same name.
local function impl<C, R, D>(class_table: C & R, t: Trait<D>): C & R & D
    local target: any = class_table
    local defaults: { [string]: (...any) -> ...any } = t.defaults

    for key, default_fn in defaults do
        if target[key] == nil then
            target[key] = default_fn
        end
    end

    return target
end

--- Copies the class's own methods from a separate table into the class
--- table. Methods already on the class are not overwritten.
local function inherent<C, M>(class_table: C, methods: M): C & M
    local target: any = class_table
    local methods: { [string]: (...any) -> ...any } = methods

    for key, method in methods do
        if target[key] == nil then
            target[key] = method
        end
    end

    return target
end

return table.freeze({
    define = define;
    impl = impl;
    inherent = inherent;
})
