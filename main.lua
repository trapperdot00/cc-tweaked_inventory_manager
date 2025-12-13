local cfg       = require("utils.config_reader")
local cliargs   = require("options")
local work      = require("work_delegator")
local Inventory = require("Inventory")

local function main()
    local pwd = fs.getDir(shell.resolve(arg[0]))

    -- Files
    local inventory_file = fs.combine(pwd, "items.data")
    local inputs_file    = fs.combine(pwd, "inputs.txt")

    if not fs.exists(inputs_file) then
        print("Input-chest file '" .. inputs_file .. "' doesn't exist.")
        return
    end

    local inputs    = cfg.read_seque(inputs_file)
    local options   = cliargs.parse()
    local inventory = Inventory.new(inputs, inventory_file)
    
    -- Select appropriate work for command-line arguments
    work.delegate(options, inventory)
end

main()
