local cfg       = require("config_reader")
local cliargs   = require("options")
local work      = require("work_delegator")
local Inventory = require("Inventory")

local function main()
    -- Update this to the current working directory:
    -- local pwd        = "./"
    local pwd        = "/chest/"

    -- Files
    local inventory_file = pwd .. "items.data"
    local inputs_file    = pwd .. "inputs.txt"

    local options   = cliargs.parse()
    local inputs    = cfg.read_seque(inputs_file)
    local inventory = Inventory.new(inputs, inventory_file)
    
    -- Select appropriate work for command-line arguments
	local t1 = os.clock()
    work.delegate(options, inventory)
	local t2 = os.clock()
	print("elapsed time:", t2 - t1, "seconds.")
end

main()
