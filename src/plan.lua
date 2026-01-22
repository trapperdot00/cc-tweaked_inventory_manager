-- Plan represents an item-moving strategy
-- between two inventory peripherals.
--
-- Fields:
--   `src`     : source chest's ID
--   `dst`     : destination chest's ID
--   `src_slot`: source slot index
--   `count`   : the count of items to move
--               (optional)
--   `dst_slot`: destination slot index
--               (optional)

local tbl  = require("utils.table_utils")
local plan = {}

function plan.execute_plan(p)
    local src = peripheral.wrap(p.src)
    if p.count == nil then
        return src.pushItems(
            p.dst, p.src_slot
        )
    elseif p.dst_slot == nil then
        return src.pushItems(
            p.dst, p.src_slot, p.count
        )
    else
        return src.pushItems(
            p.dst, p.src_slot, p.count, p.dst_slot
        )
    end
end

-- Execute a list of plans in parallel
function plan.execute_plans(plans, task_pool)
    for _, p in ipairs(plans) do
        local task = function()
            plan.execute_plan(p)
        end
        task_pool:add(task)
    end
    task_pool:run()
end

-- Returns an array containing
-- the peripheral IDs listed inside the
-- given plan-list.
-- The IDs are listed only once.
function plan.affected_chests(plans)
    local affected = {}
    for _, p in ipairs(plans) do
        if not tbl.contains(affected, p.src) then
            table.insert(affected, p.src)
        end
        if not tbl.contains(affected, p.dst) then
            table.insert(affected, p.dst)
        end
    end
    return affected
end

return plan
