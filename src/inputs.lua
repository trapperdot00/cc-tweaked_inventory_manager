local input_db  = require("src.input_db")
local tbl       = require("utils.table_utils")
local configure = require("src.configure")

local inputs = {}
inputs.__index = inputs

function inputs.new(filename)
    return setmetatable(
        {
            filename = filename,
            db       = input_db.new(),
            loaded   = false
        }, inputs
    )
end

function inputs:add(inv_id)
    self:load()
    self.db:add(inv_id)
end

function inputs:del(inv_id)
    self:load()
    self.db:del(inv_id)
end

function inputs:get(i)
    self:load()
    return self.db:get(i)
end

function inputs:size()
    self:load()
    return self.db:size()
end

function inputs:exists(inv_id)
    self:load()
    return self.db:exists(inv_id)
end

function inputs:is_loaded()
    return self.loaded
end

local function read_from_file(self)
    local file = io.open(self.filename)
    if not file then
        error(
            "cannot open file '" ..
            self.filename ..
            "' for reading", 0
        )
    end
    local text = file:read('a')
    file:close()
    local inv_ids = textutils.unserialize(text)
    for _, inv_id in ipairs(inv_ids) do
        self.db:add(inv_id)
    end
end

function inputs:load()
    if self:is_loaded() then return end
    if fs.exists(self.filename) then
        read_from_file(self)
    end
    self.loaded = true
end

function inputs:configure()
    local config = configure.run(self.filename)
    if #config == 0 then
        error("Invalid config: no inputs!", 0)
    end
    self.db = input_db.new()
    for _, inv_id in ipairs(config) do
        self.db:add(inv_id)
    end
    self:save_to_file()
end

function inputs:save_to_file()
    local file = io.open(self.filename, "w")
    if not file then
        error(
            "cannot open file '" ..
            self.filename ..
            "' for writing", 0
        )
    end
    file:write(textutils.serialize(self.db.data))
    file:close()
end

return inputs
