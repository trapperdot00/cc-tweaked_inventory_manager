local tbl          = require("table_utils")
local chest_parser = require("chest_parser")

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(inputs, filename)
    local self = setmetatable({}, Inventory)
    self.inputs   = inputs
    self.filename = filename
    self.contents = nil
    return self
end

function Inventory:load(noscan)
    if self.contents then return end
    local file = io.open(self.filename)
    if file then
        self.contents = chest_parser.read_from_file(file)
        if not noscan then
            self:scan_inputs()
        end
    else
        self:scan()
    end
end

function Inventory:get_slot_size(chest_id)
    local chest_data = self.contents[chest_id]
    local chest_size = chest_data.size
    return chest_size
end

function Inventory:get_full_slots(chest_id)
    local chest_data  = self.contents[chest_id]
    local chest_items = chest_data.items
    local full_slots = tbl.size(chest_items)
    return full_slots
end

function Inventory:get_free_slots(chest_id)
    local slot_size  = self:get_slot_size(chest_id)
    local full_slots = self:get_full_slots(chest_id)
    local free_slots = slot_size - full_slots
    return free_slots
end

function Inventory:is_full(chest_id)
    local slot_size  = self:get_slot_size(chest_id)
    local full_slots = self:get_full_slots(chest_id)
    return slot_size == full_slots
end

function Inventory:is_empty(chest_id)
    local full_slots = self:get_full_slots(chest_id)
    return full_slots == 0
end

function Inventory:is_input_chest(chest_id)
    return tbl.contains(self.inputs, chest_id)
end

-- Executes a plan to move an item between two chests
--
-- `plan` table's named members:
--   `src`: identifies the source chest by id
--   `dst`: identifies the destination chest by id
--   `src_slot`: identifies an item by its occupied slot
--               to be moved from `src` into `dst`
function Inventory:execute_plan(plan)
    local src      = plan.src
    local dst      = plan.dst
    local src_slot = plan.src_slot

    local src_chest = peripheral.wrap(src)
    src_chest.pushItems(dst, src_slot)
end

-- Execute a list of plans in parallel
function Inventory:execute_plans(plans)
    local tasks = {}
    for _, plan in ipairs(plans) do
        table.insert(tasks,
            function() self:execute_plan(plan) end
        )
    end
    parallel.waitForAll(table.unpack(tasks))
end

function Inventory:get_affected_chests(plans)
    local affected = {}
    for _, plan in ipairs(plans) do
        if not tbl.contains(affected, plan.src) then
            table.insert(affected, plan.src)
        end
        if not tbl.contains(affected, plan.dst) then
            table.insert(affected, plan.dst)
        end
    end
    return affected
end

-- Get movement plan for a basic push operation
function Inventory:get_push_plans()
    local plans = {}

    local dst_ids, dst_slots = table.unpack(
        self:get_viable_push_chests()
    )

    local src_i = 1
    local dst_i = 1
    while src_i <= #self.inputs and dst_i <= #dst_ids do
        local src = self.inputs[src_i]
        local src_data = self.contents[src]
        for src_slot, item in pairs(src_data.items) do
            local dst = dst_ids[dst_i]
            local plan = {
                src      = src,
                dst      = dst,
                src_slot = src_slot
            }
            table.insert(plans, plan)
            dst_slots[dst_i] = dst_slots[dst_i] - 1
            if dst_slots[dst_i] == 0 then
                dst_i = dst_i + 1
            end
            if dst_i > #dst_ids then break end
        end
        src_i = src_i + 1
    end
    
    return plans
end

-- Push items from input chests into output chests
function Inventory:push()
    self:load()

    -- Get item movement plans
    local plans = self:get_push_plans()
    self:execute_plans(plans)
    
    -- Update affected chests in memory
    local affected = self:get_affected_chests(plans)
    for _, id in ipairs(affected) do
        self:update_chest(id)
    end

    -- Update chest database file
    if #affected > 0 then
        self:save_contents()
    end
end

function Inventory:get_viable_push_chests()
    local output_names    = {}
    local free_slots_list = {}
    for output_name, contents in pairs(self.contents) do
        if not self:is_input_chest(output_name) then
            local free_slots = self:get_free_slots(output_name)
            if free_slots > 0 then
                table.insert(output_names, output_name)
                table.insert(free_slots_list, free_slots)
            end
        end
    end
    return { output_names, free_slots_list }
end

function Inventory:get_viable_pull_chests()
    local input_names  = {}
    local input_slots  = {}
    local output_names = {}
    local output_slots = {}
    for chest_name, contents in pairs(self.contents) do
        if self:is_input_chest(chest_name) then
            if not self:is_full(chest_name) then
                local empty_slots = self:get_free_slots(chest_name)
                table.insert(input_names, chest_name)
                table.insert(input_slots, empty_slots)
            end
        else
            if not self:is_empty(chest_name) then
                table.insert(output_names, chest_name)
                local slots = {}
                for slot, item in pairs(contents.items) do
                    table.insert(slots, slot)
                end
                table.insert(output_slots, slots)
            end
        end
    end
    local input = {
        names = input_names,
        slots = input_slots
    }
    local output = {
        names = output_names,
        slots = output_slots
    }
    return { input, output }
end

function Inventory:get_output_chests_containing(sought_items)
    local output_names = {}
    local output_slots = {}
    for chest_name, contents in pairs(self.contents) do
        if not self:is_input_chest(chest_name) then
            local slots = {}
            for slot, item in pairs(contents.items) do
                for _, sought_item in ipairs(sought_items) do
                    if item.name == sought_item then
                        if output_names[#output_names] ~= chest_name then
                            table.insert(output_names, chest_name)
                        end
                        table.insert(slots, slot)
                    end
                end
            end
            if #slots > 0 then
                table.insert(output_slots, slots)
            end
        end
    end
    return { names = output_names, slots = output_slots }
end

function Inventory:get_nonfull_input_chests()
    local input_names = {}
    local input_slots = {}
    for _, input_name in ipairs(self.inputs) do
        local free_slots = self:get_free_slots(input_name)
        if not self:is_empty(input_name) then
            table.insert(input_names, input_name)
            table.insert(input_slots, free_slots)
        end
    end
    return { names = input_names, slots = input_slots }
end

function Inventory:do_pull(input, output)
    local pulled   = 0
    local input_i  = 1
    local output_i = 1
    while output_i <= #output.names
    and   input_i  <= #input.names do
        local output_name = output.names[output_i]
        local slots       = output.slots[output_i]
        for _, slot in ipairs(slots) do
            local input_chest = peripheral.wrap(input.names[input_i])
            if input_chest.pullItems(output_name, slot) > 0 then
                pulled = pulled + 1
            end
            input.slots[input_i] = input.slots[input_i] - 1
            if input.slots[input_i] == 0 then
                input_i = input_i + 1
            end
            if input_i > #input.names then break end
        end
        output_i = output_i + 1
    end
    return { pulled, output_i }
end

function Inventory:do_get(input, output, sought_items)
    local got      = 0
    local output_i = 1
    local input_i  = 1
    while output_i <= #output.names
    and   input_i  <= #input.names do
        local output_name = output.names[output_i]
        local output_chest = peripheral.wrap(output_name)
        local output_slot_i = 1
        while output_slot_i <= #output.slots[output_i] do
            local output_slot = output.slots[output_i][output_slot_i]
            local input_name = input.names[input_i]
            if output_chest.pushItems(input_name, output_slot) > 0 then
                got = got + 1
            end
            input.slots[input_i] = input.slots[input_i] - 1
            if input.slots[input_i] <= 0 then
                input_i = input_i + 1
            end
            output_slot_i = output_slot_i + 1
        end
        output_i = output_i + 1
    end
    return { got, output_i }
end

function Inventory:pull()
    self:load()

    print("Calculating viable chests.")
    local input, output = table.unpack(
        self:get_viable_pull_chests()
    )
    print(#input.names  .. " viable input chests.")
    print(#output.names .. " viable output chests.")
    if #input.names == 0 or #output.names == 0 then return end

    print("Starting pull.")
    local pulled, output_i = table.unpack(
        self:do_pull(input, output)
    )
    print("Pulled " .. pulled .. " slots.")

    if pulled == 0 then return end
    if output_i > #output.names then
        output_i = #output.names
    end

    print("Updating chest database in memory.")
    self:update_chests(output.names, 1, output_i)

    print("Commiting changes to file '" .. self.filename .. "'.")
    self:save_contents()
end

function Inventory:scan()
    self.contents = chest_parser.read_from_chests()
    self:save_contents()
end

function Inventory:get(sought_items)
    self:load(true)

    print("Calculating viable chests.")
    local output = self:get_output_chests_containing(sought_items)
    print(#output.names .. " viable output chests.")
    if #output.names == 0 then return end

    self:scan_inputs()
    local input = self:get_nonfull_input_chests()
    print(#input.names  .. " viable input chests.")
    if #input.names == 0 then return end
    
    print("Starting get.")
    local got, output_i = table.unpack(
        self:do_get(input, output, sought_items)
    )
    print("Got " .. got .. " slots.")

    if got == 0 then return end
    if output_i > #output.names then
        output_i = #output.names
    end

    print("Updating chest database in memory.")
    self:update_chests(output.names, 1, output_i)

    print("Commiting changes to file '" .. self.filename .. "'.")
    self:save_contents()
end

function Inventory:scan_inputs()
    for _, chest_name in ipairs(self.inputs) do
        self:update_chest(chest_name)
    end
    self:save_contents()
end

function Inventory:update_chest(chest_id)
    local chest = peripheral.wrap(chest_id)
    local chest_data = { size = chest.size(), items = chest.list() }
    self.contents[chest_id] = chest_data
end

function Inventory:update_chests(chest_list, start_, end_)
    for i = start_, end_ do
        local chest_name = chest_list[i]
        print("Updating " .. chest_name)
        self:update_chest(chest_name)
    end
end

function Inventory:save_contents()
    chest_parser.write_to_file(self.contents, self.filename)
end

function Inventory:count(sought_items)
    self:load(true)
    
    local counts = {}
    for _, sought_item in ipairs(sought_items) do
        for chest_name, contents in pairs(self.contents) do
            for _, item in ipairs(contents.items) do
                if item.name == sought_item then
                    if sought_items[#counts] == sought_item then
                        counts[#counts] = counts[#counts] + item.count
                    else
                        table.insert(counts, item.count)
                    end
                end
            end
        end
    end

    for i = 1, #counts do
        print(sought_items[i], counts[i])
    end
end

return Inventory
