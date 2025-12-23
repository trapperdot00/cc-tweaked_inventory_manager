local tbl          = require("utils.table_utils")
local cont         = require("src.contents")
local cfg          = require("utils.config_reader")
local configure    = require("src.configure")

local push      = require("src.cmd.push")
local pull      = require("src.cmd.pull")
local size      = require("src.cmd.size")
local usage     = require("src.cmd.usage")
local get       = require("src.cmd.get")
local count     = require("src.cmd.count")
local find      = require("src.cmd.find")

local inventory = {}
inventory.__index = inventory

-- Constructs and returns a new instance of inventory
-- Named fields:
--     `contents_path`: Filename of the document that
--                      lists the current state of the
--                      managed chest-system.
--     `contents`     : Table that keeps track of the current
--                      state of the managed chest-system.
--     `inputs_path`  : Filename of the document that
--                      lists the chest IDs of input chests.
--     `inputs`       : Array of input chest IDs.
--     `stacks_path`  : Filename of the document that
--                      describes the currently known items'
--                      stack sizes.
--     `stacks`       : Associative table that associates
--                      an item name with a stack size.
--                      (key: item name; value: stack size)
function inventory.new(contents_path, inputs_path, stacks_path)
    local self = setmetatable({
        contents      = cont.new(contents_path),
        inputs_path   = inputs_path,
        inputs        = nil,
        stacks_path   = stacks_path,
        stacks        = nil
    }, inventory)
    self:load_inputs()
    return self
end

-- Try to load input file contents.
-- If the file doesn't exist or its format is unreadable,
-- prompts the user to reconfigure input chest bindings.
function inventory:load_inputs()
    if not fs.exists(self.inputs_path)
    or not cfg.is_valid_seque_file(self.inputs_path) then
        configure.run(self.inputs_path)
    end
    self.inputs = cfg.read_seque(self.inputs_path, "")
end

-- TODO: clean up this
function inventory:load_stack()
    if self.stacks then return end
    local file = io.open(self.stacks_path)
    if not file then self.stacks = {} return end
    local text = file:read('a')
    file:close()
    self.stacks = textutils.unserialize(text) or {}
end

function inventory:load(noscan)
    self:load_stack()
    self.contents:load() 
    if not noscan then
        self:scan_inputs()
    end
end

-- Checks whether the given inventory entity
-- referred to as an ID
-- is labeled as an input chest
function inventory:is_input_chest(chest_id)
    return tbl.contains(self.inputs, chest_id)
end

-- Executes a plan to move an item between two chests
--
-- `plan` table's named members:
--   `src`     : identifies the source chest by id
--   `dst`     : identifies the destination chest by id
--   `src_slot`: identifies an item by its occupied slot
--               to be moved from `src` into `dst`
--   `count`   : the count of items to move
--               (optional)
--   `dst_slot`: the destination slot to move the item into
--               (optional)
function inventory:execute_plan(plan)
    local src      = plan.src
    local dst      = plan.dst
    local src_slot = plan.src_slot
    local count    = plan.count
    local dst_slot = plan.dst_slot

    local src_chest = peripheral.wrap(src)
    if count == nil then
        src_chest.pushItems(dst, src_slot)
    elseif dst_slot == nil then
        src_chest.pushItems(dst, src_slot, count)
    else
        src_chest.pushItems(dst, src_slot, count, dst_slot)
    end
end

-- Execute a list of plans in parallel
function inventory:execute_plans(plans)
    local tasks = {}
    for _, plan in ipairs(plans) do
        table.insert(tasks,
            function() self:execute_plan(plan) end
        )
        if #tasks == 100 then
            parallel.waitForAll(table.unpack(tasks))
            tasks = {}
        end
    end
    parallel.waitForAll(table.unpack(tasks))
end

-- Returns an array-like table containing
-- the inventory IDs listed inside the given plan-list.
-- The IDs are listed only once.
--
-- `plan` table's named members:
--   `src`: identifies the source chest by id
--   `dst`: identifies the destination chest by id
--   `src_slot`: identifies an item by its occupied slot
--               to be moved from `src` into `dst`
--   `count`   : the count of items to move
--               (optional)
--   `dst_slot`: the destination slot to move the item into
--               (optional)
function inventory:get_affected_chests(plans)
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

-- Executes a given list of item-moving plans
-- and updates the affected inventories' databases.
function inventory:carry_out(plans)
    -- Move the specified items
    self:execute_plans(plans)
    
    -- Update affected chests in memory
    local affected = self:get_affected_chests(plans)
    for _, id in ipairs(affected) do
        print("updating", id)
        self.contents:update(id)
    end

    -- Update chest database file
    if #affected > 0 then
        print("saving to file", self.contents.filename)
        self.contents:save_to_file()
    end
end

-- Wrapper for `for_each_chest` that only calls
-- `func` for a given chest if it is an input chest.
function inventory:for_each_input_chest(func)
    local f = function(chest_id, contents)
        if self:is_input_chest(chest_id) then
            func(chest_id, contents)
        end
    end
    self.contents:for_each_chest(f)
end

-- Wrapper for `for_each_chest` that only calls
-- `func` for a given chest if it is an output chest.
function inventory:for_each_output_chest(func)
    local f = function(chest_id, contents)
        if not self:is_input_chest(chest_id) then
            func(chest_id, contents)
        end
    end
    self.contents:for_each_chest(f)
end

-- Wrapper that iterates over each input chest's slots.
function inventory:for_each_input_slot(func)
    local f = function(chest_id, contents)
        self.contents:for_each_slot_in(
            chest_id, contents, func
        )
    end
    self:for_each_input_chest(f)
end

-- Wrapper that iterates over each output chest's slots.
function inventory:for_each_output_slot(func)
    local f = function(chest_id, contents)
        self.contents:for_each_slot_in(
            chest_id, contents, func
        )
    end
    self:for_each_output_chest(f)
end

-- TODO: clean up this
function inventory:update_stacksize()
    self:load()
    local file = io.open(self.stacks_path, 'w')
    if not file then return end
    local item_equality = function(a, b)
        return a.name == b.name
    end
    local func = function(chest_id, slot, item)
        local chest = peripheral.wrap(chest_id)
        local item  = chest.getItemDetail(slot)
        self.stacks[item.name] = item.maxCount
    end
    self:for_each_input_slot(func)
    file:write(textutils.serialize(self.stacks))
    file:close()
end

-- Push items from the input chests into the output chests.
function inventory:push()
    self:update_stacksize()
    local plans = push.get_push_plans(self)
    self:carry_out(plans)
end

-- Pull items from the output chests into the input chests.
function inventory:pull()
    local plans = pull.get_pull_plans(self)
    self:carry_out(plans)
end

function inventory:size()
    local in_slots, out_slots = size.size(self)
    local full_slots = in_slots + out_slots
    print("[IN] :", in_slots)
    print("[OUT]:", out_slots)
    print("[ALL]:", full_slots)
end

function inventory:usage()
    local total, used = usage.usage(self)
    local percent = (used / total) * 100
    print("[USED]:", used)
    print("[ALL] :", total)
    print("["..tostring(percent).."%]")
end

function inventory:get(sought_items)
    local plans = get.get_get_plans(self, sought_items)
    self:carry_out(plans)
end

function inventory:count(sought_items)
    for _, item in ipairs(sought_items) do
        local cnt = count.count(self, item)
        print(item, cnt)
    end
end

function inventory:find(sought_items)
    for _, item in ipairs(sought_items) do
        local chests = find.find(self, item)
        for _, chest_id in ipairs(chests) do
            print(item, "->", chest_id)
        end
    end
end

function inventory:scan()
    self.contents:scan()
end

function inventory:scan_inputs()
    for _, chest_name in ipairs(self.inputs) do
        self.contents:update(chest_name)
    end
end

return inventory
