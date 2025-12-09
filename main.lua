local cfg       = require("config_reader")
local options   = require("options")
local wd        = require("work_delegator")
local chests    = require("chest_parser")

local function main()
    -- Update this to the current working directory:
    local pwd        = "./"
    -- local pwd        = "/chest/"

    -- Configuration files
    local chest_contents_file = pwd .. "items.data"
    local input_chests_file   = pwd .. "inputs.txt"
    -- Deprecating... :
    local row_chests_file     = pwd .. "row_chests.txt"
    local row_items_file      = pwd .. "row_items.txt"

    -- Configuration tables
    local rows         = cfg.read_config_file_assoc(row_chests_file)
    local items        = cfg.read_config_file_assoc(row_items_file)
    local input_chests = cfg.read_config_file_seque(input_chests_file)

    -- Command-line arguments
    local opts      = options.parse()
    
    local chest_contents
    local file = io.open(chest_contents_file)
    if file then
        chest_contents = chests.read_from_file(file)
    else 
        chest_contents = chests.read_from_chests()
        chests.write_to_file(chest_contents, chest_contents_file)
    end
    
    -- Select appropriate work for command-line arguments
    wd.delegate(pwd, opts, rows, items, inputs)
end

main()
