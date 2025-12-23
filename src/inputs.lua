local cfg       = require("utils.config_reader")
local tbl       = require("utils.table_utils")
local configure = require("src.configure")

local inputs = {}
inputs.__index = inputs

function inputs.new(filename)
    return setmetatable(
        {
            filename = filename,
            data     = nil
        }, inputs
    )
end

function inputs:is_loaded()
    return data ~= nil
end

-- Try to load input file contents.
-- If the file doesn't exist or
-- its format is unreadable,
-- prompts the user to configure bindings.
-- Does nothing if already loaded.
function inputs:load()
    if self.data ~= nil then return end
    if not fs.exists(self.filename) or not
    cfg.is_valid_seque_file(self.filename) then
        -- TODO: This should really return
        -- the user-inputted array of selected
        -- inputs and the re-reading of the
        -- input-file could be avoided!
        configure.run(self.filename)
    end
    self.data = cfg.read_seque(self.filename, "")
end

-- Checks whether the given peripheral
-- referred to as an ID is an input
function inputs:is_input_chest(inv_id)
    return tbl.contains(self.data, inv_id)
end

return inputs
