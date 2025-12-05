local sorter    = require("sorter")
local cfg       = require("config_reader")
local debugger  = require("debugger")
local cli_args  = require("cli_args")

local args = { ... }

local function print_help()
	print("usage: <program> [options]")
	print("options: --sort --pull --get-item=<item>")
	print("         --print-rows --print-items --print-inputs")
end

local options = {
	-- TODO
	sort			= false,
	pull			= false,
	print_rows		= false,
	print_items		= false,
	print_inputs	= false
}

local function main()
    -- Have to update this to the current working directory
    local pwd = "/programs/chest/0006/"
	--local pwd = "./"

    -- Configuration files
    local row_chests_file = pwd .. "row_chests.txt"
    local row_items_file  = pwd .. "row_items.txt"
    local inputs_file     = pwd .. "inputs.txt"

    -- Configuration tables
    local rows   = cfg.read_config_file_assoc(row_chests_file)
    local items  = cfg.read_config_file_assoc(row_items_file)
    local inputs = cfg.read_config_file_seque(inputs_file)

    if cli_args.contains(args, "--sort") then
        sorter.sort_input_chests(rows, items, inputs)
    elseif cli_args.contains(args, "--pull") then
        sorter.pull_into_input_chests(rows, items, inputs)
    elseif cli_args.contains(args, "--print-rows") then
        debugger.print_assoc(rows)
    elseif cli_args.contains(args, "--print-items") then
        debugger.print_assoc(items)
    elseif cli_args.contains(args, "--print-inputs") then
        debugger.print_seque(inputs)
	elseif cli_args.contains(args, "--get-item") then
		local item = cli_args.get_value_for_flag(args, "--get-item")
		sorter.get_item(rows, items, inputs, item)
    else
		print_help()
    end
end

main()
