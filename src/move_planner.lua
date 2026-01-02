local move_planner = {}

local function print_inv(inv)
    local inv_ids = inv:get_inv_ids()
    for _, inv_id in ipairs(inv_ids) do
        local inv_size  = inv:get_size(inv_id)
        local inv_items = inv:get_items(inv_id)
        print(inv_id, inv_size)
        for slot, item in pairs(inv_items) do
            print(slot, item.name, item.count)
        end
    end
end

local function top_up(db, src_id, dst_id)
    local plans = {}
    local stack = 64
    local src_pred = function (it)
        local curr = it:get()
        local item = curr.item
        return  item
            and curr.id == src_id
    end
    local dst_pred = function (it)
        local curr = it:get()
        local item = curr.item
        return  item
            and curr.id == dst_id
            and item.count < stack
    end
    local src_it = fiter:new(db, src_pred)
    local dst_it = fiter:new(db, dst_pred)
    src_it:first()
    dst_it:first()
    while not src_it:is_done() and
          not dst_it:is_done() do
        local src_val = src_it:get()
        local dst_val = dst_it:get()
        
        local cap = stack - dst_val.item.count
        local cnt = math.min(src_val.item.count, cap)
        
        local src_cnt = src_val.item.count - cnt
        local dst_cnt = dst_val.item.count + cnt
        
        local plan = {
            src_id   = src_val.id,
            src_slot = src_val.slot,
            dst_id   = dst_val.id,
            dst_slot = dst_val.slot,
            count    = cnt
        }
        table.insert(plans, plan)
        if src_cnt > 0 then
            db:add_item(src_val.id, src_val.slot,
                { name = src_val.item.name,
                 count = src_cnt }
            )
        else
            db:del_item(src_val.id, src_val.slot)
            src_it:next()
        end
        
        db:add_item(dst_val.id, dst_val.slot,
            { name = dst_val.item.name,
             count = dst_cnt }
        )
        if dst_cnt == stack then
            dst_it:next()
        end
    end
    return plans
end

function move_planner.plan(srcs, dsts)
    local plans = {}
    print("INPUTS:")
    print_inv(srcs)
    print("OUTPUTS:")
    print_inv(dsts)
    return plans
end

return move_planner
