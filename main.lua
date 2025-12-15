local cliargs   = require("options")
local work      = require("work_delegator")

local function main()
    local pwd = fs.getDir(shell.resolve(arg[0]))

    -- Files
    local inventory_file = fs.combine(pwd, "items.data")
    local inputs_file    = fs.combine(pwd, "inputs.txt")
    local stack_file     = fs.combine(pwd, "stack.txt")

    local options   = cliargs.parse()
    
    -- Select appropriate work for command-line arguments
    work.delegate(options, inputs_file, inventory_file, stack_file)
end

main()
