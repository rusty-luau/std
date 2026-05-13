local fs = require("@std/fs")
local process = require("@lute/process")

local targets: { string } = {}
local found_separator = false

for _, a in process.args do
    if found_separator then
        table.insert(targets, a)
    elseif a == "--" then
        found_separator = true
    end
end

if #targets == 0 then
    print("Usage: lute run type-check.luau -- <dir1> [dir2] [...]")
    print("Example: lute run type-check.luau -- ./src ./tests")

    process.exit(1)
end

local luau_files: { string } = {}

for _, target in targets do
    if not fs.exists(target) then
        print(`[WARN] Target does not exist: { target }`)

        continue
    end

    local walker = fs.walk(target, { recursive = true })

    while true do
        local path = walker()

        if path == nil then
            break
        end

        local path_str = tostring(path)

        if path_str:sub(-5) == ".luau" then
            table.insert(luau_files, path_str)
        end
    end
end

local total = 0
local failed = 0
local failed_files: { string } = {}

for _, file in luau_files do
    if fs.type(file) ~= "file" then
        continue
    end

    total += 1

    local res = process.run({ "lute", "check", file })

    if res.exitcode == 0 then
        print(`[OK]   { file }`)
    else
        print(`[FAIL] { file } (exit={ res.exitcode })`)

        if res.stdout ~= "" then
            for line in res.stdout:gmatch("[^\r\n]+") do
                print(`    { line }`)
            end
        end

        if res.stderr ~= "" then
            for line in res.stderr:gmatch("[^\r\n]+") do
                print(`    { line }`)
            end
        end

        print("")

        failed += 1
        table.insert(failed_files, file)
    end
end

print("=== Summary ===")
print(`Targets: { table.concat(targets, ", ") }`)
print(`Total: { total }, Failed: { failed }`)

if failed > 0 then
    print("")
    print("Failed files:")

    for _, f in failed_files do
        print(`  - { f }`)
    end

    process.exit(1)
end