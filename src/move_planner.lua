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

function move_planner.move
(db, stacks, src_ids, dst_ids, item_name)
    local plans = {}
    local t1 = os.clock()
    for _, src_id in ipairs(src_ids) do
        for src_slot, src_item in pairs(db:get_items(src_id)) do
            if item_name ~= nil and src_item.name ~= item_name then
                goto next_src_slot
            end
            for dst_id, dst_slots in pairs(get_nonfull_slots(db, stacks, dst_ids, src_item.name)) do
                for _, dst_slot in ipairs(dst_slots) do
                    local cap = stacks:get(src_item.name) - db:get_item(dst_id, dst_slot).count
                    local cnt = math.min(src_item.count, cap)
                    if cnt > 0 then
                        local plan = {
                            src      = src_id,
                            src_slot = src_slot,
                            dst      = dst_id,
                            dst_slot = dst_slot,
                            count    = cnt
                        }
                        table.insert(plans, plan)
                        src_item.count = src_item.count - cnt
                        db:add_item(dst_id, dst_slot, {
                            name  = db:get_item(dst_id, dst_slot).name,
                            count = db:get_item(dst_id, dst_slot).count + cnt
                        })
                        if src_item.count == 0 then goto next_src_slot end
                    end
                end
            end
            local empties = get_empty_slots(db, dst_ids, src_item.name)
            for dst_id, dst_slots in pairs(empties) do
                for _, dst_slot in ipairs(dst_slots) do
                    local cnt = math.min(src_item.count, stacks:get(src_item.name))
                    if cnt > 0 then
                        local plan = {
                            src      = src_id,
                            src_slot = src_slot,
                            dst      = dst_id,
                            dst_slot = dst_slot,
                            count    = cnt
                        }
                        table.insert(plans, plan)
                        src_item.count = 0
                        db:add_item(dst_id, dst_slot, {
                            name  = src_item.name,
                            count = cnt
                        })
                        goto next_src_slot
                    end
                end
            end
            ::next_src_slot::
        end
    end
    local t2 = os.clock()
    print("planning took", t2 - t1, "seconds")
    return plans
end

return move_planner
