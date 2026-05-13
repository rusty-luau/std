local fs = require("@std/fs")
local test_runner = require("@std/test/runner")

local SPEC_SUFFIX = ".spec.luau"
local test_root = "./tests"

local walker = fs.walk(test_root, { recursive = true })

while true do
    local path = walker()

    if path == nil then
        break
    end

    local path_str = tostring(path)

    if path_str:find(".check", 1, true) then
        continue
    end

    if path_str:sub(-#SPEC_SUFFIX) == SPEC_SUFFIX then
        local module_path = path_str:sub(1, -#SPEC_SUFFIX - 1) .. ".spec"
        
        local require_path = "../" .. module_path
        print(`  require path: { require_path }`)
        
        do
            (require :: any)(require_path)
        end
    end
end

test_runner.runRegisteredTests()