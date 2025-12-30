local iter = require("src.iterator")
local pull = {}

function pull.get_plans(self)
    self:load()
    local plans = {}
    local src_it = self:get_output_iterator()
    local dst_it = self:get_input_iterator()
    while not src_it:is_done() and
          not dst_it:is_done() do
        local src_data = src_it:get()
        local dst_data = dst_it:get()
        if not src_data.item then
            -- Input slot is empty
            src_it:next()
        elseif dst_data.item then
            -- Output slot is occupied
            dst_it:next()
        else
            local plan = {
                src      = src_data.id,
                dst      = dst_data.id,
                src_slot = src_data.slot
            }
            table.insert(plans, plan)
            src_it:next()
            dst_it:next()
        end
    end
    return plans
end

return pull
