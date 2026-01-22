local tbl = require("utils.table_utils")
local move_planner = {}

local inv_data = {}
inv_data.__index = inv_data

function inv_data.new(inv_id, inv_slot, inv_item)
    return setmetatable({
            id   = inv_id,
            slot = inv_slot,
            item = inv_item
        }, inv_data
    )
end

local function get_empty_slots
(db, inv_ids)
    -- INV_IDS = { SLOTS }
    local empty_slots = {}
    for _, inv_id in ipairs(inv_ids) do
        if empty_slots[inv_id] == nil then
            empty_slots[inv_id] = {}
        end
        local inv_size = db:get_size(inv_id)
        for slot = 1, inv_size do
            if db:item_exists(inv_id, slot) then
                goto next
            end
            table.insert(
                empty_slots[inv_id], slot
            )
            ::next::
        end
    end
    return empty_slots
end

local function get_nonfull_slots
(db, stacks, inv_ids, item_name)
    -- INV_IDS = { SLOTS }
    local nonfull_slots = {}
    for _, inv_id in ipairs(inv_ids) do
        local inv_items = db:get_items(inv_id)
        for slot, item in pairs(inv_items) do
            local stack_size = stacks:get(item.name)
            if item.name == item_name and
               item.count < stack_size then
                if nonfull_slots[inv_id] == nil then
                    nonfull_slots[inv_id] = {}
                end
                table.insert(
                    nonfull_slots[inv_id],
                    slot
                )
            end
        end
    end
    return nonfull_slots
end

local function get_top_up_plans(db, stacks, dst_ids, src_id, src_slot, src_item, limit)
    local plans = {}
    for dst_id, dst_slots in pairs(get_nonfull_slots(db, stacks, dst_ids, src_item.name)) do
        for _, dst_slot in ipairs(dst_slots) do
            local cap = stacks:get(src_item.name) - db:get_item(dst_id, dst_slot).count
            local cnt = math.min(src_item.count, cap)
            if limit ~= nil then
                cnt = math.min(cnt, limit)
            end
            if cnt > 0 then
                table.insert(plans, {
                    src      = src_id,
                    src_slot = src_slot,
                    dst      = dst_id,
                    dst_slot = dst_slot,
                    count    = cnt
                })
                src_item.count = src_item.count - cnt
                if limit ~= nil then
                    limit = limit - cnt
                end
                if src_item.count == 0 then goto done end
            end
        end
    end
    ::done::
    if #plans == 0 then
        return nil
    end
    return plans
end

local function get_insert_plan(db, stacks, dst_ids, src_id, src_slot, src_item, limit)
    for dst_id, dst_slots in pairs(get_empty_slots(db, dst_ids, src_item.name)) do
        for _, dst_slot in ipairs(dst_slots) do
            local cnt = math.min(
                src_item.count, stacks:get(src_item.name)
            )
            if limit ~= nil then
                cnt = math.min(cnt, limit)
            end
            if cnt > 0 then
                src_item.count = 0
                return {
                    src      = src_id,
                    src_slot = src_slot,
                    dst      = dst_id,
                    dst_slot = dst_slot,
                    count    = cnt
                }
            end
        end
    end
end

local function apply_top_ups(plans, db, stacks, dst_ids, src_id, src_slot, src_item, limit)
    local moved = 0
    local top_ups = get_top_up_plans(
        db, stacks, dst_ids, src_id, src_slot, src_item, limit
    )
    if top_ups ~= nil then
        for _, plan in ipairs(top_ups) do
            local cnt = db:get_item(plan.dst, plan.dst_slot).count + plan.count
            db:add_item(plan.dst, plan.dst_slot, {
                name  = src_item.name,
                count = cnt
            })
            moved = moved + plan.count
        end
        table.move(top_ups, 1, #top_ups, #plans + 1, plans)
    end
    return moved
end

local function apply_move(plans, db, stacks, dst_ids, src_id, src_slot, src_item, limit)
    local plan = get_insert_plan(
        db, stacks, dst_ids, src_id, src_slot, src_item, limit
    )
    if plan ~= nil then
        db:add_item(plan.dst, plan.dst_slot, {
            name  = src_item.name,
            count = plan.count
        })
        table.insert(plans, plan)
        return plan.count
    end
    return 0
end

function move_planner.move
(db, stacks, src_ids, dst_ids, item_name, limit)
    local plans = {}
    for _, src_id in ipairs(src_ids) do
        for src_slot, src_item in pairs(db:get_items(src_id)) do
            local src_data = inv_data.new(src_id, src_slot, src_item)
            if (limit == nil or limit > 0) and
            (item_name == nil or src_data.item.name == item_name) then
                local topped = apply_top_ups(
                    plans, db, stacks,
                    dst_ids, src_data.id, src_data.slot, src_data.item, limit
                )
                if limit ~= nil then
                    limit = limit - topped
                end
                if src_data.item.count > 0 then
                    local moved = apply_move(
                        plans, db, stacks,
                        dst_ids, src_data.id, src_data.slot, src_data.item, limit
                    )
                    if limit ~= nil then
                        limit = limit - moved
                    end
                end
            end
        end
    end
    return plans
end

return move_planner
