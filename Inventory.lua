local chest_parser = require("chest_parser")

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(inputs, filename)
    local self = setmetatable({}, Inventory)
    self.inputs   = inputs
    self.filename = filename
    return self
end

function Inventory:load()
    if self.contents then return end
    local file = io.open(self.filename)
    if file then
        self.contents = chest_parser.read_from_file(file)
        self:scan_inputs()
    else
        self:scan()
    end
end

local function get_table_size(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function Inventory:push()
    self:load()

    local output_names = {}
    local output_capacities = {}
    for output_name, contents in pairs(self.contents) do
        if not self:is_input_chest(output_name) then
            local occupied = get_table_size(contents.items)
            local empty    = contents.size - occupied
            if empty > 0 then
                table.insert(output_names, output_name)
                table.insert(output_capacities, empty)
            end
        end
    end

    local output_i = 1
    for _, input_name in ipairs(self.inputs) do
        local input_data = self.contents[input_name]
        for slot, item in pairs(input_data.items) do
            local output = peripheral.wrap(output_names[output_i])
            output.pullItems(input_name, slot)
            output_capacities[output_i] = output_capacities[output_i] - 1
            if output_capacities[output_i] == 0 then
                output_i = output_i + 1
            end
            if output_i > #output_names then break end
        end
    end
end

function Inventory:scan()
    self.contents = chest_parser.read_from_chests()
    chest_parser.write_to_file(self.contents, self.filename)
end

function Inventory:scan_inputs()
    for _, chest_name in ipairs(self.inputs) do
        local chest = peripheral.wrap(chest_name)
        local chest_data  = { size = chest.size(), items = chest.list() }
        self.contents[chest_name] = chest_data
    end
    chest_parser.write_to_file(self.contents, self.filename)
end

function Inventory:is_input_chest(chest_id)
    for _, input_name in ipairs(self.inputs) do
        if chest_id == input_name then
            return true
        end
    end
    return false
end

function Inventory:has_empty_slot(chest_id)
    local size  = self.contents[chest_id].size
    local count = 0
    for slot, item in pairs(self.contents[chest_id].items) do
        count = count + 1
    end
    return count ~= size
end

function Inventory:item_count(sought_item)
    local count = 0
    for chest_name, content in pairs(self.contents) do
        for slot, item in pairs(content) do
            if item.name == sought_item then
                count = count + item.count
            end
        end
    end
    return count
end

return Inventory
