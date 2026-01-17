local tbl   = require("utils.table_utils")
local move_planner = {}

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

local function get_top_up_plans(db, stacks, dst_ids, src_id, src_slot, src_item)
    local plans = {}
    for dst_id, dst_slots in pairs(get_nonfull_slots(db, stacks, dst_ids, src_item.name)) do
        for _, dst_slot in ipairs(dst_slots) do
            local cap = stacks:get(src_item.name) - db:get_item(dst_id, dst_slot).count
            local cnt = math.min(src_item.count, cap)
            if cnt > 0 then
                table.insert(plans, {
                    src      = src_id,
                    src_slot = src_slot,
                    dst      = dst_id,
                    dst_slot = dst_slot,
                    count    = cnt
                })
                src_item.count = src_item.count - cnt
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

local function get_insert_plan(db, stacks, dst_ids, src_id, src_slot, src_item)
    for dst_id, dst_slots in pairs(get_empty_slots(db, dst_ids, src_item.name)) do
        for _, dst_slot in ipairs(dst_slots) do
            local cnt = math.min(
                src_item.count, stacks:get(src_item.name)
            )
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

local function apply_top_ups(plans, db, stacks, dst_ids, src_id, src_slot, src_item)
    local top_ups = get_top_up_plans(
        db, stacks, dst_ids, src_id, src_slot, src_item
    )
    if top_ups ~= nil then
        for _, plan in ipairs(top_ups) do
            db:add_item(plan.dst, plan.dst_slot, {
                name  = src_item.name,
                count = db:get_item(plan.dst, plan.dst_slot).count + plan.count
            })
        end
        table.move(top_ups, 1, #top_ups, #plans + 1, plans)
    end
end

local function apply_move(plans, db, stacks, dst_ids, src_id, src_slot, src_item)
    local plan = get_insert_plan(
        db, stacks, dst_ids, src_id, src_slot, src_item
    )
    if plan ~= nil then
        db:add_item(plan.dst, plan.dst_slot, {
            name  = src_item.name,
            count = plan.count
        })
        table.insert(plans, plan)
    end
end

function move_planner.move
(db, stacks, src_ids, dst_ids, item_name)
    local plans = {}
    local t1 = os.clock()
    for _, src_id in ipairs(src_ids) do
        for src_slot, src_item in pairs(db:get_items(src_id)) do
            if item_name == nil or src_item.name == item_name then
                apply_top_ups(
                    plans, db, stacks,
                    dst_ids, src_id, src_slot, src_item
                )
                if src_item.count > 0 then
                    apply_move(
                        plans, db, stacks,
                        dst_ids, src_id, src_slot, src_item
                    )
                end
            end
        end
    end
    local t2 = os.clock()
    print("planning took", t2 - t1, "seconds")
    return plans
end

return move_planner
